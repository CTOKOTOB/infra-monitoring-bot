import os
from aiogram import BaseMiddleware
from aiogram.types import Message, CallbackQuery
from typing import Callable, Awaitable, Any

OWNER_ID = int(os.environ["OWNER_ID"])

class OwnerOnlyMiddleware(BaseMiddleware):
    async def __call__(
        self,
        handler: Callable[[Any, dict], Awaitable[Any]],
        event: Message | CallbackQuery,
        data: dict,
    ) -> Any:
        if event.from_user.id != OWNER_ID:
            return  # просто молча игнорируем
        return await handler(event, data)
