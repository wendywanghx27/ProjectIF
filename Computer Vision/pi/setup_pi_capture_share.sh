#!/bin/bash
set -euo pipefail

PI_USER="${PI_USER:-pi}"
ROS_DISTRO="${ROS_DISTRO:-noetic}"
SHARE_PATH="${SHARE_PATH:-/pic_shared}"
CAPTURE_ROOT="${CAPTURE_ROOT:-$SHARE_PATH/captures}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_SCRIPT_TARGET="/usr/local/bin/projectif-capture-images.sh"
SERVICE_PATH="/etc/systemd/system/projectif-capture.service"
TIMER_PATH="/etc/systemd/system/projectif-capture.timer"
ENV_PATH="/etc/default/projectif-capture"
SAMBA_CONFIG="/etc/samba/smb.conf"
ROS_WS="/home/$PI_USER/ros_ws"
LIBUVC_DIR="/home/$PI_USER/libuvc"
ASTRA_CAMERA_DIR="$ROS_WS/src/ros_astra_camera"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

if ! command -v lsb_release >/dev/null 2>&1; then
  apt-get update
  apt-get install -y lsb-release curl gnupg2 ca-certificates
fi

DISTRO_ID="$(lsb_release -is)"
DISTRO_CODENAME="$(lsb_release -sc)"

if [ "$DISTRO_ID" != "Ubuntu" ] || [ "$DISTRO_CODENAME" != "focal" ]; then
  cat >&2 <<EOF
This setup script currently expects Ubuntu 20.04 (Focal) with ROS Noetic packages.
Detected: $DISTRO_ID $DISTRO_CODENAME

ROS Noetic apt packages such as ros-noetic-image-geometry are not generally available on other base distros.
Use Ubuntu 20.04 on the Pi, or switch this setup to a source-build / different ROS distribution.
EOF
  exit 1
fi

if [ ! -f /etc/apt/sources.list.d/ros1-latest.list ]; then
  echo "Adding ROS apt repository for Ubuntu Focal."
  curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
    | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros/ubuntu $DISTRO_CODENAME main" \
    > /etc/apt/sources.list.d/ros1-latest.list
fi

apt-get update
apt-get install -y \
  curl gnupg2 ca-certificates lsb-release \
  samba samba-common-bin inotify-tools git cmake build-essential \
  libusb-1.0-0-dev libeigen3-dev libgflags-dev libdw-dev \
  "ros-$ROS_DISTRO-image-geometry" \
  "ros-$ROS_DISTRO-camera-info-manager" \
  "ros-$ROS_DISTRO-image-transport" \
  "ros-$ROS_DISTRO-image-publisher" \
  "ros-$ROS_DISTRO-backward-ros"

mkdir -p "$CAPTURE_ROOT"
chmod 1777 "$SHARE_PATH"
chown "$PI_USER:$PI_USER" "$CAPTURE_ROOT"

if ! grep -q "^\[pic_shared\]" "$SAMBA_CONFIG"; then
  cat >> "$SAMBA_CONFIG" <<'EOF'

[pic_shared]
path = /pic_shared
writeable = yes
browseable = yes
create mask = 0777
directory mask = 0777
public = no
force user = pi
EOF
fi

echo "Set the Samba password for user $PI_USER when prompted."
smbpasswd -a "$PI_USER"
systemctl restart smbd
systemctl enable smbd

install -m 0755 "$SCRIPT_DIR/capture_images.sh" "$CAPTURE_SCRIPT_TARGET"

if [ ! -d "$LIBUVC_DIR" ]; then
  sudo -u "$PI_USER" git clone https://github.com/libuvc/libuvc.git "$LIBUVC_DIR"
fi

if [ ! -f "$LIBUVC_DIR/build/Makefile" ]; then
  sudo -u "$PI_USER" mkdir -p "$LIBUVC_DIR/build"
  (
    cd "$LIBUVC_DIR/build"
    cmake ..
  )
fi
make -C "$LIBUVC_DIR/build" -j"$(nproc)"
make -C "$LIBUVC_DIR/build" install
ldconfig

sudo -u "$PI_USER" mkdir -p "$ROS_WS/src"
if [ ! -d "$ASTRA_CAMERA_DIR" ]; then
  sudo -u "$PI_USER" git clone https://github.com/orbbec/ros_astra_camera.git "$ASTRA_CAMERA_DIR"
fi

sudo -u "$PI_USER" bash -lc "source /opt/ros/$ROS_DISTRO/setup.bash && cd '$ROS_WS' && catkin_make"
sudo -u "$PI_USER" bash -lc "source '$ROS_WS/devel/setup.bash' && roscd astra_camera && ./scripts/create_udev_rules"
udevadm control --reload
udevadm trigger

cat > "$ENV_PATH" <<EOF
PI_USER=$PI_USER
CAPTURE_ROOT=$CAPTURE_ROOT
CAPTURE_INTERVAL_SECONDS=10800
ROS_SETUP=/opt/ros/$ROS_DISTRO/setup.bash
WORKSPACE_SETUP=$ROS_WS/devel/setup.bash
OUTPUT_DIR=/home/$PI_USER/astra_outputs
EOF

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=ProjectIF image capture job
After=network-online.target smbd.service
Wants=network-online.target

[Service]
Type=oneshot
User=$PI_USER
EnvironmentFile=$ENV_PATH
ExecStart=$CAPTURE_SCRIPT_TARGET
EOF

cat > "$TIMER_PATH" <<EOF
[Unit]
Description=Run ProjectIF image capture every 3 hours

[Timer]
OnBootSec=2min
OnUnitActiveSec=3h
Unit=projectif-capture.service
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now projectif-capture.timer

cat <<EOF
Pi setup complete.

Next steps:
1. Inspect the timer with: systemctl status projectif-capture.timer
2. Trigger an immediate capture with: systemctl start projectif-capture.service
3. Confirm the share is exported with: smbclient -L localhost -U $PI_USER
EOF
