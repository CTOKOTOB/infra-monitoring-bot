from aiogram import Router, types, F
from aiogram.types import BufferedInputFile
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from db.database import get_db_pool

import matplotlib.pyplot as plt
import io
from datetime import datetime, timedelta

router = Router()


class ServDetailStates(StatesGroup):
    choosing_server = State()
    choosing_metric = State()


@router.message(Command("serv_detail"))
async def cmd_serv_detail(message: types.Message, state: FSMContext):
    pool = get_db_pool()
    async with pool.acquire() as conn:
        servers = await conn.fetch("SELECT server_id, name FROM servers WHERE is_active = true ORDER BY name")

    if not servers:
        await message.answer("Нет доступных серверов.")
        return

    keyboard = [
        [types.InlineKeyboardButton(text=server["name"], callback_data=f"serv_{server['server_id']}")]
        for server in servers
    ]
    await message.answer("Выберите сервер:", reply_markup=types.InlineKeyboardMarkup(inline_keyboard=keyboard))
    await state.set_state(ServDetailStates.choosing_server)


@router.callback_query(F.data.startswith("serv_"))
async def select_server(callback: types.CallbackQuery, state: FSMContext):
    server_id = int(callback.data.replace("serv_", ""))
    await state.update_data(server_id=server_id)

    keyboard = [
        [
            types.InlineKeyboardButton(text="CPU", callback_data="metric_cpu"),
            types.InlineKeyboardButton(text="RAM", callback_data="metric_ram"),
        ],
        [
            types.InlineKeyboardButton(text="Disk", callback_data="metric_disk"),
            types.InlineKeyboardButton(text="Latency", callback_data="metric_latency"),
        ],
        [
            types.InlineKeyboardButton(text="Все", callback_data="metric_all"),
            types.InlineKeyboardButton(text="📆 Изменить период", callback_data="change_period"),
        ],
    ]
    await callback.message.edit_text("Выберите метрику:", reply_markup=types.InlineKeyboardMarkup(inline_keyboard=keyboard))
    await state.set_state(ServDetailStates.choosing_metric)


@router.callback_query(F.data == "change_period")
async def change_period(callback: types.CallbackQuery):
    hours_options = [1, 2, 4, 8, 12, 24, 48, 72]
    keyboard = [
        [
            types.InlineKeyboardButton(
                text=f"{h} ч", callback_data=f"period_{h}"
            )
            for h in hours_options[i:i+4]
        ]
        for i in range(0, len(hours_options), 4)
    ]
    await callback.message.edit_text("Выберите глубину отображения:", reply_markup=types.InlineKeyboardMarkup(inline_keyboard=keyboard))


@router.callback_query(F.data.startswith("period_"))
async def save_period(callback: types.CallbackQuery):
    user_id = callback.from_user.id
    hours = int(callback.data.replace("period_", ""))
    pool = get_db_pool()
    async with pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO user_settings (user_id, hours_depth)
            VALUES ($1, $2)
            ON CONFLICT (user_id) DO UPDATE SET hours_depth = $2
        """, user_id, hours)
    await callback.answer(f"Период установлен: {hours} ч ⏱️", show_alert=True)


@router.callback_query(F.data.startswith("metric_"))
@router.callback_query(F.data.startswith("metric_"))
async def show_metric(callback: types.CallbackQuery, state: FSMContext):
    metric = callback.data.replace("metric_", "")
    data = await state.get_data()
    server_id = data.get("server_id")
    user_id = callback.from_user.id

    pool = get_db_pool()
    async with pool.acquire() as conn:
        hours = await conn.fetchval(
            "SELECT hours_depth FROM user_settings WHERE user_id = $1", user_id
        )
        if hours is None:
            hours = 1  # default
        since_time = datetime.utcnow() - timedelta(hours=hours)

        images = []

        # Получаем имя сервера
        server_name = await conn.fetchval(
            "SELECT name FROM servers WHERE server_id = $1", server_id
        )

        if metric in ("latency", "all"):
            rows = await conn.fetch(
                """
                SELECT created_at, response_time FROM availability_checks
                WHERE server_id = $1 AND created_at >= $2
                ORDER BY created_at
                """, server_id, since_time
            )
            if rows:
                title = f"Latency (ms) — {server_name}"
                buf = plot_metric([(row["created_at"], row["response_time"] * 1000) for row in rows], title, y_limits=(0, 100) )
                images.append(buf)

        if metric in ("cpu", "all"):
            rows = await conn.fetch(
                """
                SELECT created_at, cpu_percent FROM cpu_usage
                WHERE server_id = $1 AND created_at >= $2
                ORDER BY created_at
                """, server_id, since_time
            )
            if rows:
                title = f"CPU Usage (%) — {server_name}"
                buf = plot_metric([(row["created_at"], row["cpu_percent"]) for row in rows], title)
                images.append(buf)

        if metric in ("ram", "all"):
            rows = await conn.fetch(
                """
                SELECT created_at, used_percent FROM ram_usage
                WHERE server_id = $1 AND created_at >= $2
                ORDER BY created_at
                """, server_id, since_time
            )
            if rows:
                title = f"RAM Usage (%) — {server_name}"
                buf = plot_metric([(row["created_at"], row["used_percent"]) for row in rows], title)
                images.append(buf)

        if metric in ("disk", "all"):
            rows = await conn.fetch(
                """
                SELECT created_at, used_percent FROM disk_usage
                WHERE server_id = $1 AND created_at >= $2
                ORDER BY created_at
                """, server_id, since_time
            )
            if rows:
                title = f"Disk Usage (%) — {server_name}"
                buf = plot_metric([(row["created_at"], row["used_percent"]) for row in rows], title)
                images.append(buf)


    if not images:
        await callback.message.answer("Нет данных за выбранный период.")
    else:
        media = [
            types.InputMediaPhoto(media=BufferedInputFile(img.getvalue(), filename="plot.png"))
            for img in images
        ]
        await callback.message.answer_media_group(media)

def plot_metric(data, title, y_limits=None):
    import matplotlib.pyplot as plt
    import io

    x = [point[0] for point in data]
    y = [point[1] for point in data]

    fig, ax = plt.subplots()
    ax.plot(x, y, marker="o")
    ax.set_title(title)
    ax.set_xlabel("Time")
    ax.set_ylabel(title.split()[0])
    if y_limits is not None:
        ax.set_ylim(y_limits)
    ax.grid(True)

    buf = io.BytesIO()
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(buf, format='png')
    plt.close(fig)
    buf.seek(0)
    return buf

