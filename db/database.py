import os
import asyncpg

_db_pool = None

async def init_db():
    global _db_pool
    _db_pool = await asyncpg.create_pool(dsn=os.environ["DATABASE_MONITORING_URL"])
    print("✅ DB pool initialized")

def get_db_pool():
    if _db_pool is None:
        raise RuntimeError("DB pool is not initialized. Call init_db() first.")
    return _db_pool
