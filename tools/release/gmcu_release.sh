#!/bin/bash
set -u
ROOT="${1:-$(pwd)}"
CONFIG="$ROOT/itch-config.json"
STATE="$ROOT/itch-deploy/config.jsonc"

fail() {
    echo "Error: $1" >&2
    exit 1
}
read_config() {
    /usr/bin/plutil -extract "$1" raw "$CONFIG"
}
[ -f "$CONFIG" ] || fail "Configuration not found: $CONFIG"
command -v jq >/dev/null || fail "jq is required"

USERNAME="$(read_config username)" || fail "Missing username"
PROJECT="$(read_config project_name)" || fail "Missing project_name"
PLATFORM_COUNT="$(read_config platforms)" || fail "Missing platforms"
[ "$PLATFORM_COUNT" -gt 0 ] || fail "At least one platform is required"
if [ "$PLATFORM_COUNT" -eq 1 ]; then
    PLATFORM_INDEX=0
else
    for ((index = 0; index < PLATFORM_COUNT; index++)); do
        echo "  $((index + 1)). $(read_config "platforms.$index")"
    done
    read -r -p "Platform number: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || fail "Invalid platform"
    [ "$choice" -ge 1 ] && [ "$choice" -le "$PLATFORM_COUNT" ] || fail "Invalid platform"
    PLATFORM_INDEX=$((choice - 1))
fi
PLATFORM="$(read_config "platforms.$PLATFORM_INDEX")"
PROTOTYPE="$(read_config prototype 2>/dev/null || echo false)"
BUILD="$ROOT/Builds/$PLATFORM"
[ -e "$BUILD" ] || fail "Export not found: $BUILD"

BUTLER="$(command -v butler || true)"
[ -n "$BUTLER" ] || BUTLER="$HOME/bin/butler"
[ -x "$BUTLER" ] || fail "Butler not found"

if [ "$PROTOTYPE" = true ]; then
    VERSION="$(basename "$ROOT")-$(date -u +%Y%m%d-%H%M%S)"
else
    [ "$(git -C "$ROOT" branch --show-current)" = main ] || fail "Release requires main"
    [ -z "$(git -C "$ROOT" status --short)" ] || fail "Release requires a clean worktree"
    OPTIONS="$BUILD/options.ini"
    [ -f "$OPTIONS" ] || fail "Version file not found: $OPTIONS"
    YEAR="$(date +%Y)"
    MONTH="$(date +%m)"
    MONTH_KEY="$YEAR-$MONTH"
    PLATFORM_NUMBER=$((PLATFORM_INDEX + 1))
    COUNT=1
    if [ -f "$STATE" ]; then
        COUNT="$(jq -r --arg p "$PLATFORM" --arg m "$MONTH_KEY" \
            '(.build_counts[$p][$m] // 0) + 1' "$STATE")"
    fi
    VERSION="$YEAR.$MONTH.$PLATFORM_NUMBER.$COUNT"
fi

echo "Publish $BUILD to $USERNAME/$PROJECT:$PLATFORM as $VERSION"
read -r -p "Continue? [y/N]: " answer
[ "$answer" = y ] || [ "$answer" = Y ] || exit 0

if [ "$PROTOTYPE" != true ]; then
    sed -e "s/^MajorVersion=.*/MajorVersion=$YEAR/" \
        -e "s/^MinorVersion=.*/MinorVersion=$((10#$MONTH))/" \
        -e "s/^BuildVersion=.*/BuildVersion=$PLATFORM_NUMBER/" \
        -e "s/^RevisionVersion=.*/RevisionVersion=$COUNT/" \
        "$OPTIONS" > "$OPTIONS.tmp" && mv "$OPTIONS.tmp" "$OPTIONS"
    [ "$PLATFORM" = html ] && BUILD_NUMBER="$BUILD/html5game/buildnumber.txt" \
        || BUILD_NUMBER="$BUILD/buildnumber.txt"
    mkdir -p "$(dirname "$BUILD_NUMBER")"
    printf '%s' "$VERSION" > "$BUILD_NUMBER"
fi

"$BUTLER" push "$BUILD" "$USERNAME/$PROJECT:$PLATFORM" --userversion "$VERSION" || exit 1
[ "$PROTOTYPE" = true ] && echo "Published $VERSION" && exit 0

mkdir -p "$(dirname "$STATE")"
[ -f "$STATE" ] || echo '{"build_counts":{}}' > "$STATE"
jq --arg p "$PLATFORM" --arg m "$MONTH_KEY" --argjson n "$COUNT" \
    '.build_counts[$p][$m] = $n' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

TARGET="$PLATFORM"
[ "$PLATFORM" = html ] && TARGET=html5
SOURCE_OPTIONS="$ROOT/options/$TARGET/options_$TARGET.yy"
FIELD="option_${TARGET}_version"
[ -f "$SOURCE_OPTIONS" ] || fail "Source options not found: $SOURCE_OPTIONS"
sed -E "s/(\"$FIELD\"[[:space:]]*:[[:space:]]*\")[^\"]*/\1$VERSION/" \
    "$SOURCE_OPTIONS" > "$SOURCE_OPTIONS.tmp" && mv "$SOURCE_OPTIONS.tmp" "$SOURCE_OPTIONS"

git -C "$ROOT" add "$STATE" "$SOURCE_OPTIONS" || exit 1
git -C "$ROOT" commit -m "Release v$VERSION" || exit 1
git -C "$ROOT" tag "releases/v$VERSION" || exit 1
echo "Published and tagged v$VERSION"
read -r -p "Push commit and tag? [y/N]: " answer
if [ "$answer" = y ] || [ "$answer" = Y ]; then
    git -C "$ROOT" push origin main && git -C "$ROOT" push origin "releases/v$VERSION"
fi
