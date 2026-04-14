#!/bin/bash
set -euo pipefail

CAPTURE_ROOT="${CAPTURE_ROOT:-/pic_shared/captures}"
CAPTURE_INTERVAL_SECONDS="${CAPTURE_INTERVAL_SECONDS:-10800}"
ROS_SETUP="${ROS_SETUP:-/opt/ros/noetic/setup.bash}"
WORKSPACE_SETUP="${WORKSPACE_SETUP:-$HOME/ros_ws/devel/setup.bash}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/astra_outputs}"

mkdir -p "$CAPTURE_ROOT" "$OUTPUT_DIR/images" "$OUTPUT_DIR/pointclouds"

if [ ! -f "$ROS_SETUP" ]; then
  echo "ROS setup file not found: $ROS_SETUP" >&2
  exit 1
fi

if [ ! -f "$WORKSPACE_SETUP" ]; then
  echo "Workspace setup file not found: $WORKSPACE_SETUP" >&2
  exit 1
fi

source "$ROS_SETUP"
source "$WORKSPACE_SETUP"

if ! pgrep -f "astra.launch" >/dev/null 2>&1; then
  nohup roslaunch astra_camera astra.launch > "$OUTPUT_DIR/astra_launch.log" 2>&1 &
  sleep 10
fi

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
TARGET_DIR="$CAPTURE_ROOT/$TIMESTAMP"
mkdir -p "$TARGET_DIR/images" "$TARGET_DIR/pointclouds"

echo "[$(date --iso-8601=seconds)] Capturing into $TARGET_DIR"
rosservice call /camera/save_images "{}"
rosservice call /camera/save_point_cloud_xyz "{}"

if [ -d "$HOME/.ros/image" ]; then
  mv "$HOME/.ros/image" "$TARGET_DIR/images"
fi

if [ -d "$HOME/.ros/point_cloud" ]; then
  mv "$HOME/.ros/point_cloud" "$TARGET_DIR/pointclouds"
fi

echo "[$(date --iso-8601=seconds)] Capture complete"
