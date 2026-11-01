#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null)"
RELEASE="$REPO_ROOT/vendor/gamemaker-common-utils/tools/release/gmcu_release.sh"

cd "$PROJECT_ROOT" || exit 1

if [ ! -x "$RELEASE" ]; then
    echo "Common Utils release script not found:"
    echo "  $RELEASE"
else
    echo "1. Serve HTML build"
    echo "2. Publish to itch.io"
    read -r -p "Choose an option: " choice
    if [ "$choice" = 1 ]; then
        python3 -m http.server 8000 --bind 0.0.0.0 --directory "$PROJECT_ROOT/Builds/html"
    elif [ "$choice" = 2 ]; then
        "$RELEASE" "$PROJECT_ROOT"
    fi
fi

echo
read -r -p "Press Enter to close..."
