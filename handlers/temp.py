from aiogram import Router, types
from aiogram.filters import Command
from db.database import get_db_pool

router = Router()


@router.message(Command("temp"))
async def get_temp_handler(message: types.Message):
    try:
        # Получаем пул соединений
        pool = get_db_pool()

        # Получаем последнюю запись о температуре
        async with pool.acquire() as connection:
            record = await connection.fetchrow(
                "SELECT temperature, created_at FROM temperature_logs "
                "ORDER BY created_at DESC LIMIT 1"
            )

            if record:
                temp = record['temperature']
                time = record['created_at']
                await message.reply(
                    f"🌡 Текущая температура: {temp}°C\n"
                    f"⏰ Последнее обновление: {time}"
                )
            else:
                await message.reply("❌ В базе нет данных о температуре")

    except Exception as e:
        await message.reply(f"⚠️ Ошибка при получении температуры: {str(e)}")
        # Логируем ошибку для отладки
        print(f"Error in get_temp_handler: {str(e)}")