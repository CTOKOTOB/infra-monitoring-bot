from aiogram import Router, types
from aiogram.filters import Command
from db.database import get_db_pool
import matplotlib.pyplot as plt
import io
from datetime import datetime, timedelta

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


@router.message(Command("graph"))
async def get_temp_graph_handler(message: types.Message):
    try:
        pool = get_db_pool()

        # Вычисляем время 24 часа назад
        time_24h_ago = datetime.now() - timedelta(hours=24)

        async with pool.acquire() as connection:
            records = await connection.fetch(
                "SELECT temperature, created_at FROM temperature_logs "
                "WHERE created_at >= $1 ORDER BY created_at ASC",
                time_24h_ago
            )

            if not records:
                await message.reply("❌ Нет данных о температуре за последние сутки")
                return

            # Подготовка данных для графика
            temps = [record['temperature'] for record in records]
            times = [record['created_at'] for record in records]

            # Создание графика
            plt.figure(figsize=(10, 5))
            plt.plot(times, temps, marker='o', linestyle='-', color='r', label='Температура')

            # Добавляем горизонтальную линию на уровне 60°C
            plt.axhline(y=60, color='orange', linestyle='--', linewidth=1, label='Опасная зона (60°C)')

            plt.title('Температура процессора за последние 24 часа')
            plt.xlabel('Время')
            plt.ylabel('Температура (°C)')
            plt.grid(True, alpha=0.3)
            plt.xticks(rotation=45)

            # Добавляем легенду
            plt.legend(loc='upper right')

            plt.tight_layout()

            # Сохранение графика в буфер
            buf = io.BytesIO()
            plt.savefig(buf, format='png', dpi=100)
            buf.seek(0)

            # Создаем InputFile из буфера
            photo = types.BufferedInputFile(buf.read(), filename="temperature_graph.png")

            # Отправка графика
            await message.reply_photo(
                photo=photo,
                caption='📈 График температуры за последние 24 часа'
            )

            # Закрытие графика и буфера
            plt.close()
            buf.close()

    except Exception as e:
        await message.reply(f"⚠️ Ошибка при построении графика: {str(e)}")
        print(f"Error in get_temp_graph_handler: {str(e)}")