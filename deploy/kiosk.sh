#!/bin/bash
# Launch Chromium in kiosk mode for Info-Pi dashboard

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor
unclutter -idle 0.1 -root &

# Launch Chromium in kiosk mode
exec chromium-browser \
    --noerrdialogs \
    --disable-infobars \
    --kiosk \
    --incognito \
    --disable-translate \
    --no-first-run \
    --fast \
    --fast-start \
    --disable-features=TranslateUI \
    --window-size=800,480 \
    --window-position=0,0 \
    http://localhost:5000
