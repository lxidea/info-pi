"""Astronomy events collector — static schedule, pure datetime math."""

import datetime

# Major annual meteor showers: (name_cn, month, peak_day)
METEOR_SHOWERS = [
    ("\u8c61\u9650\u4eea\u5ea7\u6d41\u661f\u96e8", 1, 4),
    ("\u5929\u7434\u5ea7\u6d41\u661f\u96e8", 4, 22),
    ("\u5b9d\u74f6\u5ea7\u03b7\u6d41\u661f\u96e8", 5, 6),
    ("\u5b9d\u74f6\u5ea7\u03b4\u6d41\u661f\u96e8", 7, 30),
    ("\u82f1\u4ed9\u5ea7\u6d41\u661f\u96e8", 8, 12),
    ("\u5929\u9f99\u5ea7\u6d41\u661f\u96e8", 10, 8),
    ("\u730e\u6237\u5ea7\u6d41\u661f\u96e8", 10, 21),
    ("\u72ee\u5b50\u5ea7\u6d41\u661f\u96e8", 11, 17),
    ("\u53cc\u5b50\u5ea7\u6d41\u661f\u96e8", 12, 14),
    ("\u5c0f\u718a\u5ea7\u6d41\u661f\u96e8", 12, 22),
]

# Notable eclipses 2024-2030: (year, month, day, description_cn)
ECLIPSES = [
    (2024, 4, 8, "\u65e5\u5168\u98df"),
    (2024, 9, 18, "\u6708\u504f\u98df"),
    (2024, 10, 2, "\u65e5\u73af\u98df"),
    (2025, 3, 14, "\u6708\u5168\u98df"),
    (2025, 3, 29, "\u65e5\u504f\u98df"),
    (2025, 9, 7, "\u6708\u5168\u98df"),
    (2025, 9, 21, "\u65e5\u504f\u98df"),
    (2026, 2, 17, "\u65e5\u73af\u98df"),
    (2026, 3, 3, "\u6708\u5168\u98df"),
    (2026, 8, 12, "\u65e5\u5168\u98df"),
    (2026, 8, 28, "\u6708\u504f\u98df"),
    (2027, 2, 6, "\u65e5\u73af\u98df"),
    (2027, 2, 20, "\u534a\u5f71\u6708\u98df"),
    (2027, 7, 18, "\u534a\u5f71\u6708\u98df"),
    (2027, 8, 2, "\u65e5\u5168\u98df"),
    (2028, 1, 12, "\u6708\u504f\u98df"),
    (2028, 1, 26, "\u65e5\u73af\u98df"),
    (2028, 7, 6, "\u6708\u504f\u98df"),
    (2028, 7, 22, "\u65e5\u5168\u98df"),
    (2028, 12, 31, "\u6708\u5168\u98df"),
    (2029, 1, 14, "\u65e5\u504f\u98df"),
    (2029, 6, 12, "\u65e5\u504f\u98df"),
    (2029, 6, 26, "\u6708\u5168\u98df"),
    (2029, 7, 11, "\u65e5\u5168\u98df"),
    (2029, 12, 5, "\u65e5\u504f\u98df"),
    (2029, 12, 20, "\u6708\u5168\u98df"),
    (2030, 6, 1, "\u65e5\u73af\u98df"),
    (2030, 6, 15, "\u6708\u504f\u98df"),
    (2030, 11, 25, "\u65e5\u5168\u98df"),
    (2030, 12, 9, "\u534a\u5f71\u6708\u98df"),
]


def get_upcoming_events(today=None, days_ahead=60):
    """Return up to 3 upcoming astronomy events within days_ahead days."""
    if today is None:
        today = datetime.date.today()

    horizon = today + datetime.timedelta(days=days_ahead)
    events = []

    # Meteor showers for this year and next
    for year in (today.year, today.year + 1):
        for name, month, day in METEOR_SHOWERS:
            try:
                d = datetime.date(year, month, day)
            except ValueError:
                continue
            if today <= d <= horizon:
                delta = (d - today).days
                events.append({
                    "name": name,
                    "date": d.strftime("%m/%d"),
                    "days_away": delta,
                    "type": "meteor",
                })

    # Eclipses
    for year, month, day, desc in ECLIPSES:
        try:
            d = datetime.date(year, month, day)
        except ValueError:
            continue
        if today <= d <= horizon:
            delta = (d - today).days
            events.append({
                "name": desc,
                "date": d.strftime("%m/%d"),
                "days_away": delta,
                "type": "eclipse",
            })

    events.sort(key=lambda e: e["days_away"])
    return events[:3]
