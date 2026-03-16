"""Date and time collector with world clocks."""

from datetime import datetime, timedelta

WEEKDAYS = [
    "\u661f\u671f\u4e00", "\u661f\u671f\u4e8c", "\u661f\u671f\u4e09",
    "\u661f\u671f\u56db", "\u661f\u671f\u4e94", "\u661f\u671f\u516d",
    "\u661f\u671f\u65e5",
]

# World clock cities: (display_name, std_utc_offset_hours, dst_type)
WORLD_CLOCKS = [
    ("\u4f2f\u514b\u5229", -8, "us"),      # Berkeley (Pacific)
    ("\u7ebd\u7ea6", -5, "us"),             # New York (Eastern)
    ("\u5df4\u9ece", 1, "eu"),              # Paris (CET)
]


def _get_utc_offset(utc_dt, std_offset, dst_type):
    """Return current UTC offset (hours) accounting for DST."""
    if dst_type is None:
        return std_offset

    year = utc_dt.year

    if dst_type == "us":
        # Second Sunday of March, 2 AM local standard time
        mar1_wd = datetime(year, 3, 1).weekday()
        second_sun_mar = 1 + (6 - mar1_wd) % 7 + 7
        dst_start = datetime(year, 3, second_sun_mar) + timedelta(hours=2 - std_offset)
        # First Sunday of November, 2 AM local daylight time
        nov1_wd = datetime(year, 11, 1).weekday()
        first_sun_nov = 1 + (6 - nov1_wd) % 7
        dst_end = datetime(year, 11, first_sun_nov) + timedelta(hours=2 - std_offset - 1)

    elif dst_type == "eu":
        # Last Sunday of March at 01:00 UTC
        mar31_wd = datetime(year, 3, 31).weekday()
        last_sun_mar = 31 - (mar31_wd - 6) % 7
        dst_start = datetime(year, 3, last_sun_mar, 1)
        # Last Sunday of October at 01:00 UTC
        oct31_wd = datetime(year, 10, 31).weekday()
        last_sun_oct = 31 - (oct31_wd - 6) % 7
        dst_end = datetime(year, 10, last_sun_oct, 1)
    else:
        return std_offset

    if dst_start <= utc_dt < dst_end:
        return std_offset + 1
    return std_offset


def collect():
    now = datetime.now()
    utc_now = datetime.utcnow()
    local_date = now.date()

    world_clocks = []
    for city, std_off, dst_type in WORLD_CLOCKS:
        offset = _get_utc_offset(utc_now, std_off, dst_type)
        city_dt = utc_now + timedelta(hours=offset)
        day_diff = (city_dt.date() - local_date).days
        world_clocks.append({
            "city": city,
            "time": city_dt.strftime("%H:%M"),
            "day_offset": day_diff,
        })

    return {
        "date": now.strftime("%Y-%m-%d"),
        "day_of_week": WEEKDAYS[now.weekday()],
        "time": now.strftime("%H:%M:%S"),
        "world_clocks": world_clocks,
    }
