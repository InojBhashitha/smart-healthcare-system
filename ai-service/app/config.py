import os
from dataclasses import dataclass


@dataclass
class Settings:
    """Application settings loaded from environment variables."""

    # Database
    db_host: str = os.getenv("DB_HOST", "localhost")
    db_port: int = int(os.getenv("DB_PORT", "5432"))
    db_name: str = os.getenv("DB_NAME", "smart_healthcare")
    db_user: str = os.getenv("DB_USERNAME", "postgres")
    db_password: str = os.getenv("DB_PASSWORD", "smarthealth123")

    # AI Model
    trocr_model: str = os.getenv(
        "TROCR_MODEL", "microsoft/trocr-base-handwritten"
    )

    # Service
    host: str = os.getenv("AI_SERVICE_HOST", "0.0.0.0")
    port: int = int(os.getenv("AI_SERVICE_PORT", "8000"))

    # RapidFuzz
    fuzzy_match_threshold: int = int(
        os.getenv("FUZZY_MATCH_THRESHOLD", "70")
    )

    @property
    def database_url(self) -> str:
        return (
            f"host={self.db_host} port={self.db_port} "
            f"dbname={self.db_name} user={self.db_user} "
            f"password={self.db_password}"
        )


settings = Settings()
