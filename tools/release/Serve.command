#!/bin/bash

# Serves the exported HTML build for browser and LAN device testing.
# Double-click this file; the LAN URL opens when the server is ready.

clear

set -u  # Stop if the script reads an undefined variable.

RED=$'\033[31m'                              # Error text color.
GREEN=$'\033[32m'                            # Success text color.
RESET=$'\033[0m'                             # Restore the terminal's default color.

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"   # Project folder containing this launcher.
BUILD="$PROJECT_ROOT/Builds/html"               # Existing HTML export to serve.
PORT=8000                                       # Local TCP port used by the test server.

# Show an actionable error and stop the launcher.
fail() {
    printf '%b\n' "${RED}Error: $1${RESET}" >&2
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

LOCAL_URL="http://localhost:$PORT/"
OPEN_URL="$LOCAL_URL"

echo "Local: $LOCAL_URL"
if [ -n "$LAN_IP" ]; then
    LAN_URL="http://$LAN_IP:$PORT/"
    OPEN_URL="$LAN_URL"
    echo "LAN:   $LAN_URL"
else
    echo "LAN:   unavailable; connect this computer to a network and try again."
fi

printf '%b\n' "${GREEN}Checks passed. Starting server...${RESET}"
echo "Press Control-C to stop the server."

# Listen on every network interface so both URLs can reach the same server.
python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$BUILD" &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' INT TERM EXIT

# Wait until the server accepts connections before opening the browser.
while ! lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null; do
    kill -0 "$SERVER_PID" 2>/dev/null || fail "The HTML server stopped before opening port $PORT."
    sleep 0.1
done

open "$OPEN_URL" || printf '%b\n' "${RED}Error: Could not open $OPEN_URL automatically.${RESET}" >&2
wait "$SERVER_PID"
SERVER_STATUS=$?
trap - INT TERM EXIT
exit "$SERVER_STATUS"
