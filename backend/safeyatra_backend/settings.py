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
routes_database_url = env("ROUTES_DATABASE_URL", default=None)


def parse_database_url(url, is_supabase_pooler=True):
    if not url:
        return None

    # Custom parsing for Supabase if needed, otherwise fallback to dj_database_url
    if is_supabase_pooler and url.startswith(("postgres://", "postgresql://")):
        # We can try standard parsing first
        config = dj_database_url.parse(url, conn_max_age=600)
        if "supabase.co" in url or "supabase.com" in url:
            config["OPTIONS"] = {"sslmode": "require"}
        return config

    return dj_database_url.parse(
        url,
        conn_max_age=600,
        ssl_require="supabase.co" in url or "supabase.com" in url,
    )


DATABASES = {
    "default": parse_database_url(database_url),
}

if routes_database_url:
    DATABASES["routes_db"] = parse_database_url(routes_database_url)

DATABASE_ROUTERS = ["core.routers.PredefinedRouteRouter"]

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Asia/Kathmandu"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

#ALLOWED_HOSTS = ["*"]
#CORS_ALLOWED_ORIGINS = True #env.list(
    #"CORS_ALLOWED_ORIGINS",
    #default=["http://localhost:3000", "http://127.0.0.1:3000"],
#)
CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:53496",
        "http://127.0.0.1:53496",
    ],
)
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127\.0\.0\.1:\d+$",
]

REST_FRAMEWORK = {
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

SMS_PROVIDER = env("SMS_PROVIDER", default="console")
TWILIO_ACCOUNT_SID = env("TWILIO_ACCOUNT_SID", default="")
TWILIO_AUTH_TOKEN = env("TWILIO_AUTH_TOKEN", default="")
TWILIO_FROM_PHONE = env("TWILIO_FROM_PHONE", default="")
TWILIO_VERIFY_SERVICE_SID = env(
    "TWILIO_VERIFY_SERVICE_SID",
    default=env("TWILIO_VERIFY_SERVICE_ID", default=""),
)
EMERGENCY_ALERT_BASE_URL = env(
    "EMERGENCY_ALERT_BASE_URL",
    default="https://www.google.com/maps/search/?api=1&query={lat},{lng}",
)

SUPABASE_URL = env("SUPABASE_URL", default="")
SUPABASE_SERVICE_KEY = env(
    "SUPABASE_SERVICE_ROLE_KEY",
    default=env("SUPABASE_ANON_KEY", default=""),
)
SUPABASE_ROUTES_TABLE = env("SUPABASE_ROUTES_TABLE", default="predefined_routes")
SUPABASE_POIS_TABLE = env("SUPABASE_POIS_TABLE", default="points_of_interest")
SUPABASE_ROUTE_SEARCH_COLUMNS = env.list(
    "SUPABASE_ROUTE_SEARCH_COLUMNS",
    default=["name", "description"],
)
SUPABASE_POI_SEARCH_COLUMNS = env.list(
    "SUPABASE_POI_SEARCH_COLUMNS",
    default=["name", "address", "description"],
)
SUPABASE_REQUEST_TIMEOUT = env.int("SUPABASE_REQUEST_TIMEOUT", default=8)
