/* Info-Pi Dashboard — Fetch loop and DOM updates */

// WMO weather code to emoji icon
var WEATHER_ICON = {
    0: "\u2600",        // ☀ Clear sky
    1: "\u2600",        // ☀ Mainly clear
    2: "\u2601",        // ☁ Partly cloudy (⛅ doesn't render on Pi)
    3: "\u2601",        // ☁ Overcast
    45: "\u2601",       // ☁ Fog
    48: "\u2601",       // ☁ Rime fog
    51: "\u2614",       // ☔ Light drizzle
    53: "\u2614",       // ☔ Drizzle
    55: "\u2614",       // ☔ Dense drizzle
    61: "\u2614",       // ☔ Light rain
    63: "\u2614",       // ☔ Rain
    65: "\u2614",       // ☔ Heavy rain
    66: "\u2744",       // ❄ Light freezing rain
    67: "\u2744",       // ❄ Freezing rain
    71: "\u2744",       // ❄ Light snow
    73: "\u2744",       // ❄ Snow
    75: "\u2744",       // ❄ Heavy snow
    77: "\u2744",       // ❄ Snow grains
    80: "\u2614",       // ☔ Light showers
    81: "\u2614",       // ☔ Showers
    82: "\u2614",       // ☔ Heavy showers
    85: "\u2744",       // ❄ Light snow showers
    86: "\u2744",       // ❄ Snow showers
    95: "\u26C8",       // ⛈ Thunderstorm
    96: "\u26C8",       // ⛈ Thunderstorm w/ hail
    99: "\u26C8"        // ⛈ Heavy thunderstorm
};

function weatherIcon(code) {
    return WEATHER_ICON[code] || "\u2601";
}

// Stored city weather for world clocks
var _cityWeather = [];

function updateDateTime(dt) {
    if (!dt) return;
    document.getElementById("date").textContent = dt.date + (dt.lunar_date ? " " + dt.lunar_date : "");
    document.getElementById("day").textContent = dt.day_of_week;
    document.getElementById("time").textContent = dt.time;

    // World clocks with city temps
    var wcDiv = document.getElementById("world-clocks");
    wcDiv.innerHTML = "";
    var clocks = dt.world_clocks || [];
    clocks.forEach(function (wc, i) {
        if (i > 0) {
            var sep = document.createElement("span");
            sep.className = "world-clock-sep";
            sep.textContent = "|";
            wcDiv.appendChild(sep);
        }
        var el = document.createElement("span");
        el.className = "world-clock-item";
        var offsetStr = "";
        if (wc.day_offset === -1) offsetStr = '<span class="wc-offset">-1\u5929</span>';
        else if (wc.day_offset === 1) offsetStr = '<span class="wc-offset">+1\u5929</span>';
        var tempStr = "";
        if (_cityWeather[i]) {
            var cw = _cityWeather[i];
            tempStr = '<span class="wc-temp">' + weatherIcon(cw.weather_code) + ' ' + cw.temp_c + '\u00b0</span>';
        }
        el.innerHTML =
            '<span class="wc-city">' + wc.city + '</span> ' +
            '<span class="wc-time">' + wc.time + '</span>' +
            offsetStr + tempStr;
        wcDiv.appendChild(el);
    });
}

function updateWeather(w) {
    if (!w) {
        document.getElementById("w-desc").textContent = "\u6682\u65e0\u6570\u636e";
        return;
    }

    // Store city weather for world clocks
    _cityWeather = w.city_weather || [];

    // Main weather with icon (separate span to avoid Chinese font fallback hiding the glyph)
    var mainIcon = weatherIcon(w.weather_code);
    document.getElementById("w-temp").textContent = w.temp_c + "\u00b0C";
    var descEl = document.getElementById("w-desc");
    descEl.innerHTML = '<span class="weather-icon-sym">' + mainIcon + '</span> ' + w.description;
    document.getElementById("w-humidity").textContent = w.humidity;
    document.getElementById("w-wind").textContent = w.wind_speed_kmh;
    document.getElementById("w-wind-dir").textContent = w.wind_dir;
    document.getElementById("w-feels").textContent = w.feels_like_c;

    // Air quality
    var aqiEl = document.getElementById("w-aqi");
    var aq = w.air_quality;
    if (aq && aq.aqi) {
        var aqiClass = "aqi-good";
        if (aq.aqi > 200) aqiClass = "aqi-bad";
        else if (aq.aqi > 100) aqiClass = "aqi-unhealthy";
        else if (aq.aqi > 50) aqiClass = "aqi-moderate";
        aqiEl.innerHTML =
            '\u7a7a\u6c14: <span class="aqi-badge ' + aqiClass + '">' +
            aq.level + '(' + aq.aqi + ')</span> PM2.5 ' + aq.pm25;
    } else {
        aqiEl.textContent = "";
    }

    // Forecast with icons
    var fc = document.getElementById("w-forecast");
    fc.innerHTML = "";
    if (w.forecast) {
        w.forecast.forEach(function (day) {
            var el = document.createElement("div");
            el.className = "forecast-day";
            var fIcon = weatherIcon(day.weather_code);
            el.innerHTML =
                '<div>' + day.date.slice(5) + '</div>' +
                '<div class="temp">' + fIcon + ' ' + day.min_c + '\u2013' + day.max_c + '\u00b0</div>' +
                '<div>' + day.desc + '</div>';
            fc.appendChild(el);
        });
    }
}

var _hourlyLastKey = "";

function updateHourly(w) {
    var container = document.getElementById("w-hourly");
    if (!w || !w.hourly || w.hourly.length === 0) {
        container.textContent = "";
        _hourlyLastKey = "";
        return;
    }

    // Skip rebuild if data unchanged (weather refreshes every 15 min)
    var key = w.hourly[0].hour + "-" + w.hourly[w.hourly.length - 1].hour + "-" + w.hourly.length;
    if (key === _hourlyLastKey) return;
    _hourlyLastKey = key;

    var hours = w.hourly;
    var temps = hours.map(function (h) { return h.temp_c; });
    var minT = Math.min.apply(null, temps);
    var maxT = Math.max.apply(null, temps);
    var range = maxT - minT;

    // Bar height range in px
    var minBarH = 20;
    var maxBarH = 80;

    container.textContent = "";

    var label = document.createElement("div");
    label.className = "hourly-label";
    label.textContent = "\u9010\u65f6\u9884\u62a5";
    container.appendChild(label);

    var grid = document.createElement("div");
    grid.className = "hourly-grid";

    hours.forEach(function (h, i) {
        var col = document.createElement("div");
        col.className = "hourly-col";
        if (i === 0) col.classList.add("h-now");

        var hourEl = document.createElement("div");
        hourEl.className = "h-hour";
        hourEl.textContent = i === 0 ? "\u73b0\u5728" : h.hour;

        var iconEl = document.createElement("div");
        iconEl.className = "h-icon";
        iconEl.textContent = weatherIcon(h.weather_code);

        var tempEl = document.createElement("div");
        tempEl.className = "h-temp";
        var displayTemp = range > 3 ? Math.round(h.temp_c) + "\u00b0" : h.temp_c.toFixed(1) + "\u00b0";
        tempEl.textContent = displayTemp;

        var t = range > 0.2 ? (h.temp_c - minT) / range : 0.5;
        var barH = Math.round(minBarH + t * (maxBarH - minBarH));
        // Interpolate blue (#58a6ff) to orange (#f0883e)
        var r = Math.round(88 + t * (240 - 88));
        var g = Math.round(166 + t * (136 - 166));
        var b = Math.round(255 + t * (62 - 255));

        var barEl = document.createElement("div");
        barEl.className = "h-bar";
        barEl.style.height = barH + "px";
        barEl.style.background = "rgb(" + r + "," + g + "," + b + ")";

        col.appendChild(hourEl);
        col.appendChild(iconEl);
        col.appendChild(tempEl);
        col.appendChild(barEl);
        grid.appendChild(col);
    });

    container.appendChild(grid);
}

var MOON_EMOJI = {
    "New Moon": "\u25CF",          // ● New Moon
    "Waxing Crescent": "\u25D1",   // ◑ Waxing Crescent
    "First Quarter": "\u25D1",     // ◑ First Quarter
    "Waxing Gibbous": "\u25D1",    // ◑ Waxing Gibbous
    "Full Moon": "\u25CB",         // ○ Full Moon
    "Waning Gibbous": "\u25D0",    // ◐ Waning Gibbous
    "Last Quarter": "\u25D0",      // ◐ Last Quarter
    "Waning Crescent": "\u25D0"    // ◐ Waning Crescent
};

var MW_RATING_CLASS = {
    "\u6781\u4f73": "mw-excellent",
    "\u826f\u597d": "mw-good",
    "\u4e00\u822c": "mw-fair",
    "\u8f83\u5dee": "mw-poor"
};

function updateAstronomy(weather, events) {
    var leftCol = document.getElementById("astro-left");
    var rightCol = document.getElementById("astro-right");

    var astro = (weather && weather.astronomy) ? weather.astronomy : null;
    if (!astro) {
        leftCol.innerHTML = '<div class="astro-row" style="color:#8b949e">\u6682\u65e0\u6570\u636e</div>';
        rightCol.innerHTML = "";
        return;
    }

    // Left column: sun rise/set, moon rise/set
    leftCol.innerHTML =
        '<div class="astro-row">' +
            '<span class="astro-icon">\u2600</span>' +
            '<span class="astro-label">\u65e5\u51fa</span>' +
            '<span class="astro-value">' + astro.sunrise + '</span>' +
            '<span class="astro-label" style="margin-left:14px">\u65e5\u843d</span>' +
            '<span class="astro-value">' + astro.sunset + '</span>' +
        '</div>' +
        '<div class="astro-row">' +
            '<span class="astro-icon">\u263D</span>' +
            '<span class="astro-label">\u6708\u51fa</span>' +
            '<span class="astro-value">' + astro.moonrise + '</span>' +
            '<span class="astro-label" style="margin-left:14px">\u6708\u843d</span>' +
            '<span class="astro-value">' + astro.moonset + '</span>' +
        '</div>';

    // Right column: moon phase, milky way, events
    var moonEmoji = MOON_EMOJI[astro.moon_phase_en] || "\u25CB";
    var mwClass = MW_RATING_CLASS[astro.milky_way_rating] || "mw-fair";

    var rightHtml =
        '<div class="astro-row">' +
            '<span class="astro-icon">' + moonEmoji + '</span>' +
            '<span class="astro-moon-phase">' + astro.moon_phase + '</span>' +
            '<span class="astro-moon-illum">' + astro.moon_illumination + '%</span>' +
        '</div>' +
        '<div class="astro-mw">' +
            '<span class="astro-icon">\u2726</span>' +
            '<span style="color:#8b949e">\u94f6\u6cb3:</span> ' +
            '<span class="mw-rating ' + mwClass + '">' + astro.milky_way_rating + '</span>' +
            '<span class="mw-note">' + astro.milky_way_note + '</span>' +
        '</div>';

    if (events && events.length > 0) {
        events.forEach(function (ev) {
            var countdown = ev.days_away === 0 ? "\u4eca\u5929" : ev.days_away + "\u5929";
            var icon = ev.type === "eclipse" ? "\u25CF" : "\u2605";
            rightHtml +=
                '<div class="astro-event">' +
                    '<span class="event-name">' + icon + ' ' + ev.name + '</span>' +
                    '<span class="event-date">' + ev.date + '</span>' +
                    '<span class="event-countdown">' + countdown + '</span>' +
                '</div>';
        });
    }

    rightCol.innerHTML = rightHtml;
}

// Calendar
var _calLastMonth = -1;

function updateCalendar(calData) {
    var now = new Date();
    var year = now.getFullYear();
    var month = now.getMonth(); // 0-indexed
    var today = now.getDate();

    var hols = (calData && calData.holidays) ? calData.holidays : {};
    var works = (calData && calData.workdays) ? calData.workdays : [];

    // Skip rebuild if same month (but always update today highlight)
    if (_calLastMonth === month) {
        var days = document.querySelectorAll("#calendar-body .cal-day");
        days.forEach(function (el) {
            if (el.dataset.day) {
                el.classList.toggle("today", parseInt(el.dataset.day, 10) === today);
            }
        });
        return;
    }
    _calLastMonth = month;

    var monthNames = [
        "1\u6708", "2\u6708", "3\u6708", "4\u6708", "5\u6708", "6\u6708",
        "7\u6708", "8\u6708", "9\u6708", "10\u6708", "11\u6708", "12\u6708"
    ];
    var dowNames = ["\u4e00", "\u4e8c", "\u4e09", "\u56db", "\u4e94", "\u516d", "\u65e5"];

    // First day of month (0=Sun, convert to Mon-based: 0=Mon..6=Sun)
    var firstDay = new Date(year, month, 1).getDay();
    var startOffset = (firstDay + 6) % 7; // Mon=0, Sun=6
    var daysInMonth = new Date(year, month + 1, 0).getDate();

    var body = document.getElementById("calendar-body");
    body.textContent = ""; // clear

    // Header: month + year
    var header = document.createElement("div");
    header.className = "cal-header";
    header.textContent = monthNames[month] + " " + year;
    body.appendChild(header);

    // Grid container
    var grid = document.createElement("div");
    grid.className = "cal-grid";

    // Day-of-week headers
    dowNames.forEach(function (name) {
        var el = document.createElement("div");
        el.className = "cal-dow";
        el.textContent = name;
        grid.appendChild(el);
    });

    // Empty cells before first day
    for (var i = 0; i < startOffset; i++) {
        var empty = document.createElement("div");
        empty.className = "cal-day empty";
        grid.appendChild(empty);
    }

    // Day cells
    for (var d = 1; d <= daysInMonth; d++) {
        var cell = document.createElement("div");
        cell.className = "cal-day";
        cell.dataset.day = d;
        cell.textContent = d;
        if (d === today) cell.classList.add("today");
        var dayOfWeek = (startOffset + d - 1) % 7;
        if (hols[String(d)]) {
            cell.classList.add("holiday");
        } else if (works.indexOf(d) >= 0) {
            cell.classList.add("workday");
        } else if (dayOfWeek >= 5) {
            cell.classList.add("weekend");
        }
        grid.appendChild(cell);
    }

    body.appendChild(grid);
}

// Dynamic background based on daylight
var THEME_NIGHT = { primary: [13, 17, 23], secondary: [22, 27, 34], border: [48, 54, 61] };
var THEME_DAY   = { primary: [26, 35, 50], secondary: [31, 45, 61], border: [58, 72, 88] };

function parseTimeToMinutes(hhmm) {
    var parts = hhmm.split(":");
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
}

function lerpColor(a, b, t) {
    var r = Math.round(a[0] + (b[0] - a[0]) * t);
    var g = Math.round(a[1] + (b[1] - a[1]) * t);
    var bl = Math.round(a[2] + (b[2] - a[2]) * t);
    return "#" + ((1 << 24) | (r << 16) | (g << 8) | bl).toString(16).slice(1);
}

function updateTheme(astronomy) {
    if (!astronomy || !astronomy.sunrise || !astronomy.sunset) return;

    var sunrise = parseTimeToMinutes(astronomy.sunrise);
    var sunset = parseTimeToMinutes(astronomy.sunset);
    var now = new Date();
    var nowMin = now.getHours() * 60 + now.getMinutes();

    var dawnStart = sunrise - 30;
    var dawnEnd = sunrise + 30;
    var duskStart = sunset - 30;
    var duskEnd = sunset + 30;

    var t = 0; // 0 = night, 1 = day
    if (nowMin >= dawnEnd && nowMin <= duskStart) {
        t = 1; // full day
    } else if (nowMin >= dawnStart && nowMin < dawnEnd) {
        t = (nowMin - dawnStart) / 60; // dawn blend
    } else if (nowMin > duskStart && nowMin <= duskEnd) {
        t = 1 - (nowMin - duskStart) / 60; // dusk blend
    }
    // else t = 0 (night)

    var style = document.documentElement.style;
    style.setProperty("--bg-primary", lerpColor(THEME_NIGHT.primary, THEME_DAY.primary, t));
    style.setProperty("--bg-secondary", lerpColor(THEME_NIGHT.secondary, THEME_DAY.secondary, t));
    style.setProperty("--bg-border", lerpColor(THEME_NIGHT.border, THEME_DAY.border, t));
}

function updateSystem(sys) {
    var bar = document.getElementById("status-bar");
    if (!sys) { bar.textContent = ""; return; }
    var parts = [];
    if (sys.temperature !== null) parts.push("CPU " + sys.temperature + "\u00b0C " + sys.cpu_percent + "%");
    else parts.push("CPU " + sys.cpu_percent + "%");
    parts.push("\u5185\u5b58 " + sys.ram_used_gb + "/" + sys.ram_total_gb + "G");
    parts.push("\u78c1\u76d8 " + sys.disk_percent + "%");
    bar.textContent = parts.join(" | ");
}

function fetchAll() {
    fetch("/api/all")
        .then(function (r) { return r.json(); })
        .then(function (data) {
            updateDateTime(data.datetime);
            updateWeather(data.weather);
            updateHourly(data.weather);
            updateCalendar(data.calendar);
            updateAstronomy(data.weather, data.astronomy_events);
            updateSystem(data.system);
            if (data.weather && data.weather.astronomy) {
                updateTheme(data.weather.astronomy);
            }
        })
        .catch(function () { /* retry on next cycle */ });
}

// Initial fetch, then every 5 seconds
fetchAll();
setInterval(fetchAll, 5000);
