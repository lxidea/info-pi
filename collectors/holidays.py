"""Chinese public holidays and makeup workdays.

Data source: State Council (国务院) annual holiday announcements.
Update this file each November when the next year's schedule is published.
"""

import datetime

# Format: "MM-DD": "holiday name"
# workdays: list of "MM-DD" strings (Sat/Sun that become workdays due to 调休)
HOLIDAYS = {
    2026: {
        "holidays": {
            # 元旦 New Year's Day: Jan 1-3
            "01-01": "元旦",
            "01-02": "元旦",
            "01-03": "元旦",
            # 春节 Spring Festival: Feb 15-23 (9 days!)
            "02-15": "除夕",
            "02-16": "春节",
            "02-17": "春节",
            "02-18": "春节",
            "02-19": "春节",
            "02-20": "春节",
            "02-21": "春节",
            "02-22": "春节",
            "02-23": "春节",
            # 清明节 Qingming: Apr 4-6
            "04-04": "清明节",
            "04-05": "清明节",
            "04-06": "清明节",
            # 劳动节 Labor Day: May 1-5
            "05-01": "劳动节",
            "05-02": "劳动节",
            "05-03": "劳动节",
            "05-04": "劳动节",
            "05-05": "劳动节",
            # 端午节 Dragon Boat: Jun 19-21
            "06-19": "端午节",
            "06-20": "端午节",
            "06-21": "端午节",
            # 中秋节 Mid-Autumn: Sep 25-27
            "09-25": "中秋节",
            "09-26": "中秋节",
            "09-27": "中秋节",
            # 国庆节 National Day: Oct 1-7
            "10-01": "国庆节",
            "10-02": "国庆节",
            "10-03": "国庆节",
            "10-04": "国庆节",
            "10-05": "国庆节",
            "10-06": "国庆节",
            "10-07": "国庆节",
        },
        "workdays": [
            "01-04",  # 元旦调休
            "02-14",  # 春节调休
            "02-28",  # 春节调休
            "05-09",  # 劳动节调休
            "09-20",  # 国庆节调休
            "10-10",  # 国庆节调休
        ],
    },
}


def get_month_markers(year=None, month=None):
    """Return holiday and workday markers for a given month.

    Returns:
        dict with:
            "holidays": {day_int: "name", ...}
            "workdays": [day_int, ...]
    """
    if year is None or month is None:
        today = datetime.date.today()
        year = today.year
        month = today.month

    year_data = HOLIDAYS.get(year, {})
    month_prefix = "{:02d}-".format(month)

    holidays = {}
    for date_str, name in year_data.get("holidays", {}).items():
        if date_str.startswith(month_prefix):
            day = int(date_str[3:5])
            holidays[day] = name

    workdays = []
    for date_str in year_data.get("workdays", []):
        if date_str.startswith(month_prefix):
            workdays.append(int(date_str[3:5]))

    return {"holidays": holidays, "workdays": workdays}
