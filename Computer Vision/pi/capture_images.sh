#!/bin/bash
set -euo pipefail

CAPTURE_ROOT="${CAPTURE_ROOT:-/pic_shared/captures}"
IMAGE_BASENAME="${IMAGE_BASENAME:-capture}"
CAPTURE_COMMAND="${CAPTURE_COMMAND:-auto}"
RPICAM_ARGS="${RPICAM_ARGS:---timeout 2000 --nopreview}"

mkdir -p "$CAPTURE_ROOT"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
TARGET_DIR="$CAPTURE_ROOT/$TIMESTAMP"
mkdir -p "$TARGET_DIR"
IMAGE_PATH="$TARGET_DIR/${IMAGE_BASENAME}_${TIMESTAMP}.jpg"

resolve_capture_command() {
  if [ "$CAPTURE_COMMAND" != "auto" ]; then
    printf '%s\n' "$CAPTURE_COMMAND"
    return
  fi

  if command -v rpicam-still >/dev/null 2>&1; then
    printf '%s\n' "rpicam-still"
    return
  fi

  if command -v libcamera-still >/dev/null 2>&1; then
    printf '%s\n' "libcamera-still"
    return
  fi

  return 1
}

COMMAND="$(resolve_capture_command)" || {
  echo "No supported camera capture command found. Install rpicam-still or libcamera-still, or set CAPTURE_COMMAND explicitly." >&2
  exit 1
}

echo "[$(date --iso-8601=seconds)] Capturing image to $IMAGE_PATH using $COMMAND"
"$COMMAND" $RPICAM_ARGS --output "$IMAGE_PATH"

if [ ! -s "$IMAGE_PATH" ]; then
  echo "Capture command completed but no image was written: $IMAGE_PATH" >&2
  exit 1
fi

echo "[$(date --iso-8601=seconds)] Capture complete: $IMAGE_PATH"
