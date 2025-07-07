import sys

sys.path.append(".")

import asyncio
import os
from aiogram import Bot, Dispatcher

from handlers import temp
from db.database import init_db

bot = Bot(token=os.environ["MONITORING_BOT_TOKEN"])
dp = Dispatcher()

async def main():
    await init_db()

    dp.include_router(temp.router)

    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())
