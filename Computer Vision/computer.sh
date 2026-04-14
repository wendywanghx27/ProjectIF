#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "The computer-side flow is now Docker Compose based."
echo "From the sam3 directory run:"
echo "  cd \"$SCRIPT_DIR/segmenting/sam3\""
echo "  docker compose up --build"
