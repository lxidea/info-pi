"""Weather collector using Open-Meteo API + moon phase + milky way."""

import math
import datetime
import requests
import config

# WMO weather code to Chinese description
WMO_CODES = {
    0: "\u6674", 1: "\u6674\u95f4\u591a\u4e91", 2: "\u591a\u4e91",
    3: "\u9634",
    45: "\u96fe", 48: "\u51bb\u96fe",
    51: "\u5c0f\u6bdb\u6bdb\u96e8", 53: "\u6bdb\u6bdb\u96e8",
    55: "\u5bc6\u6bdb\u6bdb\u96e8",
    61: "\u5c0f\u96e8", 63: "\u4e2d\u96e8", 65: "\u5927\u96e8",
    66: "\u5c0f\u51bb\u96e8", 67: "\u51bb\u96e8",
    71: "\u5c0f\u96ea", 73: "\u4e2d\u96ea", 75: "\u5927\u96ea",
    77: "\u96ea\u7c92",
    80: "\u5c0f\u9635\u96e8", 81: "\u9635\u96e8", 82: "\u5927\u9635\u96e8",
    85: "\u5c0f\u9635\u96ea", 86: "\u9635\u96ea",
    95: "\u96f7\u9635\u96e8", 96: "\u96f7\u9635\u96e8\u4f34\u51b0\u96f9",
    99: "\u5f3a\u96f7\u9635\u96e8",
}

# Wind degree to 16-point compass direction (Chinese)
WIND_DIRS = [
    "\u5317", "\u5317\u5317\u4e1c", "\u4e1c\u5317", "\u4e1c\u5317\u4e1c",
    "\u4e1c", "\u4e1c\u5357\u4e1c", "\u4e1c\u5357", "\u5357\u5357\u4e1c",
    "\u5357", "\u5357\u5357\u897f", "\u897f\u5357", "\u897f\u5357\u897f",
    "\u897f", "\u897f\u5317\u897f", "\u897f\u5317", "\u5317\u5317\u897f",
]

MOON_PHASES = [
    (0, "\u65b0\u6708"),       # New Moon
    (1, "\u5ce8\u7709\u6708"), # Waxing Crescent
    (2, "\u4e0a\u5f26\u6708"), # First Quarter
    (3, "\u76c8\u51f8\u6708"), # Waxing Gibbous
    (4, "\u6ee1\u6708"),       # Full Moon
    (5, "\u4e8f\u51f8\u6708"), # Waning Gibbous
    (6, "\u4e0b\u5f26\u6708"), # Last Quarter
    (7, "\u6b8b\u6708"),       # Waning Crescent
]

MOON_PHASE_EN = {
    "\u65b0\u6708": "New Moon",
    "\u5ce8\u7709\u6708": "Waxing Crescent",
    "\u4e0a\u5f26\u6708": "First Quarter",
    "\u76c8\u51f8\u6708": "Waxing Gibbous",
    "\u6ee1\u6708": "Full Moon",
    "\u4e8f\u51f8\u6708": "Waning Gibbous",
    "\u4e0b\u5f26\u6708": "Last Quarter",
    "\u6b8b\u6708": "Waning Crescent",
}


def _wind_direction(degrees):
    idx = int((degrees + 11.25) / 22.5) % 16
    return WIND_DIRS[idx]


def _parse_time(t):
    """Parse 'HH:MM' to fractional hours."""
    parts = t.split(":")
    return int(parts[0]) + int(parts[1]) / 60.0


def _format_time(h):
    """Format fractional hours as 'HH:MM'."""
    h = h % 24.0
    return "{:02d}:{:02d}".format(int(h), int((h % 1) * 60))


def _moon_phase(dt=None):
    """Calculate moon phase, illumination, and phase fraction.

    Returns (cn_name, en_name, illumination_percent, phase_frac).
    """
    if dt is None:
        dt = datetime.datetime.utcnow()
    elif isinstance(dt, datetime.date):
        dt = datetime.datetime(dt.year, dt.month, dt.day)

    ref = datetime.datetime(2000, 1, 6, 18, 14)
    synodic = 29.53058867
    days_since = (dt - ref).total_seconds() / 86400.0
    phase_frac = (days_since % synodic) / synodic

    illumination = int(round((1 - math.cos(2 * math.pi * phase_frac)) / 2 * 100))
    idx = int(phase_frac * 8) % 8
    cn = MOON_PHASES[idx][1]
    en = MOON_PHASE_EN[cn]

    return cn, en, illumination, phase_frac


def _moon_rise_set(phase_frac, sunrise_str, sunset_str):
    """Approximate moonrise/moonset from phase and sun times."""
    sunrise_h = _parse_time(sunrise_str)
    sunset_h = _parse_time(sunset_str)
    solar_noon = (sunrise_h + sunset_h) / 2.0
    moon_transit = (solar_noon + phase_frac * 24.0) % 24.0
    moonrise = (moon_transit - 6.0) % 24.0
    moonset = (moon_transit + 6.0) % 24.0
    return _format_time(moonrise), _format_time(moonset)


def _milky_way(moon_illum, month):
    """Return (rating, note) for Milky Way visibility."""
    core_season = 4 <= month <= 9

    if moon_illum > 75:
        # \u6708\u5149\u8fc7\u5f3a = moonlight too bright
        return "\u8f83\u5dee", "\u6708\u5149\u8fc7\u5f3a"
    if moon_illum > 50:
        if core_season:
            return "\u4e00\u822c", "\u6838\u5fc3\u53ef\u89c1\uff0c\u6708\u5149\u5e72\u6270"
        return "\u8f83\u5dee", "\u6838\u5fc3\u4e0d\u53ef\u89c1"
    if moon_illum > 25:
        if core_season:
            return "\u826f\u597d", "\u6838\u5fc3\u53ef\u89c1\uff0c\u6708\u5149\u8f83\u5f31"
        return "\u4e00\u822c", "\u6838\u5fc3\u4e0d\u53ef\u89c1"
    # moon_illum <= 25
    if core_season:
        return "\u6781\u4f73", "\u6838\u5fc3\u53ef\u89c1\uff0c\u6708\u5149\u5fae\u5f31"
    return "\u826f\u597d", "\u6838\u5fc3\u4e0d\u53ef\u89c1\uff0c\u6697\u591c"


def _aqi_level(aqi):
    """Return Chinese AQI level label."""
    if aqi <= 50:
        return "\u4f18"       # Excellent
    if aqi <= 100:
        return "\u826f"       # Good
    if aqi <= 150:
        return "\u8f7b\u5ea6\u6c61\u67d3"  # Light pollution
    if aqi <= 200:
        return "\u4e2d\u5ea6\u6c61\u67d3"  # Moderate pollution
    if aqi <= 300:
        return "\u91cd\u5ea6\u6c61\u67d3"  # Heavy pollution
    return "\u4e25\u91cd\u6c61\u67d3"      # Severe pollution


def collect():
    lat = config.WEATHER_LAT
    lon = config.WEATHER_LON
    url = (
        "https://api.open-meteo.com/v1/forecast"
        "?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,"
        "weather_code,wind_speed_10m,wind_direction_10m"
        "&hourly=temperature_2m,weather_code"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        "&timezone=auto&forecast_days=3"
    ).format(lat=lat, lon=lon)

    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        data = resp.json()
    except Exception:
        return None

    # World city temperatures (best-effort)
    city_weather = []
    try:
        city_url = (
            "https://api.open-meteo.com/v1/forecast"
            "?latitude=37.87,40.71,48.86"
            "&longitude=-122.27,-74.01,2.35"
            "&current=temperature_2m,weather_code&timezone=auto"
        )
        city_resp = requests.get(city_url, timeout=10)
        city_resp.raise_for_status()
        city_raw = city_resp.json()
        if isinstance(city_raw, list):
            for item in city_raw:
                c = item.get("current", {})
                city_weather.append({
                    "temp_c": str(int(round(c.get("temperature_2m", 0)))),
                    "weather_code": c.get("weather_code", -1),
                })
    except Exception:
        pass

    # Air quality (separate API, best-effort)
    aqi_data = {}
    try:
        aqi_url = (
            "https://air-quality-api.open-meteo.com/v1/air-quality"
            "?latitude={lat}&longitude={lon}"
            "&current=us_aqi,pm2_5,pm10"
        ).format(lat=lat, lon=lon)
        aqi_resp = requests.get(aqi_url, timeout=10)
        aqi_resp.raise_for_status()
        aqi_raw = aqi_resp.json().get("current", {})
        us_aqi = int(round(aqi_raw.get("us_aqi", 0)))
        aqi_data = {
            "aqi": us_aqi,
            "level": _aqi_level(us_aqi),
            "pm25": str(round(aqi_raw.get("pm2_5", 0), 1)),
            "pm10": str(round(aqi_raw.get("pm10", 0), 1)),
        }
    except Exception:
        pass

    cur = data.get("current", {})
    daily = data.get("daily", {})

    wcode = cur.get("weather_code", -1)
    description = WMO_CODES.get(wcode, "\u672a\u77e5")
    wind_deg = cur.get("wind_direction_10m", 0)

    forecast = []
    times = daily.get("time", [])
    for i in range(len(times)):
        fcode = daily.get("weather_code", [0])[i] if i < len(daily.get("weather_code", [])) else 0
        forecast.append({
            "date": times[i],
            "max_c": str(int(round(daily["temperature_2m_max"][i]))),
            "min_c": str(int(round(daily["temperature_2m_min"][i]))),
            "desc": WMO_CODES.get(fcode, ""),
            "weather_code": fcode,
        })

    sunrise_raw = daily.get("sunrise", [""])[0]
    sunset_raw = daily.get("sunset", [""])[0]
    sunrise = sunrise_raw.split("T")[1] if "T" in sunrise_raw else sunrise_raw
    sunset = sunset_raw.split("T")[1] if "T" in sunset_raw else sunset_raw

    moon_cn, moon_en, moon_illum, phase_frac = _moon_phase()
    moonrise, moonset = _moon_rise_set(phase_frac, sunrise, sunset)

    today = datetime.date.today()
    mw_rating, mw_note = _milky_way(moon_illum, today.month)

    # Hourly forecast — next 12 hours from current hour
    hourly = []
    h_times = data.get("hourly", {}).get("time", [])
    h_temps = data.get("hourly", {}).get("temperature_2m", [])
    h_codes = data.get("hourly", {}).get("weather_code", [])
    now_str = datetime.datetime.now().strftime("%Y-%m-%dT%H:00")
    start_idx = 0
    for i, t in enumerate(h_times):
        if t >= now_str:
            start_idx = i
            break
    for i in range(start_idx, min(start_idx + 12, len(h_times))):
        hourly.append({
            "hour": h_times[i].split("T")[1][:2],
            "temp_c": round(h_temps[i], 1),
            "weather_code": h_codes[i] if i < len(h_codes) else 0,
        })

    astronomy = {
        "sunrise": sunrise,
        "sunset": sunset,
        "moonrise": moonrise,
        "moonset": moonset,
        "moon_phase": moon_cn,
        "moon_phase_en": moon_en,
        "moon_illumination": str(moon_illum),
        "milky_way_rating": mw_rating,
        "milky_way_note": mw_note,
    }

    return {
        "temp_c": str(int(round(cur.get("temperature_2m", 0)))),
        "feels_like_c": str(int(round(cur.get("apparent_temperature", 0)))),
        "description": description,
        "weather_code": wcode,
        "humidity": str(cur.get("relative_humidity_2m", "")),
        "wind_speed_kmh": str(int(round(cur.get("wind_speed_10m", 0)))),
        "wind_dir": _wind_direction(wind_deg),
        "forecast": forecast,
        "hourly": hourly,
        "astronomy": astronomy,
        "air_quality": aqi_data,
        "city_weather": city_weather,
    }
