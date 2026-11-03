#!/bin/bash

clear

RED=$'\033[31m'
RESET=$'\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$PROJECT_ROOT" rev-parse --show-toplevel 2>/dev/null)"
RELEASE="$REPO_ROOT/vendor/gamemaker-common-utils/tools/release/gmcu_release.sh"

cd "$PROJECT_ROOT" || exit 1

if [ ! -x "$RELEASE" ]; then
    printf '%b\n' "${RED}Error: Common Utils release script not found: $RELEASE${RESET}" >&2
else
    "$RELEASE" "$PROJECT_ROOT"
fi
