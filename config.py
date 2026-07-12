"""Configuration for Info-Pi dashboard."""

# Location for weather (latitude/longitude)
WEATHER_LAT = 30.59
WEATHER_LON = 114.30

# Weather provider. QWeather (和风天气) is far more accurate for Chinese cities
# than the keyless Open-Meteo global models. The real account credentials are
# kept OUT of version control — put them in secrets_local.py (git-ignored, but
# still rsynced to the Pi by deploy.sh). If that file is absent, these blank
# defaults leave QWeather off and the code falls back to Open-Meteo.
#
#   # secrets_local.py
#   QWEATHER_HOST    = "xxxxxxxx.re.qweatherapi.com"   # your account's API host
#   QWEATHER_JWT_SUB = "..."      # project ID (sub)
#   QWEATHER_JWT_KID = "..."      # credential ID (kid)
#   QWEATHER_JWT_KEY = "ed25519.pem"   # Ed25519 private key (PEM text or path)
#   # or, for the legacy API key instead of JWT:  QWEATHER_KEY = "..."
QWEATHER_HOST = "devapi.qweather.com"
QWEATHER_KEY = ""
QWEATHER_JWT_SUB = ""
QWEATHER_JWT_KID = ""
QWEATHER_JWT_KEY = ""

# Local, git-ignored overrides (real credentials live here on this machine
# and on the Pi). Silently ignored if the file doesn't exist.
try:
    from secrets_local import *   # noqa: F401,F403
except ImportError:
    pass

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
