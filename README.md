# gamemaker-common-utils

Reusable GameMaker utilities intended to be shared across Ed Casillas
GameMaker projects.

The primary workflow is an editable Git submodule: add this repository to a
project, use the resources from inside the submodule, improve the utilities
from any consuming project, push those changes here, and pull them into other
projects later.

This is not a full GameMaker project. It is a source library of GameMaker
resources that consuming projects register in their own `.yyp`.

## Current Modules

Import modules in this order:

1. `Core`
   - `scripts/common_macros/common_macros.yy`
   - Shared macros and helpers such as `OBJECT_NAME`, `ROOM_NAME`,
     `DELTA_TIME_SECONDS`, `LAYER_DEPTH_MIN`, and notification handler setup.
2. `Drawing`
   - `scripts/DrawingParameters/DrawingParameters.yy`
   - Restores draw state after temporary draw changes.
3. `Logging`
   - `scripts/log_config/log_config.yy`
   - `scripts/get_log_tags/get_log_tags.yy`
   - `scripts/log_debug/log_debug.yy`
   - `scripts/log_info/log_info.yy`
   - `scripts/log_warn/log_warn.yy`
   - `scripts/log_error/log_error.yy`
   - `scripts/log_exception/log_exception.yy`
   - Portable debug output using `show_debug_message`.
4. `EventBus`
   - `scripts/event_bus/event_bus.yy`
   - Publish-subscribe API: `eventbus_subscribe`, `eventbus_unsubscribe`,
     `eventbus_dispatch`.
5. `InGameNotifications`
   - `scripts/InGameNotificationSettings/InGameNotificationSettings.yy`
   - `scripts/show_notification/show_notification.yy`
   - `objects/o_notification_from_top/o_notification_from_top.yy`
   - Optional visual notifications. When imported, it registers a handler that
     lets `log_error` and `log_exception` show notifications in dev builds.

Module notes live in [`docs/modules`](docs/modules). The implementation and
migration checklist lives in
[`docs/implementation-plan.md`](docs/implementation-plan.md).

## Add As A Submodule

From the consuming GameMaker project:

```sh
git submodule add https://github.com/edcasillas/gamemaker-common-utils.git vendor/gamemaker-common-utils
git submodule update --init --recursive
```

Then register the desired `.yy` resources from
`vendor/gamemaker-common-utils` in the consuming project's `.yyp`. Keep resource
paths inside the submodule instead of copying files into the project.

Open the project in GameMaker after registering resources. GameMaker may
reserialize `.yy` or `.yyp` files, and runtime behavior cannot be fully
validated from the command line.

## Update A Consuming Project

```sh
cd vendor/gamemaker-common-utils
git pull origin main
cd ../..
git status
git add vendor/gamemaker-common-utils
git commit -m "Update gamemaker-common-utils"
```

## Modify The Library From A Consuming Project

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

## Consumer Import Checklist

- Confirm the consuming repo state with `git status`.
- Add or update the submodule.
- Register modules in dependency order: `Core`, `Drawing`, `Logging`,
  `EventBus`, then optional `InGameNotifications`.
- Check for name conflicts before replacing local resources.
- Run `git diff --check`.
- Open the project in GameMaker and run a smoke test.
- Report whether only source/docs changed or whether GameMaker reserialized
  `.yy`/`.yyp` files.

## Current Limits

- No `.yymps` package is generated yet.
- This repo does not include a sample `.yyp` yet.
- GameMaker IDE validation is still required after import.
- Logging is intentionally portable and does not send GameAnalytics or
  GlobalStats.io events.
- HTML5 extensions such as JSUtils and NoMobileWeb are not included.

## Roadmap

Candidates for later extraction:

- Input hub
- Buttons and reusable UI objects
- Labels and localization helpers
- Transitions
- Timed actions
- Universal cursor
- GameAnalytics wrappers
- GlobalStats.io wrappers
- HTML5 extensions
- Optional `.yymps` packaging
