# gamemaker-common-utils Implementation Plan

## Vision

`gamemaker-common-utils` is a shared, reusable GameMaker utility library for
projects maintained by Ed Casillas. It is intended to work like the existing
Unity common utils workflow: add the library as a Git submodule to a project,
improve the shared code from whichever project is using it, push those changes,
and pull them into other projects later.

The distribution format is an editable Git submodule. GameMaker Local Asset
Packages (`.yymps`) are not part of the active plan because they copy imported
resources and do not preserve the editable submodule + symlink workflow.

Extraction changes ownership, not behavior. Preserve timing, presentation,
text, side-effect order, initialization order, platform injection points, and
consumer policy. Any intentional behavior change must be reviewed and
validated separately.

## v1 Module Boundaries

Import modules in this order:

1. `Core`
   - Shared macros and low-level helpers.
   - Provides `GMCU_OBJECT_NAME`, `GMCU_ROOM_NAME`, `GMCU_DELTA_TIME_SECONDS`,
     `GMCU_LAYER_DEPTH_MIN`, `GMCU_LAYER_DEPTH_MAX`, and dev-build flags.
2. `Drawing`
   - Drawing-state helpers such as `gmcu_DrawingParameters`.
3. `Logging`
   - Portable `gmcu_log_debug`, `gmcu_log_info`, `gmcu_log_warn`, `gmcu_log_error`, and
     `gmcu_log_exception`.
   - Must not depend on GameAnalytics, GlobalStats, HTML5 Helpers, or any
     game-specific service.
4. `EventBus`
   - Publish-subscribe helper with the existing API:
     `gmcu_eventbus_subscribe`, `gmcu_eventbus_unsubscribe`, and `gmcu_eventbus_dispatch`.
   - Depends only on `Core` and `Logging`.
5. `InGameNotifications`
   - Optional visual notification system.
   - Provides `gmcu_show_notification`, `gmcu_InGameNotificationSettings`, and
     `gmcu_o_notification_from_top`.
   - Depends on `Core` and `Drawing`.
6. `InputHub`
   - Portable input helper with `gmcu_`-prefixed public API.
   - Provides `gmcu_o_input_hub`, `GMCU_EVENT_GAMEPAD_BUTTON_PRESSED`,
     `GMCU_EVENT_GAMEPAD_BUTTON_RELEASED`, `GMCU_DIRECTION_ANGLE`, and
     gamepad direction/button helper methods.
   - Depends on `Core`, `Logging`, `EventBus`, and `InGameNotifications`.
7. `Localization`
   - Portable CSV-backed localization helper with `gmcu_`-prefixed public API.
   - Provides `gmcu_localization_init`, `gmcu_localization_t`, and
     `GMCU_LOCALIZATION_IS_INITIALIZED`.
   - Depends on `Core` and `Logging`.
   - Translation CSV file names and content remain consumer-owned.
8. `LayeredGUI`
   - Portable priority-ordered Draw GUI manager with `gmcu_`-prefixed public
     API.
   - Provides `gmcu_o_layered_gui_manager`,
     `gmcu_layered_gui_subscribe`, and `gmcu_layered_gui_unsubscribe`.
   - Depends on `Core`, `Drawing`, and `Logging`.
9. `UniversalCursor`
   - Portable GUI cursor helper with `gmcu_`-prefixed public API.
   - Provides `gmcu_o_universal_cursor`, `gmcu_universal_cursor_show`,
     `gmcu_universal_cursor_hide`, `gmcu_universal_cursor_subscribe`, and
     `gmcu_universal_cursor_unsubscribe`.
   - Depends on `Core`, `Logging`, `Drawing`, `LayeredGUI`, and `InputHub`.
   - Cursor sprite assets remain consumer-owned.
10. `Buttons`
   - Reusable game-space and GUI-space button base objects with `gmcu_` public
     names.
   - Provides `GMCU_EVENT_BUTTON_PRESSED`, `gmcu_o_base_button`,
     `gmcu_o_base_button_game`, and `gmcu_o_base_button_gui`.
   - Depends on `Core`, `Drawing`, `Logging`, `EventBus`, `Localization`,
     `LayeredGUI`, and `UniversalCursor`.
   - Sprites, fonts, sounds, and button IDs remain consumer-owned.
11. `Labels`
   - Reusable game-space and GUI-space label objects with `gmcu_` public names.
   - Provides `gmcu_draw_text_outlined`, `gmcu_o_base_label`,
     `gmcu_o_label_game`, and `gmcu_o_label_gui`.
   - Depends on `Core`, `Drawing`, `Localization`, and `LayeredGUI`.
12. `TimedActions`
   - Provides `gmcu_o_timed_actions_manager`, `gmcu_wait_for_seconds`, and
     `gmcu_wait_for_steps`.
   - Depends on `Core` and `Logging`.
   - The manager is created lazily and persists across room changes.
13. `Transitions`
   - Provides `GMCU_TRANSITION_TO_ROOM_TYPE`,
     `GMCU_EVENT_TRANSITION_FINISHED`, `gmcu_transition_to_room`, and reusable
     fade/horizontal-curtain transition objects.
   - Depends on `Core`, `Drawing`, `Logging`, and `EventBus`.
   - Audio fades, audio stopping, and other project-specific room-change side
     effects remain consumer-owned through transition callbacks.
14. `GlobalStats.io`
   - Provides defensive leaderboard, share, and rank-section helpers.
   - Depends on `Logging` and a consumer-installed GlobalStats.io client.
   - The controller, HTTP scripts, credentials, GTD identifiers, player
     identity policy, persistence, response events, and payload schema remain
     consumer-owned.
15. `HTML5 Helpers`
   - Provides `gmcu_html5_is_mobile_device`, `gmcu_html5_block_canvas`, and
     `gmcu_html5_console_error`.
   - Preserves Fantasma's existing `PostBody` injection and
     `datafiles/disable-mobile.js` behavior without changing timing or
     presentation.
   - Consumers can omit the included file when they do not want the fixed
     mobile warning.

`gmcu_show_notification` is included in v1, but it is not a hard dependency of the
EventBus. Logging may use notifications only when the notification module is
present and enabled.

All shared resources and public APIs use `gmcu_` as the first token; macros,
enums, and constants use `GMCU_`. This includes objects such as
`gmcu_o_input_hub`. Unprefixed compatibility aliases are not provided.

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
  `InGameNotifications` if visual notifications are needed, then `InputHub`.
- Check for name conflicts before replacing existing project resources:
  `gmcu_log_debug`, `gmcu_log_info`, `gmcu_log_warn`, `gmcu_log_error`, `gmcu_log_exception`,
  `event_bus`, `gmcu_show_notification`, `gmcu_InGameNotificationSettings`, and
  `gmcu_o_notification_from_top`. New modules should use `gmcu_` first in their
  resource names to reduce collisions.
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
  - `gmcu_o_input_hub` still drives player movement, menu input, initials
    entry, and gamepad connect/disconnect notifications.
  - `gmcu_localization_init` loads the consumer `datafiles/localization.csv`
    and localized labels/buttons still render translated text.
  - `gmcu_o_universal_cursor` still drives menu hover/press behavior with
    mouse, keyboard, and gamepad input.
  - `GMCU_EVENT_BUTTON_PRESSED` still reaches menu and game controllers.
  - Localized button/label text uses the resolved translation string.
  - `gmcu_wait_for_seconds` and `gmcu_wait_for_steps` execute delayed actions.
  - Fade and horizontal-curtain transitions change rooms and preserve
    Fantasma's consumer-owned audio behavior.
  - Opening curtains still dispatch `GMCU_EVENT_TRANSITION_FINISHED`.
  - Confirm that generated build output under `Builds/` was not touched.

## Validation Checklist

- `git diff --check`
- Search shared code for consumer names, credentials, project assets, datafile
  names, build paths, and obsolete pre-extraction resource names.
- `git status --short`
- GameMaker IDE smoke test in each consumer project after import.

## Future Modules

No additional modules are currently planned. Add new candidates only after a
real consumer demonstrates a reusable boundary.
