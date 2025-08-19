#!/bin/bash

set -e

echo "Updating system and installing required packages..."
sudo apt update
sudo apt install -y --no-install-recommends xserver-xorg x11-xserver-utils xinit \
  chromium-browser unclutter lightdm

echo "Setting up auto-login for user 'pi' on tty1..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

echo "Creating .xinitrc to launch Chromium in kiosk mode..."
cat <<'EOF' > /home/pi/.xinitrc
#!/bin/bash
# Disable screen saver and power management
xset s off
xset s noblank
xset -dpms

# Hide mouse cursor after 1 second of inactivity
unclutter -idle 1 &

# Start Chromium in kiosk mode
chromium-browser --noerrdialogs --disable-infobars --kiosk http://www.clflux.com --incognito
EOF

chmod +x /home/pi/.xinitrc
chown pi:pi /home/pi/.xinitrc

echo "Creating systemd service to start X on boot for user pi..."
sudo tee /etc/systemd/system/kiosk.service > /dev/null <<EOF
[Unit]
Description=Kiosk mode
After=network.target

[Service]
User=pi
Group=pi
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/startx /home/pi/.xinitrc --
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling kiosk service..."
sudo systemctl daemon-reload
sudo systemctl enable kiosk.service

echo "Disabling screen blanking on console..."
sudo tee /etc/kbd/config > /dev/null <<EOF
BLANK_TIME=0
POWERDOWN_TIME=0
EOF

echo "Setup complete! Reboot the system to start kiosk mode."


