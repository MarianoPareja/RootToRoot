from .base import *

debug = False
ALLOWED_HOSTS = ["*"]

# Security
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 0

# Database
# https://docs.djangoproject.com/en/4.2/ref/settings/#databases

DATABASES = {
    # LOCAL DB (DEVELOPMENT)
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    },
    # AWS POSTGRES DATABASE (PROD)
    # "default": {
    #     "ENGINE": "django.db.backends.postgresql",
    #     "NAME": "my_database",
    #     "USER": "postgres",
    #     "PASSWORD": "password",
    #     "HOST": "database-1.cmy7hzzbkiwd.sa-east-1.rds.amazonaws.com",
    #     "PORT": "5432",
    # },
}
