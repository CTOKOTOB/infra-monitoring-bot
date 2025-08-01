import os
import json
import time
import aiohttp
import asyncio
import asyncpg
from datetime import datetime
from dotenv import load_dotenv
from cryptography.hazmat.primitives import serialization
from jwt import encode as jwt_encode

# Загружаем .env
load_dotenv(os.path.expanduser("~/infra-monitoring-bot/.env"))

YANDEX_GPT_URL = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
FOLDER_ID = os.getenv("YANDEX_FOLDER_ID")
KEY_FILE_PATH = os.getenv("YANDEX_KEY_FILE")

OPENWEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY")
OPENWEATHER_CITY = os.getenv("OPENWEATHER_CITY", "Moscow")
OPENWEATHER_LANG = os.getenv("OPENWEATHER_LANG", "ru")

DATABASE_URL = os.getenv("DATABASE_MONITORING_URL")
TELEGRAM_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

YANDEX_API_KEY = None


async def get_iam_token_from_keyfile(path_to_keyfile: str) -> str:
    with open(path_to_keyfile, 'r') as f:
        key_data = json.load(f)

    private_key = serialization.load_pem_private_key(
        key_data["private_key"].encode(),
        password=None
    )

    payload = {
        "aud": "https://iam.api.cloud.yandex.net/iam/v1/tokens",
        "iss": key_data["service_account_id"],
        "iat": int(time.time()),
        "exp": int(time.time()) + 360
    }

    headers = {"kid": key_data["id"]}
    encoded_jwt = jwt_encode(payload, private_key, algorithm="PS256", headers=headers)

    async with aiohttp.ClientSession() as session:
        async with session.post(
            "https://iam.api.cloud.yandex.net/iam/v1/tokens",
            json={"jwt": encoded_jwt}
        ) as resp:
            result = await resp.json()
            return result["iamToken"]


async def get_weather():
    url = f"http://api.openweathermap.org/data/2.5/weather?q={OPENWEATHER_CITY}&appid={OPENWEATHER_API_KEY}&units=metric&lang={OPENWEATHER_LANG}"
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            data = await resp.json()
            if resp.status != 200:
                print("Ошибка получения погоды:", data)
                return None
            return data


def get_daytime_phrase():
    hour = datetime.now().hour
    if 5 <= hour < 12:
        return "доброго утра"
    elif 12 <= hour < 18:
        return "доброго дня"
    elif 18 <= hour < 23:
        return "доброго вечера"
    else:
        return "спокойной ночи"


async def query_yandex_gpt(prompt: str) -> str:
    global YANDEX_API_KEY
    if YANDEX_API_KEY is None:
        YANDEX_API_KEY = await get_iam_token_from_keyfile(KEY_FILE_PATH)

    headers = {
        "Authorization": f"Bearer {YANDEX_API_KEY}",
        "Content-Type": "application/json"
    }
    data = {
        "modelUri": f"gpt://{FOLDER_ID}/yandexgpt/latest",
        "completionOptions": {"stream": False, "temperature": 0.97, "maxTokens": 120},
        "messages": [
            {
                "role": "system",
                "text": "Ты пишешь нежные, разнообразные пожелания для любимой женщины, учитывая погоду и время суток."
            },
            {"role": "user", "text": prompt}
        ]
    }

    async with aiohttp.ClientSession() as session:
        async with session.post(YANDEX_GPT_URL, headers=headers, json=data) as resp:
            result = await resp.json()
            try:
                return result["result"]["alternatives"][0]["message"]["text"].strip()
            except Exception as e:
                print("Ошибка GPT:", result)
                return "Ошибка при генерации пожелания."


async def save_wish_to_db(city, temp, description, daytime_phrase, wish):
    conn = await asyncpg.connect(DATABASE_URL)
    await conn.execute(
        """
        INSERT INTO wishes (city, temperature, description, daytime_phrase, wish)
        VALUES ($1, $2, $3, $4, $5)
        """,
        city, temp, description, daytime_phrase, wish
    )
    await conn.close()


async def get_random_image_path():
    conn = await asyncpg.connect(DATABASE_URL)
    row = await conn.fetchrow("SELECT file_path FROM love_is_images ORDER BY random() LIMIT 1")
    await conn.close()
    if row:
        return row["file_path"]
    return None


async def send_photo_and_caption_to_telegram(photo_path: str, caption: str):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendPhoto"
    async with aiohttp.ClientSession() as session:
        if not os.path.exists(photo_path):
            print("Файл картинки не найден:", photo_path)
            return
        with open(photo_path, "rb") as photo_file:
            data = aiohttp.FormData()
            data.add_field("chat_id", TELEGRAM_CHAT_ID)
            data.add_field("photo", photo_file, filename=os.path.basename(photo_path), content_type="image/jpeg")
            data.add_field("caption", caption)
            async with session.post(url, data=data) as resp:
                if resp.status != 200:
                    print("Ошибка отправки фото в Telegram:", await resp.text())
                else:
                    print("Фото с пожеланием отправлено успешно!")


async def main():
    weather = await get_weather()
    if not weather:
        return

    temp = weather["main"]["temp"]
    description = weather["weather"][0]["description"]
    city = weather["name"]

    daytime_phrase = get_daytime_phrase()

    prompt = (
        f"Сегодня в городе {city} {description}, температура {temp}°C. "
        f"Составь красивое и оригинальное пожелание {daytime_phrase} моей любимой женщине, "
        "чтобы оно звучало искренне, тепло и не было банальным."
    )

    wish = await query_yandex_gpt(prompt)

    # сохраняем в базу
    await save_wish_to_db(city, temp, description, daytime_phrase, wish)

    # получаем рандомную картинку
    photo_path = await get_random_image_path()

    # отправляем фото + пожелание в одном сообщении
    if photo_path:
        await send_photo_and_caption_to_telegram(photo_path, wish)
    else:
        # если фото не нашли, отправим просто текст
        await send_to_telegram(wish)

    # также печатаем в консоль (на всякий случай)
    print(wish)


async def send_to_telegram(text: str):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": text}
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=payload) as resp:
            if resp.status != 200:
                print("Ошибка отправки в Telegram:", await resp.text())


if __name__ == "__main__":
    asyncio.run(main())

