# gamemaker-common-utils Implementation Plan

## Vision

`gamemaker-common-utils` is a shared, reusable GameMaker utility library for
projects maintained by Ed Casillas. It is intended to work like the existing
Unity common utils workflow: add the library as a Git submodule to a project,
improve the shared code from whichever project is using it, push those changes,
and pull them into other projects later.

The primary distribution format for v1 is an editable Git submodule. GameMaker
Local Asset Packages (`.yymps`) may be added later as an optional import format,
but they are not required for the first usable version.

## v1 Module Boundaries

Import modules in this order:

1. `Core`
   - Shared macros and low-level helpers.
   - Provides `OBJECT_NAME`, `ROOM_NAME`, `DELTA_TIME_SECONDS`,
     `LAYER_DEPTH_MIN`, `LAYER_DEPTH_MAX`, and dev-build flags.
2. `Drawing`
   - Drawing-state helpers such as `DrawingParameters`.
3. `Logging`
   - Portable `log_debug`, `log_info`, `log_warn`, `log_error`, and
     `log_exception`.
   - Must not depend on GameAnalytics, JSUtils, GlobalStats, NoMobileWeb, or
     any game-specific service.
4. `EventBus`
   - Publish-subscribe helper with the existing API:
     `eventbus_subscribe`, `eventbus_unsubscribe`, and `eventbus_dispatch`.
   - Depends only on `Core` and `Logging`.
5. `InGameNotifications`
   - Optional visual notification system.
   - Provides `show_notification`, `InGameNotificationSettings`, and
     `o_notification_from_top`.
   - Depends on `Core` and `Drawing`.

`show_notification` is included in v1, but it is not a hard dependency of the
EventBus. Logging may use notifications only when the notification module is
present and enabled.

## Submodule Usage

Add the library to a GameMaker project:

```sh
git submodule add https://github.com/edcasillas/gamemaker-common-utils.git vendor/gamemaker-common-utils
git submodule update --init --recursive
```

Update the library inside a project:

```sh
cd vendor/gamemaker-common-utils
git pull origin main
cd ../..
git status
git add vendor/gamemaker-common-utils
git commit -m "Update gamemaker-common-utils"
```

Modify the library from inside a project:

```sh
cd vendor/gamemaker-common-utils
# edit shared utility files
git status
git add .
git commit -m "Describe common utils change"
git push origin main
cd ../..
git add vendor/gamemaker-common-utils
git commit -m "Update gamemaker-common-utils pointer"
```

## Import Checklist For A Consumer Project

- Confirm the consumer project state with `git status`.
- Add or update the submodule under `vendor/gamemaker-common-utils`.
- Register only the needed GameMaker resources in the consumer `.yyp`.
- Preserve resource paths under the submodule instead of copying files into the
  consumer project.
- Import modules in dependency order: `Core`, `Drawing`, `Logging`, `EventBus`,
  then `InGameNotifications` if visual notifications are needed.
- Check for name conflicts before replacing existing project resources:
  `log_debug`, `log_info`, `log_warn`, `log_error`, `log_exception`,
  `event_bus`, `show_notification`, `InGameNotificationSettings`, and
  `o_notification_from_top`.
- Run `git diff --check`.
- Open the project in GameMaker and run a smoke test, because GameMaker resource
  behavior cannot be fully validated from the command line.
- Report whether only source/docs changed or whether GameMaker reserialized
  `.yy`/`.yyp` files.

## Fantasma Migration Checklist

- Add this repository as `vendor/gamemaker-common-utils`.
- Register only the v1 module set first.
- Replace Fantasma's local duplicates only after the library resources are
  present and portable.
- Validate these behaviors in the GameMaker IDE:
  - Event dispatch still reaches buttons, menu controllers, and `objCtrl`.
  - Pause/progression events still work.
  - Dev-build errors can show visual notifications.
  - Gamepad connect/disconnect notifications still appear when enabled.
- Confirm that generated build output under `Builds/` was not touched.

## Validation Checklist

- `git diff --check`
- `rg "Fantasma|objCtrl|GameAnalytics|GlobalStats|JSUtils|NoMobileWeb|localization_t|Builds"`
- `git status --short`
- GameMaker IDE smoke test in each consumer project after import.

## Future Modules

Do not include these in v1 unless the first module set has been validated:

- `InputHub`
- buttons and reusable UI objects
- labels and localization helpers
- transitions
- timed actions
- universal cursor
- GameAnalytics wrappers
- GlobalStats.io wrappers
- HTML5 extensions such as JSUtils and NoMobileWeb
- `.yymps` packaging
