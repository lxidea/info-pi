"""Weather collector: QWeather (和风) or Open-Meteo + moon phase + milky way."""

import os
import json
import time
import base64
import math
import datetime
import requests
import config


def _b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def _ed25519_seed(pem_or_path):
    """Extract the 32-byte Ed25519 seed from a PKCS8 PEM (text or file path)."""
    txt = pem_or_path
    if "BEGIN" not in txt and os.path.exists(txt):
        with open(txt) as f:
            txt = f.read()
    body = "".join(l.strip() for l in txt.splitlines() if "-----" not in l)
    return base64.b64decode(body)[-32:]      # PKCS8 Ed25519: seed = last 32 bytes


def _qweather_jwt():
    """Build a signed EdDSA JWT for QWeather (or None if JWT isn't configured)."""
    sub = getattr(config, "QWEATHER_JWT_SUB", "")
    kid = getattr(config, "QWEATHER_JWT_KID", "")
    keyref = getattr(config, "QWEATHER_JWT_KEY", "")
    if not (sub and kid and keyref):
        return None
    from collectors import _ed25519
    seed = _ed25519_seed(keyref)
    now = int(time.time())
    header = {"alg": "EdDSA", "kid": kid}
    payload = {"sub": sub, "iat": now - 30, "exp": now + 900}
    signing_input = (_b64url(json.dumps(header, separators=(",", ":")).encode())
                     + b"." +
                     _b64url(json.dumps(payload, separators=(",", ":")).encode()))
    sig = _ed25519.sign(signing_input, seed)
    return (signing_input + b"." + _b64url(sig)).decode()

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

# QWeather icon code → WMO weather code, so the frontend (which keys icons
# off WMO codes) works unchanged. QWeather also returns a Chinese `text`
# description directly, which we use for the label. See
# https://dev.qweather.com/docs/resource/icons/
QWEATHER_ICON_TO_WMO = {
    100: 0, 150: 0,                       # 晴
    101: 2, 151: 2, 102: 1, 152: 1,       # 多云 / 少云
    103: 1, 153: 1,                       # 晴间多云
    104: 3, 154: 3,                       # 阴
    300: 80, 350: 80, 301: 81, 351: 81,   # 阵雨
    302: 95, 303: 99, 304: 96,            # 雷阵雨 / 强雷阵雨 / 伴冰雹
    305: 61, 309: 51, 314: 63,            # 小雨 / 毛毛雨 / 小到中雨
    306: 63, 315: 65, 399: 63,            # 中雨 / 中到大雨 / 雨
    307: 65, 308: 65, 310: 65, 311: 65,   # 大雨 / 极端 / 暴雨 / 大暴雨
    312: 65, 316: 65, 317: 65, 318: 65,   # 特大暴雨 / 大到暴雨 ...
    313: 66,                              # 冻雨
    400: 71, 408: 73, 401: 73, 409: 75,   # 小雪 / 小到中 / 中雪 / 中到大
    402: 75, 403: 75, 410: 75, 499: 73,   # 大雪 / 暴雪 / 大到暴雪 / 雪
    404: 85, 406: 85, 407: 86,            # 雨夹雪 / 阵雨夹雪 / 阵雪
    405: 71,                              # 雨雪天气
    500: 45, 501: 45, 509: 45, 510: 45,   # 薄雾 / 雾 / 浓雾 / 强浓雾
    514: 45, 515: 48,                     # 大雾 / 特强浓雾
    502: 45, 511: 45, 512: 45, 513: 45,   # 霾 / 中度霾 / 重度霾 / 严重霾
    503: 45, 504: 45, 507: 45, 508: 45,   # 扬沙 / 浮尘 / 沙尘暴 / 强沙尘暴
    900: 0, 901: 3, 999: -1,              # 热 / 冷 / 未知
}


def _qw_wmo(icon):
    try:
        return QWEATHER_ICON_TO_WMO.get(int(icon), -1)
    except (TypeError, ValueError):
        return -1


def _hhmm(s):
    """QWeather time may be 'HH:MM' or ISO '...THH:MM+08:00' → 'HH:MM'."""
    if not s:
        return ""
    if "T" in s:
        s = s.split("T")[1]
    return s[:5]


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


# Rating ladder, worst \u2192 best (must match MW_CLASS keys in dashboard.js)
_MW_LADDER = ["\u8f83\u5dee", "\u4e00\u822c", "\u826f\u597d", "\u6781\u4f73"]


def _milky_way(moon_illum, month, cloud_cover=0, weather_code=-1):
    """Return (rating, note) for Milky Way visibility.

    Combines three factors, in order of how decisively each kills visibility:
      1. Sky obstruction \u2014 precipitation / fog / heavy cloud block the sky
         entirely, no matter how dark the night is.
      2. Moonlight \u2014 a bright moon washes out the faint galactic band.
      3. Galactic-core season \u2014 the bright core is only up Apr\u2013Sep here.
    """
    core_season = 4 <= month <= 9
    cc = int(cloud_cover or 0)

    # 1) Sky blocked outright \u2014 rain/snow/fog/thunderstorm, or thick cloud.
    if weather_code >= 45:                       # 45+ = fog / drizzle / rain / snow / storm
        return "\u8f83\u5dee", "\u9634\u96e8\u6216\u96fe\uff0c\u5929\u7a7a\u906e\u6321"   # overcast rain/fog, sky blocked
    if cc >= 70 or weather_code == 3:            # 3 = overcast
        return "\u8f83\u5dee", "\u4e91\u91cf{}%\uff0c\u4e91\u5c42\u8fc7\u539a".format(cc)  # cloud NN%, too thick

    # 2) Base score from moonlight + whether the core is even up this season.
    if moon_illum > 75:
        score, mnote = 0, "\u6708\u5149\u8fc7\u5f3a"                       # moon too bright
    elif moon_illum > 50:
        score, mnote = (1 if core_season else 0), "\u6708\u5149\u5e72\u6270"   # moonlight interferes
    elif moon_illum > 25:
        score, mnote = (2 if core_season else 1), "\u6708\u5149\u8f83\u5f31"   # moonlight weak
    else:
        score, mnote = (3 if core_season else 2), "\u6708\u5149\u5fae\u5f31"   # moonlight faint

    # 3) Partial-cloud penalty on an otherwise clear, dark sky.
    if cc >= 40:
        score = max(0, score - 2)
        cnote = "\u4e91\u91cf{}%".format(cc)        # cloud NN%
    elif cc >= 20:
        score = max(0, score - 1)
        cnote = "\u5c11\u91cf\u4e91"                  # some cloud
    else:
        cnote = "\u6674\u6717"                        # clear

    core_note = "\u6838\u5fc3\u53ef\u89c1" if core_season else "\u6838\u5fc3\u4e0d\u53ef\u89c1"  # core (in)visible
    return _MW_LADDER[score], "{}\uff0c{}\uff0c{}".format(core_note, cnote, mnote)


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


def _world_cities():
    """World-city temps (Berkeley / New York / Paris) via keyless Open-Meteo.
    Best-effort — used by both providers."""
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
    return city_weather


def collect():
    """Dispatch to QWeather (if a key OR JWT is configured) else Open-Meteo."""
    if getattr(config, "QWEATHER_KEY", "") or getattr(config, "QWEATHER_JWT_KEY", ""):
        return _collect_qweather()
    return _collect_openmeteo()


def _collect_openmeteo():
    lat = config.WEATHER_LAT
    lon = config.WEATHER_LON
    url = (
        "https://api.open-meteo.com/v1/forecast"
        "?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,"
        "weather_code,cloud_cover,wind_speed_10m,wind_direction_10m"
        "&hourly=temperature_2m,weather_code"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,"
        "wind_speed_10m_max,wind_direction_10m_dominant"
        "&timezone=auto&forecast_days=3"
    ).format(lat=lat, lon=lon)

    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        data = resp.json()
    except Exception:
        return None

    # World city temperatures (best-effort)
    city_weather = _world_cities()

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
    cloud_cover = cur.get("cloud_cover", 0)
    description = WMO_CODES.get(wcode, "\u672a\u77e5")
    wind_deg = cur.get("wind_direction_10m", 0)

    forecast = []
    times = daily.get("time", [])
    wind_max = daily.get("wind_speed_10m_max", [])
    wind_deg_arr = daily.get("wind_direction_10m_dominant", [])
    for i in range(len(times)):
        fcode = daily.get("weather_code", [0])[i] if i < len(daily.get("weather_code", [])) else 0
        wmax = int(round(wind_max[i])) if i < len(wind_max) else 0
        wdeg = int(wind_deg_arr[i]) if i < len(wind_deg_arr) else 0
        forecast.append({
            "date": times[i],
            "max_c": str(int(round(daily["temperature_2m_max"][i]))),
            "min_c": str(int(round(daily["temperature_2m_min"][i]))),
            "desc": WMO_CODES.get(fcode, ""),
            "weather_code": fcode,
            "wind_speed_kmh": wmax,
            "wind_dir_deg": wdeg,
            "wind_dir": _wind_direction(wdeg),
        })

    sunrise_raw = daily.get("sunrise", [""])[0]
    sunset_raw = daily.get("sunset", [""])[0]
    sunrise = sunrise_raw.split("T")[1] if "T" in sunrise_raw else sunrise_raw
    sunset = sunset_raw.split("T")[1] if "T" in sunset_raw else sunset_raw

    moon_cn, moon_en, moon_illum, phase_frac = _moon_phase()
    moonrise, moonset = _moon_rise_set(phase_frac, sunrise, sunset)

    today = datetime.date.today()
    mw_rating, mw_note = _milky_way(moon_illum, today.month, cloud_cover, wcode)

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
        "latitude": lat,
        "longitude": lon,
    }

    return {
        "temp_c": str(int(round(cur.get("temperature_2m", 0)))),
        "feels_like_c": str(int(round(cur.get("apparent_temperature", 0)))),
        "description": description,
        "weather_code": wcode,
        "humidity": str(cur.get("relative_humidity_2m", "")),
        "wind_speed_kmh": str(int(round(cur.get("wind_speed_10m", 0)))),
        "wind_dir": _wind_direction(wind_deg),
        "wind_dir_deg": int(wind_deg),
        "cloud_cover": int(cloud_cover or 0),
        "forecast": forecast,
        "hourly": hourly,
        "astronomy": astronomy,
        "air_quality": aqi_data,
        "city_weather": city_weather,
    }


def _collect_qweather():
    """China-native weather via QWeather (和风天气). Produces the same output
    dict as the Open-Meteo path; icons map through QWeather→WMO codes."""
    lat = config.WEATHER_LAT
    lon = config.WEATHER_LON
    host = getattr(config, "QWEATHER_HOST", "devapi.qweather.com")
    key = config.QWEATHER_KEY
    loc = "{:.2f},{:.2f}".format(lon, lat)      # QWeather order is lon,lat
    base = "https://{}/v7".format(host)

    # Auth: prefer JWT (Bearer) if configured, else legacy key query param.
    jwt = _qweather_jwt()
    headers = {"Authorization": "Bearer " + jwt} if jwt else {}
    common = {} if jwt else {"key": key}

    def _get(path):
        params = dict(common, location=loc)
        r = requests.get("{}/{}".format(base, path),
                         params=params, headers=headers, timeout=15)
        r.raise_for_status()
        j = r.json()
        if str(j.get("code")) != "200":
            raise ValueError("QWeather code " + str(j.get("code")))
        return j

    # current + 3-day forecast are required
    try:
        now = _get("weather/now").get("now", {})
        daily = _get("weather/3d").get("daily", [])
    except Exception:
        return None
    if not daily:
        return None
    d0 = daily[0]

    wcode = _qw_wmo(now.get("icon"))
    cloud_cover = int(now.get("cloud") or 0)
    wind_deg = int(float(now.get("wind360") or 0))
    description = now.get("text") or WMO_CODES.get(wcode, "未知")

    forecast = []
    for d in daily:
        wdeg = int(float(d.get("wind360Day") or 0))
        forecast.append({
            "date": d.get("fxDate", ""),
            "max_c": str(int(round(float(d.get("tempMax", 0))))),
            "min_c": str(int(round(float(d.get("tempMin", 0))))),
            "desc": d.get("textDay", ""),
            "weather_code": _qw_wmo(d.get("iconDay")),
            "wind_speed_kmh": int(round(float(d.get("windSpeedDay") or 0))),
            "wind_dir_deg": wdeg,
            "wind_dir": _wind_direction(wdeg),
        })

    sunrise = _hhmm(d0.get("sunrise", ""))
    sunset = _hhmm(d0.get("sunset", ""))
    moonrise = _hhmm(d0.get("moonrise", ""))
    moonset = _hhmm(d0.get("moonset", ""))

    moon_cn, moon_en, moon_illum, phase_frac = _moon_phase()
    if not (moonrise and moonset):          # QWeather blanks these some days
        moonrise, moonset = _moon_rise_set(phase_frac, sunrise or "06:00", sunset or "18:00")

    today = datetime.date.today()
    mw_rating, mw_note = _milky_way(moon_illum, today.month, cloud_cover, wcode)

    # hourly (best-effort) — next 12 hours
    hourly = []
    try:
        for h in _get("weather/24h").get("hourly", [])[:12]:
            hourly.append({
                "hour": _hhmm(h.get("fxTime", ""))[:2],
                "temp_c": round(float(h.get("temp", 0)), 1),
                "weather_code": _qw_wmo(h.get("icon")),
            })
    except Exception:
        pass

    # air quality (best-effort)
    aqi_data = {}
    try:
        a = _get("air/now").get("now", {})
        us_aqi = int(float(a.get("aqi", 0)))
        aqi_data = {
            "aqi": us_aqi,
            "level": a.get("category") or _aqi_level(us_aqi),
            "pm25": str(a.get("pm2p5", "")),
            "pm10": str(a.get("pm10", "")),
        }
    except Exception:
        pass

    astronomy = {
        "sunrise": sunrise, "sunset": sunset,
        "moonrise": moonrise, "moonset": moonset,
        "moon_phase": moon_cn, "moon_phase_en": moon_en,
        "moon_illumination": str(moon_illum),
        "milky_way_rating": mw_rating, "milky_way_note": mw_note,
        "latitude": lat, "longitude": lon,
    }

    return {
        "temp_c": str(int(round(float(now.get("temp", 0))))),
        "feels_like_c": str(int(round(float(now.get("feelsLike", 0))))),
        "description": description,
        "weather_code": wcode,
        "humidity": str(now.get("humidity", "")),
        "wind_speed_kmh": str(int(round(float(now.get("windSpeed", 0))))),
        "wind_dir": _wind_direction(wind_deg),
        "wind_dir_deg": wind_deg,
        "cloud_cover": cloud_cover,
        "forecast": forecast,
        "hourly": hourly,
        "astronomy": astronomy,
        "air_quality": aqi_data,
        "city_weather": _world_cities(),
    }
