# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Info-Pi is a Raspberry Pi kiosk dashboard — a Flask web app that displays weather, astronomy, date/time with world clocks, and system stats on an 800x480 screen. The UI is in Chinese (zh-CN). It's designed to run fullscreen in Chromium kiosk mode on a Pi.

## Running the App

```bash
# Setup
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# Run (serves on 0.0.0.0:5000)
python3 app.py
```

## Deploying to Raspberry Pi

```bash
# Deploys via rsync+ssh, installs systemd services, restarts everything
bash deploy/deploy.sh [user@host]   # default: pi@raspberrypi.local
```

This installs two systemd services: `info-pi.service` (Flask server) and `kiosk.service` (Chromium fullscreen).

## Architecture

**Backend (Flask):** Single-file app (`app.py`) with one HTML route (`/`) and one API endpoint (`/api/all`) that returns all dashboard data as JSON.

**Data collectors** (`collectors/`): Each module has a `collect()` function (or `get_upcoming_events()` for astronomy) returning a dict:
- `weather.py` — Fetches from Open-Meteo API (weather + air quality + world city temps), calculates moon phase and Milky Way visibility. Runs in a background thread, refreshed every 15 min (`config.WEATHER_INTERVAL`).
- `datetime_info.py` — Local time, date, weekday, and world clocks (Berkeley, New York, Paris) with manual DST calculation.
- `system_stats.py` — CPU/RAM/disk usage via psutil, CPU temperature via psutil or sysfs fallback.
- `astronomy_events.py` — Upcoming meteor showers and eclipses from hardcoded static tables (2024-2030).
- `network.py` — IP addresses, ARP table, bandwidth counters. Exists but not currently wired into the API.

Weather runs in a daemon thread with a lock-protected shared data store; other collectors are called synchronously on each `/api/all` request.

**Frontend:** Single-page dashboard (`templates/index.html`, `static/js/dashboard.js`, `static/css/dashboard.css`). Polls `/api/all` every 5 seconds. Background color transitions between night/day themes based on sunrise/sunset times.

**Configuration** (`config.py`): Location coordinates (Wuhan), refresh intervals, Flask host/port. No environment variables or .env files — all config is in this file.

## Key Constraints

- Target display is 800x480 pixels — all CSS is hardcoded for this resolution
- No build tools, bundlers, or package managers for frontend — plain JS/CSS
- No database — all data is ephemeral or fetched from APIs
- Weather descriptions, weekday names, moon phases, and UI labels are in Chinese
- WMO weather codes are used throughout (shared mapping in both `weather.py` and `dashboard.js`)
