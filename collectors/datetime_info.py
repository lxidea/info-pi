"""Date and time collector with world clocks and lunar calendar."""

from datetime import datetime, timedelta

# Lunar calendar data from zhdate (1900-2100)
# 20-bit codes: top 1 bit = leap month big/small, middle 12 bits = month sizes, bottom 4 bits = leap month number
_YEAR_CODES = [
    19416, 19168, 42352, 21717, 53856, 55632, 91476, 22176, 39632, 21970,
    19168, 42422, 42192, 53840, 119381, 46400, 54944, 44450, 38320, 84343,
    18800, 42160, 46261, 27216, 27968, 109396, 11104, 38256, 21234, 18800,
    25958, 54432, 59984, 92821, 23248, 11104, 100067, 37600, 116951, 51536,
    54432, 120998, 46416, 22176, 107956, 9680, 37584, 53938, 43344, 46423,
    27808, 46416, 86869, 19872, 42416, 83315, 21168, 43432, 59728, 27296,
    44710, 43856, 19296, 43748, 42352, 21088, 62051, 55632, 23383, 22176,
    38608, 19925, 19152, 42192, 54484, 53840, 54616, 46400, 46752, 103846,
    38320, 18864, 43380, 42160, 45690, 27216, 27968, 44870, 43872, 38256,
    19189, 18800, 25776, 29859, 59984, 27480, 23232, 43872, 38613, 37600,
    51552, 55636, 54432, 55888, 30034, 22176, 43959, 9680, 37584, 51893,
    43344, 46240, 47780, 44368, 21977, 19360, 42416, 86390, 21168, 43312,
    31060, 27296, 44368, 23378, 19296, 42726, 42208, 53856, 60005, 54576,
    23200, 30371, 38608, 19195, 19152, 42192, 118966, 53840, 54560, 56645,
    46496, 22224, 21938, 18864, 42359, 42160, 43600, 111189, 27936, 44448,
    84835, 37744, 18936, 18800, 25776, 92326, 59984, 27296, 108228, 43744,
    37600, 53987, 51552, 54615, 54432, 55888, 23893, 22176, 42704, 21972,
    21200, 43448, 43344, 46240, 46758, 44368, 21920, 43940, 42416, 21168,
    45683, 26928, 29495, 27296, 44368, 84821, 19296, 42352, 21732, 53600,
    59752, 54560, 55968, 92838, 22224, 19168, 43476, 41680, 53584, 62034,
    54560,
]

# Chinese New Year Gregorian dates (1900-2100)
_CNY_DATES = [
    '19000131',
    '19010219', '19020208', '19030129', '19040216', '19050204',
    '19060125', '19070213', '19080202', '19090122', '19100210',
    '19110130', '19120218', '19130206', '19140126', '19150214',
    '19160203', '19170123', '19180211', '19190201', '19200220',
    '19210208', '19220128', '19230216', '19240205', '19250124',
    '19260213', '19270202', '19280123', '19290210', '19300130',
    '19310217', '19320206', '19330126', '19340214', '19350204',
    '19360124', '19370211', '19380131', '19390219', '19400208',
    '19410127', '19420215', '19430205', '19440125', '19450213',
    '19460202', '19470122', '19480210', '19490129', '19500217',
    '19510206', '19520127', '19530214', '19540203', '19550124',
    '19560212', '19570131', '19580218', '19590208', '19600128',
    '19610215', '19620205', '19630125', '19640213', '19650202',
    '19660121', '19670209', '19680130', '19690217', '19700206',
    '19710127', '19720215', '19730203', '19740123', '19750211',
    '19760131', '19770218', '19780207', '19790128', '19800216',
    '19810205', '19820125', '19830213', '19840202', '19850220',
    '19860209', '19870129', '19880217', '19890206', '19900127',
    '19910215', '19920204', '19930123', '19940210', '19950131',
    '19960219', '19970207', '19980128', '19990216', '20000205',
    '20010124', '20020212', '20030201', '20040122', '20050209',
    '20060129', '20070218', '20080207', '20090126', '20100214',
    '20110203', '20120123', '20130210', '20140131', '20150219',
    '20160208', '20170128', '20180216', '20190205', '20200125',
    '20210212', '20220201', '20230122', '20240210', '20250129',
    '20260217', '20270206', '20280126', '20290213', '20300203',
    '20310123', '20320211', '20330131', '20340219', '20350208',
    '20360128', '20370215', '20380204', '20390124', '20400212',
    '20410201', '20420122', '20430210', '20440130', '20450217',
    '20460206', '20470126', '20480214', '20490202', '20500123',
    '20510211', '20520201', '20530219', '20540208', '20550128',
    '20560215', '20570204', '20580124', '20590212', '20600202',
    '20610121', '20620209', '20630129', '20640217', '20650205',
    '20660126', '20670214', '20680203', '20690123', '20700211',
    '20710131', '20720219', '20730207', '20740127', '20750215',
    '20760205', '20770124', '20780212', '20790202', '20800122',
    '20810209', '20820129', '20830217', '20840206', '20850126',
    '20860214', '20870203', '20880124', '20890210', '20900130',
    '20910218', '20920207', '20930127', '20940215', '20950205',
    '20960125', '20970212', '20980201', '20990121', '21000209',
]

_LUNAR_MONTHS = [
    "\u6b63\u6708", "\u4e8c\u6708", "\u4e09\u6708", "\u56db\u6708",
    "\u4e94\u6708", "\u516d\u6708", "\u4e03\u6708", "\u516b\u6708",
    "\u4e5d\u6708", "\u5341\u6708", "\u5341\u4e00\u6708", "\u814a\u6708",
]

_LUNAR_DAYS = [
    "\u521d\u4e00", "\u521d\u4e8c", "\u521d\u4e09", "\u521d\u56db", "\u521d\u4e94",
    "\u521d\u516d", "\u521d\u4e03", "\u521d\u516b", "\u521d\u4e5d", "\u521d\u5341",
    "\u5341\u4e00", "\u5341\u4e8c", "\u5341\u4e09", "\u5341\u56db", "\u5341\u4e94",
    "\u5341\u516d", "\u5341\u4e03", "\u5341\u516b", "\u5341\u4e5d", "\u4e8c\u5341",
    "\u5eff\u4e00", "\u5eff\u4e8c", "\u5eff\u4e09", "\u5eff\u56db", "\u5eff\u4e94",
    "\u5eff\u516d", "\u5eff\u4e03", "\u5eff\u516b", "\u5eff\u4e5d", "\u4e09\u5341",
]


def _decode_year(year_code):
    """Decode year code into list of month day counts (12 or 13 entries)."""
    month_days = []
    for i in range(5, 17):
        month_days.insert(0, 30 if (year_code >> (i - 1)) & 1 else 29)
    if year_code & 0xf:
        leap_days = 30 if year_code >> 16 else 29
        month_days.insert(year_code & 0xf, leap_days)
    return month_days


def _solar_to_lunar(dt):
    """Convert datetime to (lunar_month, lunar_day, is_leap)."""
    lunar_year = dt.year
    cny = datetime.strptime(_CNY_DATES[lunar_year - 1900], '%Y%m%d')
    if (cny - dt).days > 0:
        lunar_year -= 1
        cny = datetime.strptime(_CNY_DATES[lunar_year - 1900], '%Y%m%d')

    days_passed = (dt - cny).days
    year_code = _YEAR_CODES[lunar_year - 1900]
    month_days = _decode_year(year_code)

    total = 0
    month = 0
    for i, md in enumerate(month_days):
        total += md
        if days_passed + 1 <= total:
            month = i + 1
            lunar_day = md - (total - days_passed) + 1
            break

    leap_month = False
    leap_idx = year_code & 0xf
    if leap_idx == 0 or month <= leap_idx:
        lunar_month = month
    else:
        lunar_month = month - 1

    if leap_idx != 0 and month == leap_idx + 1:
        leap_month = True

    return lunar_month, lunar_day, leap_month


def lunar_date_str(dt=None):
    """Return Chinese lunar date string like '二月初四'."""
    if dt is None:
        dt = datetime.now()
    lunar_month, lunar_day, is_leap = _solar_to_lunar(dt)
    prefix = "\u95f0" if is_leap else ""
    return prefix + _LUNAR_MONTHS[lunar_month - 1] + _LUNAR_DAYS[lunar_day - 1]

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
        "lunar_date": lunar_date_str(now),
        "day_of_week": WEEKDAYS[now.weekday()],
        "time": now.strftime("%H:%M:%S"),
        "world_clocks": world_clocks,
    }
