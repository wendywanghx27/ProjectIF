#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "This Samba setup has been replaced by the Pi setup script:"
echo "  sudo bash \"$SCRIPT_DIR/pi/setup_pi_capture_share.sh\""
