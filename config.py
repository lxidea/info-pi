"""Configuration for Info-Pi dashboard."""

# Location for weather (latitude/longitude for Open-Meteo)
WEATHER_LAT = 30.59
WEATHER_LON = 114.30

# Refresh intervals (seconds)
WEATHER_INTERVAL = 900      # 15 minutes
SYSTEM_INTERVAL = 5          # 5 seconds
NETWORK_INTERVAL = 30        # 30 seconds

# Flask settings
HOST = "0.0.0.0"
PORT = 5000
DEBUG = False
