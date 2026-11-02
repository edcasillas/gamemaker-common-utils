#!/bin/bash

# Publishes an existing GameMaker export to itch.io using the project's itch-config.json.
# Pass the project root, or omit it to use the current directory.
# Example: ./gmcu_release.sh /path/to/game

set -u                                  # Stop if the script reads an undefined variable.
ROOT="${1:-$(pwd)}"                     # Use the first argument as the project root, or the current directory when omitted.

CONFIG="$ROOT/itch-config.json"         # Consumer-owned itch.io destination and platform list.
STATE="$ROOT/itch-deploy/config.jsonc"  # Consumer-owned release counter source of truth.

# Show an error message and stop the script with an error.
fail() {
    echo "Error: $1" >&2                  # Write the message to stderr.
    exit 1                                # Stop the script with a failure status.
}

read_config() {
    /usr/bin/plutil -extract "$1" raw "$CONFIG" # Print the requested config value without JSON formatting.
}

[ -f "$CONFIG" ] || fail "Configuration not found: $CONFIG" # Require the consumer configuration file.
command -v jq >/dev/null || fail "jq is required"             # Require jq to update the release counter JSON.

USERNAME="$(read_config username)" || fail "Missing username"                  # itch.io account name.
PROJECT="$(read_config project_name)" || fail "Missing project_name"           # itch.io project slug.
PLATFORM_COUNT="$(read_config platforms)" || fail "Missing platforms"          # Number of configured export platforms.
[ "$PLATFORM_COUNT" -gt 0 ] || fail "At least one platform is required"       # Reject an empty platform list.

PLATFORM_INDEX=0                        # The only platform is selected automatically.
if [ "$PLATFORM_COUNT" -gt 1 ]; then   # Ask which export to publish when several are configured.
    for ((index = 0; index < PLATFORM_COUNT; index++)); do # Visit each configured platform.
        echo "  $((index + 1)). $(read_config "platforms.$index")" # Print its numbered menu entry.
    done
    read -r -p "Platform number: " choice # Read the selected one-based menu number.
    [[ "$choice" =~ ^[0-9]+$ ]] || fail "Invalid platform" # Require an integer.
    [ "$choice" -ge 1 ] && [ "$choice" -le "$PLATFORM_COUNT" ] || fail "Invalid platform" # Require an existing entry.
    PLATFORM_INDEX=$((choice - 1))       # Convert the selection to a zero-based config index.
fi

PLATFORM="$(read_config "platforms.$PLATFORM_INDEX")" # Selected platform and itch.io channel name.
PROTOTYPE="$(read_config prototype 2>/dev/null || echo false)" # Use prototype behavior only when explicitly enabled.
BUILD="$ROOT/Builds/$PLATFORM"            # Existing GameMaker export to publish.
[ -e "$BUILD" ] || fail "Export not found: $BUILD" # Stop before release work when the export is missing.

BUTLER="$(command -v butler || true)"      # Prefer a Butler executable available in PATH.
[ -n "$BUTLER" ] || BUTLER="$HOME/bin/butler" # Otherwise use the standard local installation.
[ -x "$BUTLER" ] || fail "Butler not found" # Require an executable Butler before continuing.

# Prototype versions are disposable; game versions advance the stored counter.
if [ "$PROTOTYPE" = true ]; then
    VERSION="$(basename "$ROOT")-$(date -u +%Y%m%d-%H%M%S)" # Give disposable builds a unique UTC timestamp.
else
    [ "$(git -C "$ROOT" branch --show-current)" = main ] || fail "Release requires main" # Release only from main.
    [ -z "$(git -C "$ROOT" status --short)" ] || fail "Release requires a clean worktree" # Keep release commits isolated.
    OPTIONS="$BUILD/options.ini"            # Generated GameMaker version metadata inside the export.
    [ -f "$OPTIONS" ] || fail "Version file not found: $OPTIONS" # Require metadata before modifying the export.
    YEAR="$(date +%Y)"                      # Version major component.
    MONTH="$(date +%m)"                     # Version minor component.
    MONTH_KEY="$YEAR-$MONTH"                # Counter bucket for the current month.
    PLATFORM_NUMBER=$((PLATFORM_INDEX + 1)) # Stable one-based platform component.
    COUNT=1                                  # First release when the state file has no matching counter.
    if [ -f "$STATE" ]; then               # Advance the persisted platform/month counter when available.
        COUNT="$(jq -r --arg p "$PLATFORM" --arg m "$MONTH_KEY" \
            '(.build_counts[$p][$m] // 0) + 1' "$STATE")"
    fi
    VERSION="$YEAR.$MONTH.$PLATFORM_NUMBER.$COUNT" # Complete release version.

    TARGET="$PLATFORM"                      # GameMaker target folder usually matches the release platform.
    [ "$PLATFORM" = html ] && TARGET=html5 # GameMaker names the HTML target html5.
    SOURCE_OPTIONS="$ROOT/options/$TARGET/options_$TARGET.yy" # Source metadata committed after release.
    [ -f "$SOURCE_OPTIONS" ] || fail "Source options not found: $SOURCE_OPTIONS" # Prevent a release that cannot be recorded.
fi

echo "Publish $BUILD to $USERNAME/$PROJECT:$PLATFORM as $VERSION" # Show the exact pending upload.
read -r -p "Continue? [y/N]: " answer    # Require explicit confirmation.
[ "$answer" = y ] || [ "$answer" = Y ] || exit 0 # Cancel without changing anything unless confirmed.

# Stamp a game export with the version that itch.io will receive.
if [ "$PROTOTYPE" != true ]; then
    sed -e "s/^MajorVersion=.*/MajorVersion=$YEAR/" \
        -e "s/^MinorVersion=.*/MinorVersion=$((10#$MONTH))/" \
        -e "s/^BuildVersion=.*/BuildVersion=$PLATFORM_NUMBER/" \
        -e "s/^RevisionVersion=.*/RevisionVersion=$COUNT/" \
        "$OPTIONS" > "$OPTIONS.tmp" && mv "$OPTIONS.tmp" "$OPTIONS"
    [ "$PLATFORM" = html ] && BUILD_NUMBER="$BUILD/html5game/buildnumber.txt" \
        || BUILD_NUMBER="$BUILD/buildnumber.txt"
    mkdir -p "$(dirname "$BUILD_NUMBER")" # Ensure the runtime metadata directory exists.
    printf '%s' "$VERSION" > "$BUILD_NUMBER" # Expose the version to the game runtime.
fi

"$BUTLER" push "$BUILD" "$USERNAME/$PROJECT:$PLATFORM" --userversion "$VERSION" || exit 1 # Upload the export.
[ "$PROTOTYPE" = true ] && echo "Published $VERSION" && exit 0 # Prototypes need no release bookkeeping.

mkdir -p "$(dirname "$STATE")"           # Ensure the consumer state directory exists.
[ -f "$STATE" ] || echo '{"build_counts":{}}' > "$STATE" # Initialize missing counter state.
jq --arg p "$PLATFORM" --arg m "$MONTH_KEY" --argjson n "$COUNT" \
    '.build_counts[$p][$m] = $n' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

# Write the published version into the selected GameMaker target settings.
sed -E "s/(\"option_${TARGET}_version\"[[:space:]]*:[[:space:]]*\")[^\"]*/\1$VERSION/" \
    "$SOURCE_OPTIONS" > "$SOURCE_OPTIONS.tmp" && mv "$SOURCE_OPTIONS.tmp" "$SOURCE_OPTIONS"

# Record the successful release locally; pushing remains explicit.
git -C "$ROOT" add "$STATE" "$SOURCE_OPTIONS" || exit 1 # Stage only release-owned source files.
git -C "$ROOT" commit -m "Release v$VERSION" || exit 1 # Create the local release commit.
git -C "$ROOT" tag "releases/v$VERSION" || exit 1 # Mark the exact released commit.
echo "Published and tagged v$VERSION"      # Report completed local bookkeeping.
read -r -p "Push commit and tag? [y/N]: " answer # Keep remote Git mutation optional.
if [ "$answer" = y ] || [ "$answer" = Y ]; then # Push only after explicit confirmation.
    git -C "$ROOT" push origin main && git -C "$ROOT" push origin "releases/v$VERSION" # Publish commit and tag together.
fi
