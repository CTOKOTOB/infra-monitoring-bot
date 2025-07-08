from aiogram import Router, types
from aiogram.filters import Command
from db.database import get_db_pool
from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup

router = Router()


@router.message(Command("status"))
async def show_server_status(message: types.Message):
    pool = get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT s.server_id, s.name, s.is_active,
                   ac.is_available, ac.response_time, ac.created_at
            FROM servers s
            LEFT JOIN LATERAL (
                SELECT is_available, response_time, created_at
                FROM availability_checks ac
                WHERE ac.server_id = s.server_id
                ORDER BY created_at DESC
                LIMIT 1
            ) ac ON true
            ORDER BY s.server_id
        """)

    text = "📡 <b>Состояние серверов:</b>\n\n"
    keyboard = []

    for row in rows:
        name = row["name"]
        active = "✅" if row["is_active"] else "❌"
        status = "🟢 OK" if row["is_available"] else "🔴 DOWN"
        response = f"{row['response_time']:.3f}s" if row["response_time"] else "—"
        updated = row["created_at"].strftime("%H:%M:%S") if row["created_at"] else "—"

        #text += f"{status}  <b>{name}</b> {active} ⏱ {response}  {updated}\n"
        text += f" {active} <b>{name}</b> {status}  ⏱ {response}  {updated}\n"

        button_text = f"{'🔕 Отключить оповещения' if row['is_active'] else '🔔 Включить оповещения'} {name}"
        callback_data = f"toggle:{row['server_id']}:{int(not row['is_active'])}"

        keyboard.append([InlineKeyboardButton(text=button_text, callback_data=callback_data)])

    markup = InlineKeyboardMarkup(inline_keyboard=keyboard)
    await message.answer(text, reply_markup=markup, parse_mode="HTML")


@router.callback_query(lambda c: c.data.startswith("toggle:"))
async def toggle_server_state(callback: types.CallbackQuery):
    _, server_id, new_state = callback.data.split(":")
    pool = get_db_pool()

    async with pool.acquire() as conn:
        await conn.execute("UPDATE servers SET is_active = $1 WHERE server_id = $2", bool(int(new_state)), int(server_id))

    await callback.answer("Статус обновлён ✅")
    await show_server_status(callback.message)  # обновляем список
