#!/bin/bash
set -euo pipefail

CAPTURE_ROOT="${CAPTURE_ROOT:-/pic_shared/captures}"
IMAGE_BASENAME="${IMAGE_BASENAME:-capture}"
CAPTURE_COMMAND="${CAPTURE_COMMAND:-auto}"
VIDEO_DEVICE="${VIDEO_DEVICE:-auto}"
VIDEO_SIZE="${VIDEO_SIZE:-1280x720}"
VIDEO_INPUT_FORMAT="${VIDEO_INPUT_FORMAT:-mjpeg}"
FFMPEG_EXTRA_ARGS="${FFMPEG_EXTRA_ARGS:-}"

mkdir -p "$CAPTURE_ROOT"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
TARGET_DIR="$CAPTURE_ROOT/$TIMESTAMP"
mkdir -p "$TARGET_DIR"
IMAGE_PATH="$TARGET_DIR/${IMAGE_BASENAME}_${TIMESTAMP}.jpg"

resolve_video_device() {
  if [ "$VIDEO_DEVICE" != "auto" ]; then
    printf '%s\n' "$VIDEO_DEVICE"
    return
  fi

  if command -v v4l2-ctl >/dev/null 2>&1; then
    v4l2-ctl --list-devices 2>/dev/null \
      | awk '
          /^[^[:space:]].*:$/ { in_device = ($0 ~ /[Oo]rbbec|[Aa]stra|[Uu][Vv][Cc]/) }
          in_device && /\/dev\/video[0-9]+/ { print $1; exit }
        '
    return
  fi

  for dev in /dev/video*; do
    if [ -e "$dev" ]; then
      printf '%s\n' "$dev"
      return
    fi
  done

  return 1
}

capture_with_ffmpeg() {
  local device="$1"
  local input_format_args=()
  local extra_args=()

  if [ -n "$VIDEO_INPUT_FORMAT" ]; then
    input_format_args=(-input_format "$VIDEO_INPUT_FORMAT")
  fi

  if [ -n "$FFMPEG_EXTRA_ARGS" ]; then
    # shellcheck disable=SC2206
    extra_args=($FFMPEG_EXTRA_ARGS)
  fi

  ffmpeg -hide_banner -loglevel error -y \
    -f video4linux2 \
    "${input_format_args[@]}" \
    -video_size "$VIDEO_SIZE" \
    -i "$device" \
    "${extra_args[@]}" \
    -frames:v 1 \
    "$IMAGE_PATH"
}

capture_with_fswebcam() {
  local device="$1"
  fswebcam -q -d "$device" -r "$VIDEO_SIZE" --no-banner "$IMAGE_PATH"
}

DEVICE_PATH="$(resolve_video_device)" || {
  echo "No V4L2 video device found for the Astra camera. Check cable/power and inspect with 'v4l2-ctl --list-devices'." >&2
  exit 1
}

echo "[$(date --iso-8601=seconds)] Capturing image to $IMAGE_PATH from $DEVICE_PATH"

case "$CAPTURE_COMMAND" in
  auto|ffmpeg)
    if command -v ffmpeg >/dev/null 2>&1; then
      capture_with_ffmpeg "$DEVICE_PATH"
    elif command -v fswebcam >/dev/null 2>&1; then
      capture_with_fswebcam "$DEVICE_PATH"
    else
      echo "No supported capture tool found. Install ffmpeg or fswebcam." >&2
      exit 1
    fi
    ;;
  fswebcam)
    capture_with_fswebcam "$DEVICE_PATH"
    ;;
  *)
    echo "Unsupported CAPTURE_COMMAND: $CAPTURE_COMMAND. Use auto, ffmpeg, or fswebcam." >&2
    exit 1
    ;;
esac

if [ ! -s "$IMAGE_PATH" ]; then
  echo "Capture command completed but no image was written: $IMAGE_PATH" >&2
  exit 1
fi

echo "[$(date --iso-8601=seconds)] Capture complete: $IMAGE_PATH"
