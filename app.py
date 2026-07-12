"""Info-Pi Flask application with background data collection."""

import os
import threading
import time

from flask import Flask, jsonify, render_template

import config
from collectors import datetime_info, weather, astronomy_events, system_stats, holidays

app = Flask(__name__)

# Shared data store (protected by lock)
_lock = threading.Lock()
_data = {
    "weather": None,
}


def _weather_loop():
    while True:
        result = weather.collect()
        if result is not None:
            with _lock:
                _data["weather"] = result
            time.sleep(config.WEATHER_INTERVAL)
        else:
            # Transient fetch failure (the Pi's link is flaky). Retry soon
            # instead of leaving the dashboard blank for a whole interval —
            # otherwise one failed fetch at startup blanks weather for 15 min.
            time.sleep(30)


def _start_collectors():
    t = threading.Thread(target=_weather_loop, daemon=True)
    t.start()


_STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")


def _asset_ver():
    """Max mtime of the JS/CSS so <link>/<script> URLs change when they do —
    forces the kiosk browser to fetch fresh instead of serving a stale cache."""
    ver = 0
    for rel in ("js/dashboard.js", "css/dashboard.css"):
        try:
            ver = max(ver, int(os.path.getmtime(os.path.join(_STATIC_DIR, rel))))
        except OSError:
            pass
    return ver


@app.route("/")
def index():
    return render_template("index.html", ver=_asset_ver())


@app.route("/api/all")
def api_all():
    with _lock:
        snapshot = {
            "datetime": datetime_info.collect(),
            "weather": _data["weather"],
            "astronomy_events": astronomy_events.get_upcoming_events(),
            "system": system_stats.collect(),
            "calendar": holidays.get_month_markers(),
        }
    return jsonify(snapshot)


_start_collectors()

if __name__ == "__main__":
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)
