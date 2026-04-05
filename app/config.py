import os

# Load .env file automatically — works in development without needing to set
# environment variables manually every time.
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv not installed — env vars must be set manually


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
        self.DATABASE_URL: str = os.getenv(
            "DATABASE_URL",
            "postgresql+asyncpg://postgres:dominoe8@127.0.0.1:5432/postgres",
        )
        self.ENTRY_FEE_NGN: int = int(os.getenv("ENTRY_FEE_NGN", "2000"))
        self.TARGET_ITEM_AMOUNT_NGN: int = int(
            os.getenv("TARGET_ITEM_AMOUNT_NGN", "50000")
        )
        self.PAYSTACK_SECRET_KEY: str = os.getenv(
            "PAYSTACK_SECRET_KEY",
            "sk_test_c7725b68e39597625a71453f6c5de0b6449aed25",
        )
        self.PAYSTACK_PUBLIC_KEY: str = os.getenv(
            "PAYSTACK_PUBLIC_KEY",
            "pk_test_058d24db323397dcd4e1b5bf503b4b1748ff39f9",
        )
        self.PAYSTACK_BASE_URL: str = os.getenv(
            "PAYSTACK_BASE_URL", "https://api.paystack.co",
        )
        self.PAYSTACK_CALLBACK_URL: str = os.getenv(
            "PAYSTACK_CALLBACK_URL", "http://localhost:8000/payments/callback",
        )
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

        # ── Email notifications ────────────────────────────────────────────────
        # Admin email — receives lobby trigger alerts and force-remove logs
        self.ADMIN_EMAIL: str = os.getenv("ADMIN_EMAIL", "unicartbytekena@gmail.com")
        # Gmail account used to SEND emails
        self.GMAIL_USER: str = os.getenv("GMAIL_USER", "")
        # Gmail App Password (16 chars, no spaces)
        # Get it at: myaccount.google.com/apppasswords (requires 2FA to be enabled)
        self.GMAIL_APP_PASSWORD: str = os.getenv("GMAIL_APP_PASSWORD", "")

        self.BACKEND_CORS_ORIGINS: list[str] = self._parse_origins(
            os.getenv(
                "BACKEND_CORS_ORIGINS",
                "http://localhost:3000,http://127.0.0.1:3000,"
                "http://localhost:5173,http://127.0.0.1:5173,"
                "http://localhost:8000,http://127.0.0.1:8000",
            )
        )

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @staticmethod
    def _parse_origins(value: str) -> list[str]:
        return [item.strip() for item in value.split(",") if item.strip()]


settings = Settings()