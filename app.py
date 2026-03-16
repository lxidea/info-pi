"""Info-Pi Flask application with background data collection."""

import threading
import time

from flask import Flask, jsonify, render_template

import config
from collectors import datetime_info, weather, astronomy_events, system_stats

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


def _start_collectors():
    t = threading.Thread(target=_weather_loop, daemon=True)
    t.start()


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/all")
def api_all():
    with _lock:
        snapshot = {
            "datetime": datetime_info.collect(),
            "weather": _data["weather"],
            "astronomy_events": astronomy_events.get_upcoming_events(),
            "system": system_stats.collect(),
        }
    return jsonify(snapshot)


_start_collectors()

if __name__ == "__main__":
    app.run(host=config.HOST, port=config.PORT, debug=config.DEBUG)
