import sys

sys.path.append(".")

import asyncio
import os
from aiogram import Bot, Dispatcher

from handlers import temp, server_status, serv_detail
from db.database import init_db

bot = Bot(token=os.environ["MONITORING_BOT_TOKEN"])
dp = Dispatcher()

async def main():
    await init_db()

    dp.include_router(temp.router)
    dp.include_router(server_status.router)
    dp.include_router(serv_detail.router)

    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
