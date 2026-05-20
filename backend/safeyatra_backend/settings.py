from pathlib import Path
import dj_database_url
import environ


BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
)
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY", default="unsafe-dev-secret")
DEBUG = env("DEBUG")
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True  # ✅ Allows any port during development
else:
    CORS_ALLOWED_ORIGINS = env.list(
        "CORS_ALLOWED_ORIGINS",
        default=[],
    )
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "core",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "safeyatra_backend.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "safeyatra_backend.wsgi.application"

database_url = env("DATABASE_URL", default=f"sqlite:///{BASE_DIR / 'db.sqlite3'}")


def parse_database_url(url):
    supabase_host = "db.qdebzwqpboupbnwlhslr.supabase.co"
    if supabase_host in url and url.startswith(("postgres://", "postgresql://")):
        prefix, rest = url.split("://", 1)
        credentials, after_credentials = rest.rsplit(f"@{supabase_host}", 1)
        username, password = credentials.split(":", 1)
        path_and_query = after_credentials.split("/", 1)[1]
        database_name = path_and_query.split("?", 1)[0]
        port = after_credentials.split(":", 1)[1].split("/", 1)[0]
        return {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": database_name,
            "USER": username,
            "PASSWORD": password,
            "HOST": supabase_host,
            "PORT": port,
            "CONN_MAX_AGE": 600,
            "OPTIONS": {"sslmode": "require"},
        }

    return dj_database_url.parse(
        url,
        conn_max_age=600,
        ssl_require="supabase.co" in url,
    )


DATABASES = {"default": parse_database_url(database_url)}

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kathmandu"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

#ALLOWED_HOSTS = ["*"]
#CORS_ALLOWED_ORIGINS = True #env.list(
    #"CORS_ALLOWED_ORIGINS",
    #default=["http://localhost:3000", "http://127.0.0.1:3000"],
#)
CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=["http://localhost:8000", "http://127.0.0.1:8000"],
)

REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}
