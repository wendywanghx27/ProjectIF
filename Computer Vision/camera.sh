#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "This file is now reference-only."
echo "Run the Raspberry Pi setup script instead:"
echo "  sudo bash \"$SCRIPT_DIR/pi/setup_pi_capture_share.sh\""
