/* ═══════════════════════════════════════════
   Info-Pi · Meridian v5 — Digital Clock Edition
   1920×440 ultra-wide
   ═══════════════════════════════════════════ */

var WEATHER_ICON = {
    0:"☀",1:"☀",2:"☁",3:"☁",
    45:"☁",48:"☁",
    51:"☔",53:"☔",55:"☔",
    61:"☔",63:"☔",65:"☔",
    66:"❄",67:"❄",
    71:"❄",73:"❄",75:"❄",77:"❄",
    80:"☔",81:"☔",82:"☔",
    85:"❄",86:"❄",
    95:"⛈",96:"⛈",99:"⛈"
};
function weatherIcon(c){return WEATHER_ICON[c]||"☁";}

// Map WMO code -> icon kind (sun, partly, cloud, rain, snow, storm, fog)
function iconKind(code) {
    if (code === 0 || code === 1) return "sun";
    if (code === 2) return "partly";
    if (code === 3) return "cloud";
    if (code === 45 || code === 48) return "fog";
    if ((code >= 51 && code <= 65) || (code >= 80 && code <= 82)) return "rain";
    if ((code >= 66 && code <= 67) || (code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
    if (code >= 95) return "storm";
    return "cloud";
}

// Build a custom SVG weather icon (size in pixels)
function svgWeatherIcon(code, size) {
    var kind = iconKind(code);
    var s = '<svg viewBox="0 0 64 64" width="' + size + '" height="' + size + '" xmlns="http://www.w3.org/2000/svg">';
    s += '<defs>' +
        '<radialGradient id="sunG" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="#ffd86b"/><stop offset="100%" stop-color="#e8913a"/></radialGradient>' +
        '<linearGradient id="cloudG" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#c0cad6"/><stop offset="100%" stop-color="#7a8794"/></linearGradient>' +
        '<linearGradient id="cloudDark" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" stop-color="#5e6975"/><stop offset="100%" stop-color="#3a424d"/></linearGradient>' +
        '</defs>';

    if (kind === "sun") {
        // Rays
        for (var i = 0; i < 8; i++) {
            var ang = i * 45;
            s += '<line x1="32" y1="6" x2="32" y2="12" stroke="#e8913a" stroke-width="3" stroke-linecap="round" transform="rotate(' + ang + ' 32 32)"/>';
        }
        s += '<circle cx="32" cy="32" r="14" fill="url(#sunG)"/>';
    } else if (kind === "partly") {
        // Small sun upper-left corner with rays
        var sunCx = 18, sunCy = 18, sunR = 9;
        for (var i = 0; i < 6; i++) {
            var ang = i * 60;
            var rx = sunCx + Math.cos(ang * Math.PI / 180) * 14;
            var ry = sunCy + Math.sin(ang * Math.PI / 180) * 14;
            var rxe = sunCx + Math.cos(ang * Math.PI / 180) * 18;
            var rye = sunCy + Math.sin(ang * Math.PI / 180) * 18;
            s += '<line x1="'+rx.toFixed(1)+'" y1="'+ry.toFixed(1)+'" x2="'+rxe.toFixed(1)+'" y2="'+rye.toFixed(1)+'" stroke="#e8913a" stroke-width="2.5" stroke-linecap="round"/>';
        }
        s += '<circle cx="'+sunCx+'" cy="'+sunCy+'" r="'+sunR+'" fill="url(#sunG)"/>';
        // Big cloud lower-right with multiple bumps, clearly overlapping sun
        s += '<path d="M 22 56 ' +
                'Q 14 56 14 48 ' +
                'Q 8 48 8 40 ' +
                'Q 8 32 18 32 ' +    // left hump
                'Q 22 24 30 26 ' +   // first top bump
                'Q 36 18 44 24 ' +   // peak top bump
                'Q 52 22 56 32 ' +   // right top bump
                'Q 62 32 62 42 ' +   // right side
                'Q 62 56 50 56 ' +
                'Z" fill="url(#cloudG)" stroke="#3a424d" stroke-width="0.8"/>';
    } else if (kind === "cloud") {
        s += '<path d="M 10 42 Q 10 32 20 32 Q 22 24 32 26 Q 42 22 46 32 Q 56 32 56 44 Q 56 52 46 52 L 16 52 Q 8 52 10 42 Z" fill="url(#cloudG)"/>';
    } else if (kind === "fog") {
        s += '<path d="M 10 36 Q 10 26 20 26 Q 22 18 32 20 Q 42 16 46 26 Q 56 26 56 38 Q 56 44 46 44 L 16 44 Q 8 44 10 36 Z" fill="url(#cloudG)" opacity="0.85"/>';
        s += '<line x1="8" y1="50" x2="56" y2="50" stroke="#9aa5b1" stroke-width="2" stroke-linecap="round" opacity="0.7"/>';
        s += '<line x1="14" y1="56" x2="50" y2="56" stroke="#9aa5b1" stroke-width="2" stroke-linecap="round" opacity="0.7"/>';
    } else if (kind === "rain") {
        s += '<path d="M 10 36 Q 10 26 20 26 Q 22 18 32 20 Q 42 16 46 26 Q 56 26 56 38 Q 56 44 46 44 L 16 44 Q 8 44 10 36 Z" fill="url(#cloudG)"/>';
        // Rain drops
        s += '<line x1="20" y1="48" x2="17" y2="56" stroke="#5ba0d0" stroke-width="2.5" stroke-linecap="round"/>';
        s += '<line x1="32" y1="48" x2="29" y2="58" stroke="#5ba0d0" stroke-width="2.5" stroke-linecap="round"/>';
        s += '<line x1="44" y1="48" x2="41" y2="56" stroke="#5ba0d0" stroke-width="2.5" stroke-linecap="round"/>';
    } else if (kind === "snow") {
        s += '<path d="M 10 36 Q 10 26 20 26 Q 22 18 32 20 Q 42 16 46 26 Q 56 26 56 38 Q 56 44 46 44 L 16 44 Q 8 44 10 36 Z" fill="url(#cloudG)"/>';
        // Snowflakes
        ['20,52','32,55','44,52'].forEach(function(p) {
            var xy = p.split(','); var x = +xy[0], y = +xy[1];
            s += '<g stroke="#e6edf3" stroke-width="1.8" stroke-linecap="round">' +
                '<line x1="' + (x-3) + '" y1="' + y + '" x2="' + (x+3) + '" y2="' + y + '"/>' +
                '<line x1="' + x + '" y1="' + (y-3) + '" x2="' + x + '" y2="' + (y+3) + '"/>' +
                '<line x1="' + (x-2) + '" y1="' + (y-2) + '" x2="' + (x+2) + '" y2="' + (y+2) + '"/>' +
                '<line x1="' + (x-2) + '" y1="' + (y+2) + '" x2="' + (x+2) + '" y2="' + (y-2) + '"/>' +
                '</g>';
        });
    } else if (kind === "storm") {
        s += '<path d="M 10 36 Q 10 26 20 26 Q 22 18 32 20 Q 42 16 46 26 Q 56 26 56 38 Q 56 44 46 44 L 16 44 Q 8 44 10 36 Z" fill="url(#cloudDark)"/>';
        // Lightning bolt
        s += '<path d="M 32 44 L 26 54 L 31 54 L 28 62 L 38 50 L 33 50 L 36 44 Z" fill="#ffd86b" stroke="#e8913a" stroke-width="0.5"/>';
    }

    s += '</svg>';
    return s;
}

var MOON_EMOJI = {
    "New Moon":"●","Waxing Crescent":"◑",
    "First Quarter":"◑","Waxing Gibbous":"◑",
    "Full Moon":"○","Waning Gibbous":"◐",
    "Last Quarter":"◐","Waning Crescent":"◐"
};

// Moon phase fractions (0=new, 0.5=full, 1=new again)
var MOON_PHASE_FRAC = {
    "New Moon": 0.0,
    "Waxing Crescent": 0.125,
    "First Quarter": 0.25,
    "Waxing Gibbous": 0.375,
    "Full Moon": 0.5,
    "Waning Gibbous": 0.625,
    "Last Quarter": 0.75,
    "Waning Crescent": 0.875
};

// Build moon phase SVG shapes (circle + lit path) at given (cx, cy, r).
// Returns inner SVG content suitable to embed in a parent <svg>.
// fillDark: color of dark side, fillLit: color of lit side.
// If fillDark is null/false, skip drawing the dark disk (lit crescent only).
function moonPhaseShapes(cx, cy, r, phaseEn, illum, fillDark, fillLit) {
    var f = parseFloat(illum) / 100;
    if (isNaN(f)) f = 0.5;

    var waning = false;
    if (phaseEn) {
        waning = phaseEn.indexOf("Waning") >= 0 || phaseEn.indexOf("Last") >= 0;
    }

    var s = "";
    if (fillDark) {
        s += '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="' + fillDark + '" stroke="#4a5060" stroke-width="0.8"/>';
    }

    if (f < 0.005) {
        // New moon — only dark disk
    } else if (f > 0.995) {
        // Full moon
        s += '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="' + fillLit + '"/>';
    } else {
        // Terminator's horizontal semi-axis: |1-2f| * r
        var rx = Math.abs(1 - 2 * f) * r;

        var outerSweep, innerSweep;
        if (!waning) {
            outerSweep = 1;
            innerSweep = (f < 0.5) ? 0 : 1;
        } else {
            outerSweep = 0;
            innerSweep = (f < 0.5) ? 1 : 0;
        }

        s += '<path d="M ' + cx + ',' + (cy - r) +
             ' A ' + r + ',' + r + ' 0 0,' + outerSweep + ' ' + cx + ',' + (cy + r) +
             ' A ' + rx + ',' + r + ' 0 0,' + innerSweep + ' ' + cx + ',' + (cy - r) +
             ' Z" fill="' + fillLit + '"/>';
    }
    return s;
}

// Standalone moon phase icon for use as a small SVG element
function svgMoonPhase(phaseEn, illum, size) {
    size = size || 32;
    var s = '<svg viewBox="0 0 32 32" width="' + size + '" height="' + size + '" xmlns="http://www.w3.org/2000/svg">';
    s += moonPhaseShapes(16, 16, 14, phaseEn, illum, "#2a3142", "#f5e6c8");
    s += '</svg>';
    return s;
}

// Wind direction arrow SVG. Direction is "where wind comes FROM" in degrees.
// Arrow points toward where wind is going (180° from the FROM direction).
function svgWindArrow(dirDeg, size) {
    size = size || 14;
    var rot = (dirDeg + 180) % 360; // arrow points to where wind blows TO
    var s = '<svg viewBox="0 0 16 16" width="' + size + '" height="' + size + '" xmlns="http://www.w3.org/2000/svg" style="transform: rotate(' + rot + 'deg);">';
    // Arrow: shaft + head
    s += '<line x1="8" y1="2" x2="8" y2="13" stroke="#9aa5b1" stroke-width="1.5" stroke-linecap="round"/>';
    s += '<polygon points="8,1 5,5 11,5" fill="#9aa5b1"/>';
    s += '</svg>';
    return s;
}

var MW_CLASS = {
    "极佳":"mw-excellent","良好":"mw-good",
    "一般":"mw-fair","较差":"mw-poor"
};

var _cityWeather = [];
var _lastWeather = null;

// ── P1: Clock ─────────────────────────

function updateDateTime(dt) {
    if (!dt) return;
    var p = dt.time.split(":");
    document.getElementById("time").textContent = p[0] + ":" + p[1];
    document.getElementById("date").textContent = dt.date;
    document.getElementById("lunar-date").textContent = dt.lunar_date || "";
    document.getElementById("day").textContent = dt.day_of_week;

    var WMO_NAMES = {
        0:"晴",1:"晴",2:"多云",3:"阴",
        45:"雾",48:"雾凇",
        51:"小雨",53:"小雨",55:"中雨",
        61:"小雨",63:"中雨",65:"大雨",
        66:"冻雨",67:"冻雨",
        71:"小雪",73:"中雪",75:"大雪",77:"米雪",
        80:"阵雨",81:"阵雨",82:"暴雨",
        85:"阵雪",86:"阵雪",
        95:"雷雨",96:"雷雹",99:"雷雹"
    };

    var el = document.getElementById("world-clocks");
    el.innerHTML = "";
    (dt.world_clocks || []).forEach(function(wc, i) {
        var card = document.createElement("div");
        card.className = "wc-card";
        var off = "";
        if (wc.day_offset === -1) off = '<span class="wc-offset">-1</span>';
        else if (wc.day_offset === 1) off = '<span class="wc-offset">+1</span>';
        var iconSvg = "";
        var tempStr = "";
        var descStr = "";
        if (_cityWeather[i]) {
            var c = _cityWeather[i];
            iconSvg = svgWeatherIcon(c.weather_code, 32);
            tempStr = c.temp_c + "°";
            descStr = WMO_NAMES[c.weather_code] || "";
        }
        card.innerHTML =
            '<div class="wc-top">' +
                '<div class="wc-icon">' + iconSvg + '</div>' +
                '<div class="wc-temp">' + tempStr + '</div>' +
            '</div>' +
            '<div class="wc-time">' + wc.time + off + '</div>' +
            '<div class="wc-city">' + wc.city + '</div>' +
            '<div class="wc-desc">' + descStr + '</div>';
        el.appendChild(card);
    });
}

// ── P2: Weather ───────────────────────

function updateWeather(w) {
    if (!w) { document.getElementById("w-desc").textContent = "暂无数据"; return; }
    _cityWeather = w.city_weather || [];
    _lastWeather = w;

    document.getElementById("w-icon").innerHTML = svgWeatherIcon(w.weather_code, 56);
    document.getElementById("w-temp").textContent = w.temp_c + "°";

    // Description + today's min/max (from forecast[0])
    var descEl = document.getElementById("w-desc");
    var today = w.forecast && w.forecast.length ? w.forecast[0] : null;
    var todayRange = "";
    if (today) {
        todayRange = ' <span class="wx-range">↑' + today.max_c + '° ↓' + today.min_c + '°</span>';
    }
    descEl.innerHTML = w.description + todayRange;

    // Metrics — 4 compact pills in 2x2 grid
    var m = document.getElementById("w-metrics");
    var pills = [
        {l:"湿度", v:w.humidity+"%"},
        {l:"体感", v:w.feels_like_c+"°"},
        {l:"风", v:w.wind_speed_kmh+"km/h "+w.wind_dir}
    ];
    var aq = w.air_quality;
    if (aq && aq.aqi) {
        var ac = "";
        if (aq.aqi>200) ac="aqi-bad";
        else if (aq.aqi>100) ac="aqi-unhealthy";
        else if (aq.aqi>50) ac="aqi-moderate";
        else ac="aqi-good";
        pills.push({l:"空气 "+aq.level, v:"AQI "+aq.aqi, c:ac});
    }
    m.innerHTML = "";
    pills.forEach(function(p) {
        var e = document.createElement("span");
        e.className = "m-pill" + (p.c ? " "+p.c : "");
        e.innerHTML = '<span>'+p.l+'</span> <span class="mv">'+p.v+'</span>';
        m.appendChild(e);
    });

    // Minute-level rain nowcast (QWeather only) — "X分钟后开始下雨" + sparkline
    var rainEl = document.getElementById("w-rain");
    var rs = w.rain_summary || "";
    if (rs) {
        var mm = w.rain_minutely || [];
        var wet = /[雨雪]/.test(rs) && !/无[雨雪降]/.test(rs);
        var maxp = mm.reduce(function(a, x){ return Math.max(a, x.precip); }, 0.08);
        var bars = mm.map(function(x){
            var h = Math.max(6, Math.round(x.precip / maxp * 100));
            return '<i style="height:' + h + '%"></i>';
        }).join("");
        rainEl.className = "wx-rain" + (wet ? " rain-on" : "");
        rainEl.innerHTML = '<span class="rain-ico">☔</span>' +
                           '<span class="rain-txt">' + rs + '</span>' +
                           (mm.length ? '<span class="rain-bars">' + bars + '</span>' : '');
        rainEl.style.display = "";
    } else {
        rainEl.style.display = "none";
    }

    // Forecast — horizontal cards: icon left, info right
    var fc = document.getElementById("w-forecast");
    fc.innerHTML = "";
    (w.forecast || []).forEach(function(day) {
        var e = document.createElement("div");
        e.className = "fc-card";
        var windHtml = "";
        if (day.wind_speed_kmh !== undefined) {
            var arrowSvg = (day.wind_dir_deg !== undefined) ? svgWindArrow(day.wind_dir_deg, 12) : "";
            // arrow already shows direction, so only the speed text (keeps it
            // on one line inside the narrow card)
            windHtml = '<div class="fc-wind">' +
                '<span class="fc-wind-arrow">' + arrowSvg + '</span>' +
                '<span>' + day.wind_speed_kmh + ' km/h</span></div>';
        }
        e.innerHTML = '<div class="fc-i">'+svgWeatherIcon(day.weather_code, 44)+'</div>' +
            '<div class="fc-info">' +
                '<div class="fc-d">'+day.date.slice(5)+' · '+day.desc+'</div>' +
                '<div class="fc-t">'+day.max_c+'° / '+day.min_c+'°</div>' +
                windHtml +
            '</div>';
        fc.appendChild(e);
    });
}

// ── SVG Temperature Curve ─────────────

var _hourlyKey = "";

function updateHourly(w) {
    var box = document.getElementById("w-hourly");
    if (!w || !w.hourly || !w.hourly.length) { box.innerHTML = ""; _hourlyKey = ""; return; }

    var k = w.hourly[0].hour + "-" + w.hourly[w.hourly.length-1].hour;
    if (k === _hourlyKey) return;
    _hourlyKey = k;

    var hrs = w.hourly;
    var ts = hrs.map(function(h){return h.temp_c;});
    var lo = Math.min.apply(null,ts), hi = Math.max.apply(null,ts);
    var rng = hi - lo || 1;

    var W = 460, H = 130;
    var padL = 12, padR = 12, padT = 22, padB = 36;
    var cw = W - padL - padR, ch = H - padT - padB;

    var pts = hrs.map(function(h, i) {
        var x = padL + (i / (hrs.length - 1)) * cw;
        var t = (h.temp_c - lo) / rng;
        var y = padT + ch - t * ch;
        return {x: x, y: y, temp: h.temp_c, hour: h.hour, code: h.weather_code, idx: i};
    });

    var linePath = pts.map(function(p,i){return (i===0?"M":"L")+p.x.toFixed(1)+","+p.y.toFixed(1);}).join(" ");
    var areaPath = linePath + " L"+pts[pts.length-1].x.toFixed(1)+","+(padT+ch)+" L"+pts[0].x.toFixed(1)+","+(padT+ch)+" Z";

    var s = '<svg viewBox="0 0 '+W+' '+H+'" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">';
    s += '<defs><linearGradient id="tempGrad" x1="0" y1="0" x2="0" y2="1">';
    s += '<stop offset="0%" stop-color="#e8913a" stop-opacity="0.45"/>';
    s += '<stop offset="100%" stop-color="#5ba0d0" stop-opacity="0.05"/>';
    s += '</linearGradient></defs>';
    s += '<path class="chart-area" d="'+areaPath+'"/>';
    s += '<path class="chart-line" d="'+linePath+'"/>';

    pts.forEach(function(p) {
        var dotClass = p.idx === 0 ? "chart-dot-now" : "chart-dot";
        s += '<circle class="'+dotClass+'" cx="'+p.x.toFixed(1)+'" cy="'+p.y.toFixed(1)+'" r="'+(p.idx===0?4:2.5)+'"/>';
        var tLabel = rng > 3 ? Math.round(p.temp)+"°" : p.temp.toFixed(1)+"°";
        s += '<text class="chart-temp-label" x="'+p.x.toFixed(1)+'" y="'+(p.y-10)+'">'+tLabel+'</text>';
        s += '<text class="chart-icon" x="'+p.x.toFixed(1)+'" y="'+(padT+ch+14)+'">'+weatherIcon(p.code)+'</text>';
        var hLabel = p.idx === 0 ? "现在" : p.hour;
        var hClass = p.idx === 0 ? "chart-now-label" : "chart-hour-label";
        s += '<text class="'+hClass+'" x="'+p.x.toFixed(1)+'" y="'+(padT+ch+28)+'">'+hLabel+'</text>';
    });
    s += '</svg>';
    box.innerHTML = s;
}

// ── P3: Calendar + Holidays ───────────

var _calMonth = -1;
var _calHolidays = {};

function updateCalendar(calData) {
    var now = new Date(), yr = now.getFullYear(), mo = now.getMonth(), td = now.getDate();
    var hols = (calData && calData.holidays) || {};
    var wrks = (calData && calData.workdays) || [];
    _calHolidays = hols;

    if (_calMonth === mo) {
        document.querySelectorAll("#calendar-body .cal-day").forEach(function(el) {
            if (el.dataset.day) el.classList.toggle("today", +el.dataset.day === td);
        });
        updateHolidayList(yr, mo, hols, wrks, calData && calData.next_holiday);
        return;
    }
    _calMonth = mo;

    var mN = ["1月","2月","3月","4月","5月","6月",
              "7月","8月","9月","10月","11月","12月"];
    var dN = ["一","二","三","四","五","六","日"];

    var off = (new Date(yr,mo,1).getDay()+6)%7;
    var dim = new Date(yr,mo+1,0).getDate();

    var body = document.getElementById("calendar-body");
    body.textContent = "";

    var hd = document.createElement("div"); hd.className = "cal-header";
    hd.textContent = mN[mo] + " " + yr;
    body.appendChild(hd);

    var grid = document.createElement("div"); grid.className = "cal-grid";

    dN.forEach(function(n) {
        var e = document.createElement("div"); e.className = "cal-dow"; e.textContent = n;
        grid.appendChild(e);
    });

    for (var i = 0; i < off; i++) {
        var emp = document.createElement("div"); emp.className = "cal-day empty";
        grid.appendChild(emp);
    }

    for (var d = 1; d <= dim; d++) {
        var c = document.createElement("div"); c.className = "cal-day";
        c.dataset.day = d; c.textContent = d;
        if (d === td) c.classList.add("today");
        var dow = (off + d - 1) % 7;
        if (hols[String(d)]) c.classList.add("holiday");
        else if (wrks.indexOf(d) >= 0) c.classList.add("workday");
        else if (dow >= 5) c.classList.add("weekend");
        grid.appendChild(c);
    }
    body.appendChild(grid);
    updateHolidayList(yr, mo, hols, wrks);
}

function updateHolidayList(yr, mo, hols, wrks, nextHoliday) {
    var el = document.getElementById("cal-holidays");
    el.innerHTML = "";
    var nowD = new Date();
    var todayD = nowD.getDate();
    var todayDate = new Date(yr, mo, todayD);
    todayDate.setHours(0,0,0,0);

    var items = [];
    Object.keys(hols).forEach(function(dayStr) {
        var d = parseInt(dayStr, 10);
        if (d >= todayD) {
            var mm = String(mo+1).padStart(2,'0');
            var dd = dayStr.padStart(2,'0');
            var diff = Math.round((new Date(yr, mo, d) - todayDate) / 86400000);
            items.push({date: mm+"/"+dd, name: hols[dayStr], type: "rest", days: diff});
        }
    });
    wrks.forEach(function(d) {
        if (d >= todayD) {
            var mm = String(mo+1).padStart(2,'0');
            var dd = String(d).padStart(2,'0');
            var diff = Math.round((new Date(yr, mo, d) - todayDate) / 86400000);
            items.push({date: mm+"/"+dd, name: "调休工作日", type: "work", days: diff});
        }
    });

    items.sort(function(a,b){return a.days - b.days;});

    var titleDiv = document.createElement("div");
    titleDiv.className = "hol-title";
    titleDiv.textContent = items.length ? "本月假期 · 倒数日" : "下一个法定节假日";
    el.appendChild(titleDiv);

    if (items.length) {
        items.slice(0, 3).forEach(function(item) {
            var div = document.createElement("div"); div.className = "hol-item";
            var cls = item.type === "rest" ? "hol-rest" : "hol-work";
            var cd = item.days === 0 ? "今天" : item.days + "天后";
            div.innerHTML = '<span class="hol-date">'+item.date+'</span>' +
                '<span class="hol-name '+cls+'">'+item.name+'</span>' +
                '<span class="hol-cd">'+cd+'</span>';
            el.appendChild(div);
        });
    } else if (nextHoliday) {
        var div = document.createElement("div"); div.className = "hol-item";
        var cd = nextHoliday.days_away === 0 ? "今天" : nextHoliday.days_away + "天后";
        div.innerHTML = '<span class="hol-date">'+nextHoliday.month_day+'</span>' +
            '<span class="hol-name hol-rest">'+nextHoliday.name+'</span>' +
            '<span class="hol-cd">'+cd+'</span>';
        el.appendChild(div);
    }
}

// ── P4: Observatory ───────────────────

function parseTimeToMinutes(hhmm) {
    var p = hhmm.split(":"); return +p[0]*60 + +p[1];
}

// ── Solar and lunar position (SunCalc-style algorithm) ────
// Returns azimuth (0-360° from north) and altitude (-90 to +90°)
var _R = Math.PI / 180;
var _OBLIQUITY = 23.4397 * _R;

function _toDays(date) {
    return date.valueOf() / 86400000 - 0.5 + 2440588 - 2451545;
}
function _rightAscension(l, b) {
    return Math.atan2(Math.sin(l)*Math.cos(_OBLIQUITY) - Math.tan(b)*Math.sin(_OBLIQUITY), Math.cos(l));
}
function _declination(l, b) {
    return Math.asin(Math.sin(b)*Math.cos(_OBLIQUITY) + Math.cos(b)*Math.sin(_OBLIQUITY)*Math.sin(l));
}
function _siderealTime(d, lw) {
    return _R * (280.16 + 360.9856235 * d) - lw;
}
function _altitude(H, phi, dec) {
    return Math.asin(Math.sin(phi)*Math.sin(dec) + Math.cos(phi)*Math.cos(dec)*Math.cos(H));
}
function _azimuthCalc(H, phi, dec) {
    return Math.atan2(Math.sin(H), Math.cos(H)*Math.sin(phi) - Math.tan(dec)*Math.cos(phi));
}

function sunPosition(date, lat, lon) {
    var lw = _R * -lon, phi = _R * lat;
    var d = _toDays(date);
    var M = _R * (357.5291 + 0.98560028 * d);
    var C = _R * (1.9148*Math.sin(M) + 0.02*Math.sin(2*M) + 0.0003*Math.sin(3*M));
    var L = M + C + _R * 102.9372 + Math.PI;
    var dec = _declination(L, 0);
    var ra = _rightAscension(L, 0);
    var H = _siderealTime(d, lw) - ra;
    var az = (_azimuthCalc(H, phi, dec) / _R + 180 + 360) % 360;
    var alt = _altitude(H, phi, dec) / _R;
    return { azimuth: az, altitude: alt };
}

function moonPosition(date, lat, lon) {
    var lw = _R * -lon, phi = _R * lat;
    var d = _toDays(date);
    var L = _R * (218.316 + 13.176396 * d);
    var M = _R * (134.963 + 13.064993 * d);
    var F = _R * (93.272  + 13.229350 * d);
    var l = L + _R * 6.289 * Math.sin(M);
    var b = _R * 5.128 * Math.sin(F);
    var dec = _declination(l, b);
    var ra = _rightAscension(l, b);
    var H = _siderealTime(d, lw) - ra;
    var az = (_azimuthCalc(H, phi, dec) / _R + 180 + 360) % 360;
    var alt = _altitude(H, phi, dec) / _R;
    return { azimuth: az, altitude: alt };
}

// Map azimuth degrees to 8-direction Chinese cardinal
function azimuthCardinal(deg) {
    var dirs = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"];
    var idx = Math.round(deg / 45) % 8;
    return dirs[idx];
}

// Compute body position on a celestial arc
function arcPosition(rise, set, current) {
    if (rise === null || set === null) return null;
    var dur, el;
    if (set > rise) {
        // Rise/set in same day
        dur = set - rise;
        el = current - rise;
    } else {
        // Crosses midnight
        dur = (1440 - rise) + set;
        if (current >= rise) el = current - rise;
        else if (current <= set) el = (1440 - rise) + current;
        else el = -1; // body is below horizon
    }
    var t = el / dur;
    var above = t >= 0 && t <= 1;
    return { t: Math.max(0, Math.min(1, t)), above: above, raw_t: t };
}

function updateSkyArc(astro) {
    var box = document.getElementById("sky-arc");
    if (!astro || !astro.sunrise || !astro.sunset) { box.innerHTML = ""; return; }

    // 24-hour timeline: x maps minutes-of-day [0..1440] to [pad..W-pad]
    var W = 520, H = 170;
    var pad = 24;
    var hY = H - 42;       // horizon y
    var arcH = hY - 16;    // max arc peak
    var x1 = pad, x2 = W - pad;
    var span = x2 - x1;

    // Convert minutes-of-day (0-1439) to x pixel
    function timeToX(min) {
        return x1 + (min / 1440) * span;
    }

    var now = new Date();
    var nowMin = now.getHours()*60 + now.getMinutes();
    var sr = parseTimeToMinutes(astro.sunrise);
    var ss = parseTimeToMinutes(astro.sunset);
    var mr = astro.moonrise ? parseTimeToMinutes(astro.moonrise) : null;
    var ms = astro.moonset ? parseTimeToMinutes(astro.moonset) : null;

    // Build an arc path on the 24h timeline from rise to set
    // Returns SVG path string + position of body on arc at currentMin
    function buildArc(rise, set, current, peakHeight, cssClass, overflowOffset) {
        if (rise === null || set === null) return { path: "", body: null };

        // Build the arc as ONE continuous quadratic curve representing the
        // body's full path from rise to set, even when crossing midnight.
        // For midnight-crossing cases, we render the arc extended beyond
        // the visible timeline (to the right past the panel, and to the
        // left before the panel). SVG clip-path then crops to the visible
        // [0, 1440] area so we only see the correct portion of the arc.
        var pathStr = "";
        var dx = x2 - x1;  // pixel width of full 24h timeline

        if (set > rise) {
            // Single arc, same day
            var sx = timeToX(rise);
            var ex = timeToX(set);
            var midX = (sx + ex) / 2;
            var peakY = hY - peakHeight;
            pathStr = 'M ' + sx + ',' + hY +
                      ' Q ' + midX + ',' + peakY +
                      ' ' + ex + ',' + hY + ' Z ';
        } else {
            // Crosses midnight: draw TWO instances of the same full arc,
            // one extending past the right edge and one before the left.
            // Clip-path will limit them to the visible panel area.
            //
            // Instance A: rise (today) → set + 1440 (effectively past right)
            var sxA = timeToX(rise);
            var exA = timeToX(set) + dx;
            var midXA = (sxA + exA) / 2;
            // Instance B: rise - 1440 (effectively before left) → set (today)
            var sxB = timeToX(rise) - dx;
            var exB = timeToX(set);
            var midXB = (sxB + exB) / 2;
            var peakY = hY - peakHeight;
            pathStr = 'M ' + sxA + ',' + hY +
                      ' Q ' + midXA + ',' + peakY +
                      ' ' + exA + ',' + hY + ' Z ' +
                      'M ' + sxB + ',' + hY +
                      ' Q ' + midXB + ',' + peakY +
                      ' ' + exB + ',' + hY + ' Z ';
        }

        // Compute body position based on current time
        var body = null;
        var totalDur = 0; var elapsed = -1;
        if (set > rise) {
            totalDur = set - rise;
            if (current >= rise && current <= set) elapsed = current - rise;
        } else {
            totalDur = (1440 - rise) + set;
            if (current >= rise) elapsed = current - rise;
            else if (current <= set) elapsed = (1440 - rise) + current;
        }

        if (elapsed >= 0) {
            // Body is above horizon
            var t = elapsed / totalDur;
            var bx = timeToX(current); // x on 24h timeline
            // y on the arc curve: sin(t*π) gives 0..1..0
            var by = hY - Math.sin(t * Math.PI) * peakHeight;
            body = { x: bx, y: by, above: true };
        } else {
            body = { x: timeToX(current), y: hY + (overflowOffset || 18), above: false };
        }
        return { path: pathStr, body: body };
    }

    var sun = buildArc(sr, ss, nowMin, arcH, "arc-path", 18);
    var moon = (mr !== null && ms !== null) ? buildArc(mr, ms, nowMin, arcH * 0.65, "moon-arc", 16) : { path: "", body: null };

    var s = '<svg viewBox="0 0 '+W+' '+H+'" xmlns="http://www.w3.org/2000/svg">';

    // Gradient defs and moon glow filter
    s += '<defs>' +
        '<linearGradient id="sunArcGrad" x1="0" y1="0" x2="0" y2="1">' +
            '<stop offset="0%" stop-color="#e8913a" stop-opacity="0.45"/>' +
            '<stop offset="100%" stop-color="#e8913a" stop-opacity="0.05"/>' +
        '</linearGradient>' +
        '<linearGradient id="moonArcGrad" x1="0" y1="0" x2="0" y2="1">' +
            '<stop offset="0%" stop-color="#c8d3e0" stop-opacity="0.32"/>' +
            '<stop offset="100%" stop-color="#c8d3e0" stop-opacity="0.05"/>' +
        '</linearGradient>' +
        '<filter id="moonGlow" x="-50%" y="-50%" width="200%" height="200%">' +
            '<feGaussianBlur stdDeviation="1.5" result="blur"/>' +
            '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>' +
        '</filter>' +
        // Clip path: limit arc rendering to the visible timeline area only
        '<clipPath id="skyClip">' +
            '<rect x="' + (x1 - 4) + '" y="0" width="' + (x2 - x1 + 8) + '" height="' + hY + '"/>' +
        '</clipPath>' +
        '</defs>';

    // Hour grid markers (every 6 hours: 00, 06, 12, 18, 24)
    [0, 6, 12, 18, 24].forEach(function(h) {
        var hX = timeToX(h * 60);
        s += '<line class="sky-tick" x1="'+hX+'" y1="'+(hY-5)+'" x2="'+hX+'" y2="'+(hY+5)+'" />';
        s += '<text class="sky-hour" x="'+hX+'" y="'+(hY+22)+'" text-anchor="middle">'+(h<10?'0'+h:h)+':00</text>';
    });

    // Arc paths wrapped in clip group so wrap-around portions outside
    // the visible timeline don't draw fake midnight peaks.
    s += '<g clip-path="url(#skyClip)">';

    // Moon arc (drawn first so sun is on top)
    if (moon.path) {
        s += '<path class="moon-arc" d="'+moon.path+'"/>';
    }

    // Sun arc
    s += '<path class="arc-path" d="'+sun.path+'"/>';

    s += '</g>';  // end clip group

    // Horizon line
    s += '<line class="horizon-line" x1="'+(pad-8)+'" y1="'+hY+'" x2="'+(W-pad+8)+'" y2="'+hY+'"/>';

    // Now marker
    var nowX = timeToX(nowMin);
    s += '<line class="sky-now-marker" x1="'+nowX+'" y1="18" x2="'+nowX+'" y2="'+hY+'"/>';
    s += '<text class="sky-now-text" x="'+nowX+'" y="13" text-anchor="middle">现在</text>';

    // Sun body — only render when above horizon (after set, position is meaningless)
    if (sun.body && sun.body.above) {
        s += '<text class="sky-body-sun" x="'+sun.body.x+'" y="'+sun.body.y+'">☀</text>';
    }

    // Moon body — render accurate phase SVG when above horizon
    if (moon.body && moon.body.above) {
        // Lit crescent only (no dark disk so arc remains visible behind moon).
        // Faint outline ring shows the full moon disk subtly.
        s += '<g class="sky-body-moon-svg" filter="url(#moonGlow)">' +
             '<circle cx="' + moon.body.x + '" cy="' + moon.body.y + '" r="13" fill="none" stroke="#c8d3e0" stroke-width="0.6" opacity="0.35"/>' +
             moonPhaseShapes(moon.body.x, moon.body.y, 13, astro.moon_phase_en, astro.moon_illumination,
                             null, "#e6edf3") +
             '</g>';
    }

    // Vertical dashed lines from each rise/set event down to the time axis
    var srX = timeToX(sr);
    var ssX = timeToX(ss);
    s += '<line class="sky-event-line sun" x1="'+srX+'" y1="'+(hY-arcH+18)+'" x2="'+srX+'" y2="'+hY+'"/>';
    s += '<line class="sky-event-line sun" x1="'+ssX+'" y1="'+(hY-arcH+18)+'" x2="'+ssX+'" y2="'+hY+'"/>';
    if (mr !== null) {
        var mrX = timeToX(mr);
        s += '<line class="sky-event-line moon" x1="'+mrX+'" y1="'+(hY-arcH+36)+'" x2="'+mrX+'" y2="'+hY+'"/>';
    }
    if (ms !== null) {
        var msX = timeToX(ms);
        s += '<line class="sky-event-line moon" x1="'+msX+'" y1="'+(hY-arcH+36)+'" x2="'+msX+'" y2="'+hY+'"/>';
    }

    // Sun rise/set tick labels (above hour labels)
    s += '<text class="sky-rise-set" x="'+timeToX(sr)+'" y="'+(hY-arcH+16)+'" text-anchor="middle">☀'+astro.sunrise+'</text>';
    s += '<text class="sky-rise-set" x="'+timeToX(ss)+'" y="'+(hY-arcH+16)+'" text-anchor="middle">'+astro.sunset+'☀</text>';
    if (mr !== null) {
        s += '<text class="sky-moon-tick" x="'+timeToX(mr)+'" y="'+(hY-arcH+34)+'" text-anchor="middle">☽'+astro.moonrise+'</text>';
    }
    if (ms !== null) {
        s += '<text class="sky-moon-tick" x="'+timeToX(ms)+'" y="'+(hY-arcH+34)+'" text-anchor="middle">'+astro.moonset+'☽</text>';
    }

    s += '</svg>';
    box.innerHTML = s;
}

function updateAstronomy(weather, events) {
    var el = document.getElementById("obs-info");
    var a = (weather && weather.astronomy) ? weather.astronomy : null;

    if (!a) {
        el.innerHTML = '<div class="obs-row" style="color:var(--c-dim)">暂无数据</div>';
        return;
    }

    updateSkyArc(a);

    var w = _lastWeather || {};
    var mwCls = MW_CLASS[a.milky_way_rating] || "mw-fair";

    var html = "";

    // Moon phase row + sun & moon azimuth
    var azHtml = "";
    if (a.latitude !== undefined && a.longitude !== undefined) {
        var nowDate = new Date();
        var sp = sunPosition(nowDate, a.latitude, a.longitude);
        var mp = moonPosition(nowDate, a.latitude, a.longitude);
        var sunAz = Math.round(sp.azimuth);
        var moonAz = Math.round(mp.azimuth);
        azHtml = '<span class="obs-az obs-az-moon" title="月方位"><span class="obs-az-icon">☽</span>' + azimuthCardinal(moonAz) + ' ' + moonAz + '°</span>' +
                 '<span class="obs-az obs-az-sun" title="日方位"><span class="obs-az-icon">☀</span>' + azimuthCardinal(sunAz) + ' ' + sunAz + '°</span>';
    }

    html += '<div class="obs-row obs-moon">' +
        '<span class="obs-icon obs-moon-icon">' + svgMoonPhase(a.moon_phase_en, a.moon_illumination, 24) + '</span>' +
        '<span class="obs-label">月相</span>' +
        '<span class="obs-val">' + a.moon_phase + ' ' + a.moon_illumination + '%</span>' +
        azHtml +
        '</div>';

    // Sun rise+set on one row, Moon rise+set on one row
    html += '<div class="obs-row obs-rs">' +
        '<span class="obs-icon obs-rs-sun">☀</span>' +
        '<span class="obs-label">日出</span>' +
        '<span class="obs-val">' + a.sunrise + '</span>' +
        '<span class="obs-label" style="margin-left:14px">日落</span>' +
        '<span class="obs-val">' + a.sunset + '</span>' +
        '</div>';
    html += '<div class="obs-row obs-rs">' +
        '<span class="obs-icon obs-rs-moon">☽</span>' +
        '<span class="obs-label">月出</span>' +
        '<span class="obs-val">' + a.moonrise + '</span>' +
        '<span class="obs-label" style="margin-left:14px">月落</span>' +
        '<span class="obs-val">' + a.moonset + '</span>' +
        '</div>';

    // Wind with directional arrow icon
    if (w.wind_speed_kmh) {
        var dirSvg = (w.wind_dir_deg !== undefined) ? svgWindArrow(w.wind_dir_deg, 18) : "☴";
        html += '<div class="obs-row">' +
            '<span class="obs-icon">' + dirSvg + '</span>' +
            '<span class="obs-label">风</span>' +
            '<span class="obs-val">' + (w.wind_dir||'') + ' ' + w.wind_speed_kmh + 'km/h</span>' +
            '</div>';
    }

    // Milky Way
    html += '<div class="obs-row obs-mw">' +
        '<span class="obs-icon">✦</span>' +
        '<span class="obs-label">银河</span>' +
        '<span class="obs-val"><span class="mw-rating ' + mwCls + '">' +
        a.milky_way_rating + '</span> · ' + a.milky_way_note + '</span>' +
        '</div>';

    // Upcoming astronomy events (up to 3), each with its calendar date
    (events || []).slice(0,3).forEach(function(ev) {
        var cd = ev.days_away===0 ? "今天" : ev.days_away + "天";
        var ic = ev.type==="eclipse" ? "●" : "★";
        html += '<div class="obs-row obs-event">' +
            '<span class="obs-icon">' + ic + '</span>' +
            '<span class="obs-val">' + ev.name + '</span>' +
            '<span class="obs-date">' + ev.date + '</span>' +
            '<span class="obs-cd">' + cd + '</span>' +
            '</div>';
    });

    el.innerHTML = html;
}

// ── Theme ─────────────────────────────

var TN={primary:[10,14,20],card:[19,24,32],pill:[31,39,51]};
var TD={primary:[20,28,42],card:[31,42,60],pill:[44,57,80]};

function lerpColor(a,b,t) {
    var r=Math.round(a[0]+(b[0]-a[0])*t);
    var g=Math.round(a[1]+(b[1]-a[1])*t);
    var bl=Math.round(a[2]+(b[2]-a[2])*t);
    return "#"+((1<<24)|(r<<16)|(g<<8)|bl).toString(16).slice(1);
}

function updateTheme(ast) {
    if (!ast||!ast.sunrise||!ast.sunset) return;
    var sr=parseTimeToMinutes(ast.sunrise),ss=parseTimeToMinutes(ast.sunset);
    var n=new Date(),nm=n.getHours()*60+n.getMinutes();
    var ds=sr-30,de=sr+30,us=ss-30,ue=ss+30;
    var t=0;
    if (nm>=de&&nm<=us) t=1;
    else if (nm>=ds&&nm<de) t=(nm-ds)/60;
    else if (nm>us&&nm<=ue) t=1-(nm-us)/60;
    var s=document.documentElement.style;
    s.setProperty("--bg-primary",lerpColor(TN.primary,TD.primary,t));
    s.setProperty("--bg-card",lerpColor(TN.card,TD.card,t));
    s.setProperty("--bg-pill",lerpColor(TN.pill,TD.pill,t));
}

// ── System ────────────────────────────

function updateSystem(sys) {
    var b=document.getElementById("status-bar");
    if (!sys){b.textContent="";return;}
    var p=[];
    if (sys.temperature!==null) p.push("CPU "+sys.temperature+"°C "+sys.cpu_percent+"%");
    else p.push("CPU "+sys.cpu_percent+"%");
    p.push("内存 "+sys.ram_used_gb+"/"+sys.ram_total_gb+"G");
    p.push("磁盘 "+sys.disk_percent+"%");
    b.textContent=p.join(" · ");
}

// ── Fetch ─────────────────────────────

function fetchAll() {
    fetch("/api/all").then(function(r){return r.json();}).then(function(d) {
        updateDateTime(d.datetime);
        updateWeather(d.weather);
        updateHourly(d.weather);
        updateCalendar(d.calendar);
        updateAstronomy(d.weather,d.astronomy_events);
        updateSystem(d.system);
        if (d.weather&&d.weather.astronomy) updateTheme(d.weather.astronomy);
    }).catch(function(){});
}
fetchAll();
setInterval(fetchAll,5000);
