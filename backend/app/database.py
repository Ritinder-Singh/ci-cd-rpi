"""Database configuration and session management."""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
import os

# Get database URL from environment
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://cicd_user:cicd_password_prod@postgres:5432/cicd_production"
)

# Convert to async URL
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

# Create async engine
engine = create_async_engine(
    DATABASE_URL,
    echo=True if os.getenv("LOG_LEVEL") == "debug" else False,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Base class for models
Base = declarative_base()


async def get_db():
    """
    Dependency function to get database session.

    Usage in FastAPI endpoints:
    ```
    @app.get("/items")
    async def read_items(db: AsyncSession = Depends(get_db)):
        ...
    ```
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    """Initialize database tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
