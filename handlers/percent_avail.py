from aiogram import Router, types, F
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from datetime import timedelta
from db.database import get_db_pool

router = Router()

# Интервалы: отображаемое имя → timedelta
HUMAN_INTERVALS = {
    "1 hour": timedelta(hours=1),
    "2 hours": timedelta(hours=2),
    "4 hours": timedelta(hours=4),
    "8 hours": timedelta(hours=8),
    "12 hours": timedelta(hours=12),
    "1 day": timedelta(days=1),
    "2 days": timedelta(days=2),
    "3 days": timedelta(days=3),
    "365 days": timedelta(days=365),  # Вся история
}

# Функция для генерации клавиатуры
def get_interval_keyboard():
    buttons = [
        ("1ч", "1 hour"), ("2ч", "2 hours"), ("4ч", "4 hours"), ("8ч", "8 hours"),
        ("12ч", "12 hours"), ("24ч", "1 day"), ("48ч", "2 days"), ("72ч", "3 days"),
    ]

    rows = [
        [
            InlineKeyboardButton(text=label, callback_data=f"avail:{interval}")
            for label, interval in buttons[i:i + 4]
        ]
        for i in range(0, len(buttons), 4)
    ]

    rows.append([
        InlineKeyboardButton(text="Вся история", callback_data="avail:365 days")
    ])

    return InlineKeyboardMarkup(inline_keyboard=rows)


# Обработка команды /percent_avail
@router.message(F.text == "/percent_avail")
async def cmd_percent_avail(message: types.Message):
    await message.answer("Выберите интервал для расчёта доступности:", reply_markup=get_interval_keyboard())


# Обработка нажатия кнопки
@router.callback_query(F.data.startswith("avail:"))
async def handle_avail_callback(callback: types.CallbackQuery):
    interval_str = callback.data.split("avail:")[1]
    interval_obj = HUMAN_INTERVALS.get(interval_str)

    if interval_obj is None:
        await callback.message.answer("Неверный интервал.")
        return

    pool = get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT name, availability_percent FROM get_server_availability($1::interval)",
            interval_obj
        )

    if not rows:
        text = "Нет данных за выбранный период."
    else:
        text = "\n".join(
            f"🔹 <b>{r['name']}</b>: {r['availability_percent']}%" for r in rows
        )

    await callback.message.edit_text(
        f"<b>Процент доступности серверов</b> за: <code>{interval_str}</code>\n\n{text}",
        parse_mode="HTML"
    )
    await callback.answer()
