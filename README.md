# Info-Pi · 超宽屏版 (1920×440)

[English](#english) | 中文

> 这是 Info-Pi 的**超宽屏版本**，专为客厅壁挂或餐桌使用的 1920×440 条形显示器设计，搭配 Orange Pi Zero 2W 主控。
> 标准 800×480 树莓派版本请见 [`main` 分支](https://github.com/lxidea/info-pi/tree/main)。

![看板截图](https://raw.githubusercontent.com/lxidea/info-pi/ultrawide-1920x440/screenshot.png)

## 特色亮点

- **数字 LCD 时钟** — DSEG7 七段显示风格字体，远距离一眼可见
- **气象站仪表盘风格** — 卡片化布局，时钟 / 天气 / 日历 / 天文台 四区并列
- **24 小时天球弧线** — 真实时间轴上同时展示太阳与月亮的运行轨迹
- **精确月相** — SVG 渲染，根据实际亮度百分比绘制弯月/凸月形状
- **自定义天气图标** — SVG 多层次图标（晴/晴间多云/阴/雨/雪/雷暴/雾），不依赖 emoji 字体
- **温度曲线图** — 渐变填充的折线图替代柱状图，气象图风格
- **风向箭头** — 实时按罗盘方位旋转
- **节假日倒数日** — 自动查找下一个法定节假日并显示距离天数
- **现代字体栈** — Inter + JetBrains Mono + Noto Sans CJK
- **昼夜主题** — 背景色根据日出日落自动渐变

## 功能

- **实时天气** — 温度、湿度、风速风向、体感温度、空气质量 (AQI + PM2.5)
- **三天预报** — 自定义 SVG 图标 + 高/低温 + 风力风向
- **12 小时温度曲线** — SVG 折线 + 渐变填充 + 天气图标
- **月历** — 圆角日期单元格、今日强高亮、周末红色背景、节假日红色/调休金色
- **农历日期** — 自动转换显示
- **天球弧线** — 24h 时间轴 + 太阳橙色弧 + 月亮银色弧 + 实时位置标记
- **天文事件** — 流星雨、日月食倒计时
- **世界时钟** — 三城市卡片，含天气图标 + 温度 + 城市描述
- **系统状态** — CPU 温度、CPU/内存/磁盘使用率（底部紧凑行）

## 硬件方案

- **主控**：Orange Pi Zero 2W（Allwinner H618 四核 A53 + 2GB RAM）
- **显示**：1920×440 超宽条形屏（HDMI 接入，xrandr 旋转 90°）
- **系统**：Debian 12 Bookworm（Linux 6.1 内核，桌面版）

> 也可在标准 16:9 显示器上运行，但布局针对 1920×440 比例优化。

## 快速开始

```bash
# 克隆超宽屏分支
git clone -b ultrawide-1920x440 https://github.com/lxidea/info-pi.git
cd info-pi
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# 本地运行
python3 app.py
# 浏览器打开 http://localhost:5000
```

## 部署到 Orange Pi

```bash
# 安装依赖（Pi 端）
sudo apt install -y python3-pip python3-venv chromium scrot unclutter xdotool fonts-noto-cjk

# 部署看板（修改 deploy.sh 里的 SSH 目标）
bash deploy/deploy.sh orangepi@<橙派IP>
```

将安装两个 systemd 服务：
- `info-pi.service` — Flask 服务（端口 5000）
- `kiosk.service` — Chromium 全屏 kiosk 模式 + xrandr 屏幕旋转

### 系统准备

- Orange Pi Zero 2W 或同级 ARM 单板机（亦支持树莓派）
- Debian 12 / Ubuntu 22.04 桌面版
- 中文字体：`fonts-noto-cjk`（高质量 CJK 渲染）
- Python 3.7+
- 网络连接（用于 Open-Meteo 天气 API）

### 显示器旋转

`deploy/kiosk.sh` 默认假设条形屏需要旋转 90°：

```bash
xrandr --output HDMI-1 --mode 440x1920 --rotate right
```

如果你的屏幕原生是横向 1920×440，可移除这行。

## 配置

编辑 `config.py` 自定义位置和世界时钟：

```python
# 经纬度（Open-Meteo 天气接口使用）
WEATHER_LAT = 30.59    # 默认：中国武汉
WEATHER_LON = 114.30

# 刷新间隔（秒）
WEATHER_INTERVAL = 900  # 15 分钟

# 世界时钟：(显示名称, UTC偏移小时数, 夏令时类型)
# 夏令时类型: "us" = 美国规则, "eu" = 欧盟规则, None = 无夏令时
WORLD_CLOCKS = [
    ("伯克利", -8, "us"),
    ("纽约", -5, "us"),
    ("巴黎", 1, "eu"),
]
```

法定节假日数据在 `collectors/holidays.py`，每年 11 月国务院公布次年安排后更新一次。

## 架构

```
info-pi/
  app.py                Flask 应用 — / 和 /api/all
  config.py             位置、间隔、世界时钟、Flask 设置
  collectors/
    weather.py          Open-Meteo 天气 + 风力风向 + 日出日落 + 月相
    datetime_info.py    日期、时间、农历、世界时钟
    astronomy_events.py 流星雨/日月食（2024-2030）
    holidays.py         中国法定节假日 + 调休 + 倒数日查找
    system_stats.py     CPU/内存/磁盘（psutil）
  templates/
    index.html          四区单页看板（视口 1920×440）
  static/
    css/dashboard.css   卡片化 + 圆角 + 昼夜变量
    js/dashboard.js     5s 轮询 + SVG 月相/天气/天球弧线
    fonts/              DSEG7、Inter、JetBrains Mono 字体文件
  deploy/
    deploy.sh           rsync + systemd 安装脚本
    info-pi.service     Flask 服务
    kiosk.service       Chromium kiosk 服务
    kiosk.sh            Chromium 启动脚本（含 xrandr 旋转）
```

**数据流**：前端每 5 秒轮询 `/api/all`。天气数据由后台线程每 15 分钟更新；其它采集器同步响应。

## 设计语言

- **配色**：深色主题 (#0a0e14)，太阳橙 #e8913a，月亮银 #c8d3e0，时间蓝 #5ba0d0
- **字体**：DSEG7（LCD 时钟）/ Inter（正文+数字）/ JetBrains Mono（等宽数据）/ Noto Sans CJK（中文）
- **圆角**：卡片 18px / 嵌套元素 12px / 胶囊 999px
- **昼夜过渡**：日出日落 ±30 分钟内 CSS 变量平滑过渡

## 许可证

MIT

---

<a id="english"></a>

# Info-Pi · Ultra-wide Edition (1920×440)

English | [中文](#info-pi-超宽屏版-1920×440)

> This is the **ultra-wide edition** of Info-Pi, designed for a 1920×440 bar display
> mounted in a living room or on a dining table, paired with an Orange Pi Zero 2W.
> For the standard 800×480 Raspberry Pi version, see the [`main` branch](https://github.com/lxidea/info-pi/tree/main).

![Dashboard Screenshot](https://raw.githubusercontent.com/lxidea/info-pi/ultrawide-1920x440/screenshot.png)

## Highlights

- **Digital LCD clock** — DSEG7 seven-segment display font, readable from across the room
- **Weather-station aesthetic** — Card-based layout: clock / weather / calendar / observatory
- **24-hour celestial timeline** — Real-time axis showing sun and moon arcs simultaneously
- **Accurate moon phase** — SVG-rendered, drawn from real illumination percentage
- **Custom SVG weather icons** — Multi-layer (sun/partly cloudy/cloud/rain/snow/storm/fog), no emoji font dependency
- **Temperature curve chart** — Gradient-filled line chart, meteorological style
- **Wind direction arrow** — Rotates to compass heading in real time
- **Holiday countdown** — Auto-finds next public holiday with day count
- **Modern font stack** — Inter + JetBrains Mono + Noto Sans CJK
- **Day/night theme** — Smooth color transitions tied to sunrise/sunset

## Features

- **Current weather** — temperature, humidity, wind, feels-like, AQI + PM2.5
- **3-day forecast** — custom SVG icons + high/low temp + wind
- **12-hour temperature curve** — SVG line chart with gradient fill and weather icons
- **Monthly calendar** — rounded day cells, prominent today highlight, weekend tinting,
  Chinese holidays (red) and makeup workdays (gold)
- **Lunar calendar** — automatic solar-to-lunar conversion
- **Celestial arc** — 24h timeline with sun (orange) and moon (silver) trajectories
- **Astronomy events** — meteor showers and eclipses with countdown
- **World clocks** — three city cards with weather icon + temp + description
- **System stats** — CPU temp, CPU/RAM/disk in a compact bottom row

## Hardware

- **Compute**: Orange Pi Zero 2W (Allwinner H618 quad-core A53 + 2GB RAM)
- **Display**: 1920×440 ultra-wide bar screen (HDMI, rotated 90° via xrandr)
- **OS**: Debian 12 Bookworm (Linux 6.1, desktop)

> Will run on any 16:9 display, but the layout is optimized for 1920×440.

## Quick Start

```bash
# Clone the ultrawide branch
git clone -b ultrawide-1920x440 https://github.com/lxidea/info-pi.git
cd info-pi
python3 -m venv venv
venv/bin/pip install -r requirements.txt

# Run locally
python3 app.py
# Open http://localhost:5000
```

## Deploy to Orange Pi

```bash
# Install dependencies on the Pi
sudo apt install -y python3-pip python3-venv chromium scrot unclutter xdotool fonts-noto-cjk

# Deploy (edit deploy.sh's SSH target first)
bash deploy/deploy.sh orangepi@<pi-ip>
```

Sets up two systemd services:
- `info-pi.service` — Flask server on port 5000
- `kiosk.service` — Chromium fullscreen kiosk + xrandr rotation

### Display rotation

`deploy/kiosk.sh` assumes a vertically-mounted bar screen needing 90° rotation:

```bash
xrandr --output HDMI-1 --mode 440x1920 --rotate right
```

Remove this line if your screen is natively horizontal 1920×440.

## Configuration

Edit `config.py` for location and world clocks:

```python
WEATHER_LAT = 30.59    # default: Wuhan, China
WEATHER_LON = 114.30
WEATHER_INTERVAL = 900  # 15 minutes

WORLD_CLOCKS = [
    ("伯克利", -8, "us"),
    ("纽约", -5, "us"),
    ("巴黎", 1, "eu"),
]
```

Public holiday data lives in `collectors/holidays.py`; refresh once a year after the
State Council publishes the next year's schedule.

## Design Language

- **Palette**: dark `#0a0e14`, sun orange `#e8913a`, moon silver `#c8d3e0`, time blue `#5ba0d0`
- **Fonts**: DSEG7 (LCD clock) / Inter (body+numerals) / JetBrains Mono (tabular data) / Noto Sans CJK (Chinese)
- **Radius**: cards 18px / nested 12px / pill 999px
- **Day/night**: ±30 minutes around sunrise/sunset transition the CSS variables smoothly

## License

MIT
