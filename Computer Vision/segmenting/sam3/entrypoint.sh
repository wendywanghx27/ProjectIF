#!/bin/sh
set -eu

if [ -z "${INPUT_DIR:-}" ] || [ -z "${MASK_OUTPUT_DIR:-}" ] || [ -z "${STATE_FILE:-}" ]; then
  echo "INPUT_DIR, MASK_OUTPUT_DIR, and STATE_FILE must be set." >&2
  exit 1
fi

if [ ! -d "${INPUT_DIR}" ]; then
  echo "Input directory is not available: ${INPUT_DIR}" >&2
  exit 1
fi

if ! ls -a "${INPUT_DIR}" >/dev/null 2>&1; then
  echo "Input directory is mounted but cannot be read: ${INPUT_DIR}" >&2
  exit 1
fi

mkdir -p "${MASK_OUTPUT_DIR}"
mkdir -p "$(dirname "${STATE_FILE}")"

exec python /app/multiSegment.py "$@"
