# gamemaker-common-utils

Reusable GameMaker utilities intended to be shared across Ed Casillas
GameMaker projects.

The primary workflow is an editable Git submodule: add this repository to a
project, use the resources from inside the submodule, improve the utilities
from any consuming project, push those changes here, and pull them into other
projects later.

This repository includes a lightweight `gamemaker-common-utils.yyp` project so
GameMaker can resolve the resource files as belonging to a project when using
the IDE's import tools. Consuming games still register or import the desired
resources into their own `.yyp`.

For editable shared code, do not use GameMaker's import as the final link. The
IDE copies imported resources into the consumer project. The working live-edit
pattern is:

1. Add this repo as `vendor/gamemaker-common-utils`.
2. Keep the consumer `.yyp` pointing to normal local resource paths such as
   `scripts/event_bus/event_bus.yy`.
3. Replace each local resource folder with a symlink to the matching folder in
   `vendor/gamemaker-common-utils`.

With that setup, GameMaker still opens local-looking paths, while edits land in
the submodule.

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
6. `InputHub`
   - `scripts/gmcu_input_hub_events/gmcu_input_hub_events.yy`
   - `scripts/gmcu_gamepad_buttons_mapping/gmcu_gamepad_buttons_mapping.yy`
   - `objects/gmcu_o_input_hub/gmcu_o_input_hub.yy`
   - Centralized keyboard/gamepad direction state and gamepad button
     press/release events. New shared resources put the `gmcu_` prefix first.
7. `Localization`
   - `scripts/gmcu_localization_init/gmcu_localization_init.yy`
   - `scripts/gmcu_localization_macros/gmcu_localization_macros.yy`
   - `scripts/gmcu_localization_t/gmcu_localization_t.yy`
   - CSV-backed translation lookup with `gmcu_`-prefixed API. Translation CSV
     file names and content remain owned by the consuming project.
8. `LayeredGUI`
   - `objects/gmcu_o_layered_gui_manager/gmcu_o_layered_gui_manager.yy`
   - `scripts/gmcu_layered_gui_subscribe/gmcu_layered_gui_subscribe.yy`
   - `scripts/gmcu_layered_gui_unsubscribe/gmcu_layered_gui_unsubscribe.yy`
   - Priority-ordered Draw GUI callbacks for reusable GUI surfaces.
9. `UniversalCursor`
   - `objects/gmcu_o_universal_cursor/gmcu_o_universal_cursor.yy`
   - `scripts/gmcu_universal_cursor_show/gmcu_universal_cursor_show.yy`
   - `scripts/gmcu_universal_cursor_hide/gmcu_universal_cursor_hide.yy`
   - `scripts/gmcu_universal_cursor_subscribe/gmcu_universal_cursor_subscribe.yy`
   - `scripts/gmcu_universal_cursor_unsubscribe/gmcu_universal_cursor_unsubscribe.yy`
   - Sprite-driven GUI cursor for mouse, keyboard, and gamepad interaction.
10. `Buttons`
   - `scripts/gmcu_button_events/gmcu_button_events.yy`
   - `objects/gmcu_o_base_button/gmcu_o_base_button.yy`
   - `objects/gmcu_o_base_button_game/gmcu_o_base_button_game.yy`
   - `objects/gmcu_o_base_button_gui/gmcu_o_base_button_gui.yy`
   - Reusable localized buttons with EventBus dispatch and consumer-owned
     sprites, fonts, sounds, and IDs.
11. `Labels`
   - `scripts/gmcu_draw_text_outlined/gmcu_draw_text_outlined.yy`
   - `objects/gmcu_o_base_label/gmcu_o_base_label.yy`
   - `objects/gmcu_o_label_game/gmcu_o_label_game.yy`
   - `objects/gmcu_o_label_gui/gmcu_o_label_gui.yy`
   - Reusable localized game/GUI labels and outlined text drawing.
12. `TimedActions`
   - `objects/gmcu_o_timed_actions_manager/gmcu_o_timed_actions_manager.yy`
   - `scripts/gmcu_wait_for_seconds/gmcu_wait_for_seconds.yy`
   - `scripts/gmcu_wait_for_steps/gmcu_wait_for_steps.yy`
   - Persistent scheduling of callbacks after elapsed seconds or Step events.
13. `Transitions`
   - `scripts/gmcu_transition_events/gmcu_transition_events.yy`
   - `scripts/gmcu_transition_types/gmcu_transition_types.yy`
   - `scripts/gmcu_transition_to_room/gmcu_transition_to_room.yy`
   - `objects/gmcu_o_transition_to_room/gmcu_o_transition_to_room.yy`
   - `objects/gmcu_o_transition_fadeout_to_room/gmcu_o_transition_fadeout_to_room.yy`
   - `objects/gmcu_o_transition_hcurtain_close_to_room/gmcu_o_transition_hcurtain_close_to_room.yy`
   - `objects/gmcu_o_transition_hcurtain_open/gmcu_o_transition_hcurtain_open.yy`
   - Fade and horizontal-curtain room transitions. Audio and other
     project-specific side effects are supplied through consumer callbacks.
14. `GameAnalytics`
   - `scripts/gmcu_gameanalytics/gmcu_gameanalytics.yy`
   - Defensive facade over a consumer-installed GameAnalytics SDK.
   - The extension, SDK scripts, credentials, consent policy, and event
     taxonomy remain consumer-owned.
15. `GlobalStats.io`
   - `scripts/gmcu_globalstats/gmcu_globalstats.yy`
   - Defensive facade over a consumer-installed GlobalStats.io client.
   - The controller, HTTP client, credentials, GTD identifiers, persistence,
     response events, and payload schema remain consumer-owned.
16. `HTML5 Helpers`
   - `extensions/gmcu_html5_helpers/gmcu_html5_helpers.yy`
   - Mobile-browser detection, browser-console output, and the legacy early
     mobile warning through `datafiles/disable-mobile.js`.
   - Consumers may omit the included file if they do not want that fixed
     mobile-blocking behavior.
17. `Release and Build Info`
   - `tools/release/gmcu_release.py`
   - `scripts/gmcu_build_info/gmcu_build_info.yy`
   - `objects/gmcu_o_build_info_label/gmcu_o_build_info_label.yy`
   - Exports through `gm-cli`, serves HTML exports on localhost and the LAN,
     versions and publishes tested builds through Butler, and exposes runtime
     build information.
   - Consumer projects retain all build paths, GameMaker targets, itch.io
     destinations, platform IDs, version state, build output, and presentation
     values.

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
`vendor/gamemaker-common-utils` in the consuming project's `.yyp`, but keep the
consumer `.yyp` resource paths local. For example, use
`scripts/event_bus/event_bus.yy`, then symlink `scripts/event_bus` to
`vendor/gamemaker-common-utils/scripts/event_bus`.

If importing through the GameMaker IDE, import from inside the full checked-out
repository, not from loose copied `.yy` files. GameMaker expects a parent `.yyp`
project for the resource file. Treat this as a registration/bootstrap step:
GameMaker imports are copied, so replace the copied folder with a symlink if the
resource should remain editable through the submodule.

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
  `EventBus`, optional `InGameNotifications`, `InputHub`, `Localization`,
  `LayeredGUI`, `UniversalCursor`, `Buttons`, `Labels`, `TimedActions`, then
  `Transitions`, `GameAnalytics`, `GlobalStats.io`, `HTML5 Helpers`, and
  `Release and Build Info` if needed.
- Keep `.yyp` paths local and symlink local folders to this submodule.
- Check for name conflicts before replacing local resources.
- Run `git diff --check`.
- Open the project in GameMaker and run a smoke test.
- Report whether only source/docs changed or whether GameMaker reserialized
  `.yy`/`.yyp` files.

## Current Limits

- No `.yymps` package is generated yet.
- This repo includes a lightweight project container, not a standalone playable
  sample project.
- GameMaker IDE validation is still required after import.
- Logging is intentionally portable and does not send GameAnalytics or
  GlobalStats.io events.
- HTML5 build/export behavior still requires GameMaker IDE validation.
- Release export and deployment are intentionally separate. The tooling never
  publishes automatically after an export; the exact artifact must be tested
  and deployment must be invoked explicitly.

## Roadmap

No additional modules are currently planned for the extraction roadmap.

`.yymps` packaging is not part of the active roadmap. It creates copied import
packages rather than the editable submodule + symlink links used by current
consumers.
