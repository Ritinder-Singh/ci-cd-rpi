"""Application configuration using pydantic-settings."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings."""

    app_name: str = "CI/CD Backend API"
    app_env: str = "development"
    log_level: str = "info"

    class Config:
        """Pydantic configuration."""
        env_file = ".env"
        case_sensitive = False


settings = Settings()
