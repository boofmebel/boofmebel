from functools import lru_cache
from pydantic import BaseSettings, AnyUrl
from typing import List


class Settings(BaseSettings):
    app_name: str = "BoofMebel API"
    version: str = "0.1.0"

    database_url: AnyUrl = "postgresql+asyncpg://user:password@localhost:5432/boofmebel"
    cors_origins: List[str] = ["http://localhost:3000", "http://localhost:8000"]
    sentry_dsn: str = ""
    secret_key: str = "dev-secret-key-change-in-production"  # Change in production!

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

