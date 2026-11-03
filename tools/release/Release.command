#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null)"
RELEASE="$REPO_ROOT/vendor/gamemaker-common-utils/tools/release/gmcu_release.sh"

cd "$PROJECT_ROOT" || exit 1

if [ ! -x "$RELEASE" ]; then
    echo "Common Utils release script not found:"
    echo "  $RELEASE"
else
    "$RELEASE" "$PROJECT_ROOT"
fi

echo
read -r -p "Press Enter to close..."
