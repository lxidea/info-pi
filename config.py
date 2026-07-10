"""Configuration for Info-Pi dashboard."""

# Location for weather (latitude/longitude)
WEATHER_LAT = 30.59
WEATHER_LON = 114.30

# Weather provider. QWeather (和风天气) is far more accurate for Chinese
# cities than the keyless Open-Meteo global models. Register a free key at
# https://dev.qweather.com/ , create a project, and paste the API key +
# your account's API host below. Leave QWEATHER_KEY empty to fall back to
# Open-Meteo (no key needed).
QWEATHER_HOST = "devapi.qweather.com"   # free/dev host; paid = api.qweather.com,
                                        # or your account's custom xxxx.qweatherapi.com

# Auth — use EITHER the legacy API key OR JWT (new QWeather accounts use JWT).
# Legacy API key (query param):
QWEATHER_KEY = ""                       # e.g. "abcdef0123456789..."
# JWT (Ed25519) — from the QWeather console: create a credential, upload an
# Ed25519 public key, and note the Project ID (sub) + Credential ID (kid).
# QWEATHER_JWT_KEY is the Ed25519 PRIVATE key: paste the PEM text, or give a
# path to the .pem file. Signed in pure Python (no crypto deps needed).
QWEATHER_JWT_SUB = ""                   # project ID  (sub)
QWEATHER_JWT_KID = ""                   # credential ID (kid)
QWEATHER_JWT_KEY = ""                   # Ed25519 private key: PEM text or file path

# Refresh intervals (seconds)
WEATHER_INTERVAL = 900      # 15 minutes
SYSTEM_INTERVAL = 5          # 5 seconds
NETWORK_INTERVAL = 30        # 30 seconds

# World clocks: list of (display_name, utc_offset_hours, dst_type)
# dst_type: "us" = US rules, "eu" = EU rules, None = no DST
WORLD_CLOCKS = [
    ("伯克利", -8, "us"),      # Berkeley (US Pacific)
    ("纽约", -5, "us"),        # New York (US Eastern)
    ("巴黎", 1, "eu"),         # Paris (CET)
]

# Flask settings
HOST = "0.0.0.0"
PORT = 5000
DEBUG = False
