#!/bin/bash

# Serves the exported HTML build for browser and LAN device testing.
# Double-click this file, then open one of the URLs printed below.

clear

set -u  # Stop if the script reads an undefined variable.

RED=$'\033[31m'                              # Error text color.
GREEN=$'\033[32m'                            # Success text color.
RESET=$'\033[0m'                             # Restore the terminal's default color.

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"   # Project folder containing this launcher.
BUILD="$PROJECT_ROOT/Builds/html"               # Existing HTML export to serve.
PORT=8000                                       # Local TCP port used by the test server.

# Show an actionable error and keep the Terminal window open.
fail() {
    printf '%b\n' "${RED}Error: $1${RESET}" >&2
    read -r -p "Press Enter to close..."
    exit 1
}

command -v python3 >/dev/null || fail "Python 3 not found. Install it with: brew install python"
command -v lsof >/dev/null || fail "lsof not found. Restore the macOS system utility or add it to PATH."
[ -d "$BUILD" ] || fail "HTML build not found: $BUILD"
[ -f "$BUILD/index.html" ] || fail "HTML entrypoint not found: $BUILD/index.html"

# Use the first available port, starting at 8000.
while lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null; do
    PORT=$((PORT + 1))
done

INTERFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
LAN_IP=""
[ -n "$INTERFACE" ] && LAN_IP="$(ipconfig getifaddr "$INTERFACE" 2>/dev/null || true)"

echo "Local: http://localhost:$PORT/"
if [ -n "$LAN_IP" ]; then
    echo "LAN:   http://$LAN_IP:$PORT/"
else
    echo "LAN:   unavailable; connect this computer to a network and try again."
fi
printf '%b\n' "${GREEN}Checks passed. Starting server...${RESET}"
echo "Press Control-C to stop the server."

# Listen on every network interface so both URLs can reach the same server.
python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$BUILD"

echo
read -r -p "Press Enter to close..."
