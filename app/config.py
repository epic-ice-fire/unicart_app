import os


class Settings:
    def __init__(self) -> None:
        self.SECRET_KEY: str = os.getenv(
            "SECRET_KEY",
            "unicart_secret_key_change_this_in_production_min32chars",
        )
        self.ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
        self.ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
            os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
        )
        # Local dev uses postgres default database
        # Render sets this via environment variable automatically
        self.DATABASE_URL: str = os.getenv(
            "DATABASE_URL",
            "postgresql+asyncpg://postgres:dominoe8@localhost/unicart_db"
        )
        self.ENTRY_FEE_NGN: int = int(os.getenv("ENTRY_FEE_NGN", "2000"))
        self.TARGET_ITEM_AMOUNT_NGN: int = int(
            os.getenv("TARGET_ITEM_AMOUNT_NGN", "50000")
        )

        # ── Flutterwave ────────────────────────────────────────────────────
        self.FLW_PUBLIC_KEY: str = os.getenv(
            "FLW_PUBLIC_KEY",
            "FLWPUBK-2d489e876e5c76613cbf311ca564e033-X",
        )
        self.FLW_SECRET_KEY: str = os.getenv(
            "FLW_SECRET_KEY",
            "FLWSECK-972240d6fa943f0154ceebc6a48a5429-19e69a097f2vt-X",
        )
        self.FLW_ENCRYPTION_KEY: str = os.getenv(
            "FLW_ENCRYPTION_KEY",
            "972240d6fa942aa577da74bd",
        )
        self.FLW_BASE_URL: str = os.getenv(
            "FLW_BASE_URL", "https://api.flutterwave.com/v3"
        )
        self.FLW_REDIRECT_URL: str = os.getenv(
            "FLW_REDIRECT_URL",
            "https://unicart-backend-v6u9.onrender.com/payments/callback",
        )

        # ── PAU verification ──────────────────────────────────────────────
        self.ALLOWED_EMAIL_DOMAINS: str = os.getenv(
            "ALLOWED_EMAIL_DOMAINS", "pau.edu.ng",
        )
        self.PAU_CODE_EXPIRES_MINUTES: int = int(
            os.getenv("PAU_CODE_EXPIRES_MINUTES", "10")
        )
        self.DEBUG_RETURN_PAU_CODE: bool = (
            os.getenv("DEBUG_RETURN_PAU_CODE", "true").lower() == "true"
        )
        self.ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

        # ── Email ──────────────────────────────────────────────────────────
        self.ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "")
        self.GMAIL_USER: str = os.getenv("GMAIL_USER", "")
        self.GMAIL_APP_PASSWORD: str = os.getenv("GMAIL_APP_PASSWORD", "")

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"


settings = Settings()
