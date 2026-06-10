#!/bin/bash

ROOT="$(cd "$(dirname "$0")" && pwd)"
CLI="$ROOT/vendor/gamemaker-common-utils/tools/release/gmcu_release.py"

cd "$ROOT" || exit 1

if [ ! -f "$CLI" ]; then
    echo "Common Utils release tool not found:"
    echo "  $CLI"
elif [ ! -f "$ROOT/itch-config.json" ]; then
    echo "Release configuration not found:"
    echo "  $ROOT/itch-config.json"
else
    python3 "$CLI" menu
fi

echo
read -r -p "Press Enter to close..."
