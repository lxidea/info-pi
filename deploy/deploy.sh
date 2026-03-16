#!/bin/bash
# Deploy Info-Pi to Raspberry Pi
# Usage: bash deploy/deploy.sh [user@host]

set -euo pipefail

TARGET="${1:-pi@raspberrypi.local}"
REMOTE_DIR="/home/pi/info-pi"

echo "==> Deploying to $TARGET:$REMOTE_DIR"

# Sync project files
rsync -avz --delete \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'venv/' \
    --exclude '.git/' \
    -e ssh \
    "$(dirname "$0")/../" \
    "$TARGET:$REMOTE_DIR/"

echo "==> Setting up Python venv and installing dependencies..."
ssh "$TARGET" << 'REMOTE'
cd /home/pi/info-pi
python3 -m venv venv 2>/dev/null || true
venv/bin/pip install --quiet -r requirements.txt
chmod +x deploy/kiosk.sh
REMOTE

echo "==> Installing systemd services..."
ssh "$TARGET" << 'REMOTE'
sudo cp /home/pi/info-pi/deploy/info-pi.service /etc/systemd/system/
sudo cp /home/pi/info-pi/deploy/kiosk.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable info-pi.service kiosk.service
sudo systemctl restart info-pi.service
sudo systemctl restart kiosk.service
REMOTE

echo "==> Deployment complete!"
echo "    Dashboard: http://$TARGET:5000 (replace hostname with IP if needed)"
