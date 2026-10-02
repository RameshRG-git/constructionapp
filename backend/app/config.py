import os
from datetime import timedelta


class BaseConfig:
    # When unset, create_app() loads/generates a persistent key in the instance folder.
    SECRET_KEY = os.getenv("SECRET_KEY")
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://constructionapp:constructionapp@localhost:5432/constructionapp",
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JSON_SORT_KEYS = False
    DEFAULT_TENANT = os.getenv("DEFAULT_TENANT", "kaniskahomes")

    SESSION_IDLE_TIMEOUT_MINUTES = int(os.getenv("SESSION_IDLE_TIMEOUT_MINUTES", "15"))
    SESSION_ABSOLUTE_TIMEOUT_HOURS = int(os.getenv("SESSION_ABSOLUTE_TIMEOUT_HOURS", "12"))
    PERMANENT_SESSION_LIFETIME = timedelta(minutes=SESSION_IDLE_TIMEOUT_MINUTES)
    SESSION_REFRESH_EACH_REQUEST = True
    SESSION_COOKIE_NAME = "constructionapp_session"
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    SESSION_COOKIE_SECURE = os.getenv("SESSION_COOKIE_SECURE", "true").lower() == "true"


class DevelopmentConfig(BaseConfig):
    DEBUG = True


class TestingConfig(BaseConfig):
    TESTING = True
    SECRET_KEY = "testing-secret-key"
    SESSION_COOKIE_SECURE = False
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "TEST_DATABASE_URL",
        "sqlite+pysqlite:///:memory:",
    )


class ProductionConfig(BaseConfig):
    DEBUG = False
