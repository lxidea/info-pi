#!/bin/bash
# Launch Chromium in kiosk mode for Info-Pi dashboard

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Set display rotation for ultra-wide bar screen
xrandr --output HDMI-1 --mode 440x1920 --rotate left 2>/dev/null || true

# Hide cursor
unclutter -idle 0.1 -root &

# Launch Chromium in kiosk mode
exec chromium \
    --noerrdialogs \
    --disable-infobars \
    --kiosk \
    --incognito \
    --disable-translate \
    --no-first-run \
    --fast \
    --fast-start \
    --disable-features=TranslateUI \
    --disable-breakpad \
    --disable-crash-reporter \
    --disable-component-update \
    --disable-gpu-shader-disk-cache \
    --window-size=1920,440 \
    --window-position=0,0 \
    http://localhost:5000
