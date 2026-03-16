# Info-Pi

A Raspberry Pi kiosk dashboard that displays weather, calendar, astronomy, and system stats on an 800x480 screen. Built with Flask and plain HTML/CSS/JS -- no build tools required.

![Dashboard Screenshot](screenshot.png)

## Features

- **Current weather** -- temperature, humidity, wind, feels-like, air quality (PM2.5)
- **3-day forecast** with weather icons and temperature ranges
- **12-hour hourly timeline** with temperature bars and weather icons
- **Monthly calendar** with today highlight and Chinese day-of-week headers
- **Astronomy data** -- sunrise/sunset, moonrise/moonset, moon phase, Milky Way visibility
- **Upcoming events** -- meteor showers and eclipses with countdown
- **World clocks** -- Berkeley, New York, Paris with local temperatures
- **System stats** -- CPU temperature, CPU/RAM/disk usage
- **Day/night theme** -- background color transitions based on sunrise/sunset with 30-minute dawn/dusk blending

Weather data is fetched from [Open-Meteo](https://open-meteo.com/) (free, no API key required).

## Quick Start

```bash
# Clone and set up
git clone https://github.com/lxidea/info-pi.git
cd info-pi
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# Run locally
python3 app.py
# Open http://localhost:5000
```

## Deploy to Raspberry Pi

```bash
# One-command deploy (installs systemd services, starts everything)
bash deploy/deploy.sh pi@<your-pi-ip>
```

This sets up two systemd services:
- `info-pi.service` -- Flask server on port 5000
- `kiosk.service` -- Chromium in fullscreen kiosk mode

### Prerequisites (Pi)

- Raspberry Pi with a display (optimized for 800x480)
- Raspberry Pi OS with desktop (for Chromium kiosk mode)
- Python 3.7+
- Network access for weather API

## Configuration

Edit `config.py` to customize:

```python
# Your location (latitude/longitude for Open-Meteo weather)
WEATHER_LAT = 30.59    # default: Wuhan, China
WEATHER_LON = 114.30

# Refresh intervals (seconds)
WEATHER_INTERVAL = 900  # 15 minutes
```

World clock cities can be changed in `collectors/datetime_info.py`.

## Architecture

```
info-pi/
  app.py              # Flask app -- serves / and /api/all
  config.py           # Location, intervals, Flask settings
  collectors/
    weather.py        # Open-Meteo API (current + hourly + forecast + astronomy)
    datetime_info.py  # Date, time, world clocks
    astronomy_events.py  # Meteor showers & eclipses (2024-2030)
    system_stats.py   # CPU/RAM/disk via psutil
    network.py        # IP/ARP/bandwidth (available, not wired in)
  templates/
    index.html        # Single-page dashboard
  static/
    css/dashboard.css  # Dark theme, 800x480 layout
    js/dashboard.js    # Fetches /api/all every 5s, updates DOM
  deploy/
    deploy.sh         # rsync + systemd setup script
    info-pi.service   # Flask server systemd unit
    kiosk.service     # Chromium kiosk systemd unit
    kiosk.sh          # Chromium launch script
```

**Data flow:** The frontend polls `/api/all` every 5 seconds. Weather data is fetched in a background thread every 15 minutes; other collectors run synchronously per request.

## UI Language

The dashboard UI is in **Chinese (zh-CN)** -- weather descriptions, date formats, labels, and moon phase names are all in Chinese.

## License

MIT
