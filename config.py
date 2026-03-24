"""Configuration for Info-Pi dashboard."""

# Location for weather (latitude/longitude for Open-Meteo)
WEATHER_LAT = 30.59
WEATHER_LON = 114.30

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
