import asyncpg
import asyncio
import os

async def test_connection():
    try:
        conn = await asyncpg.connect(os.environ["DATABASE_MONITORING_URL"])
        print("✅ Connection successful!")
        await conn.close()
    except Exception as e:
        print(f"❌ Connection failed: {e}")

asyncio.run(test_connection())