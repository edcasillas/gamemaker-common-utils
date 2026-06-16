# Core

`Core` provides the shared macros, runtime helpers, singleton helper, and
notification-handler state used by other Common Utils modules.

## Quickstart

Import `Core` before every other Common Utils module. Its macros and functions
become available when `scripts/gmcu_core` is registered in the consuming
project.

Use the context macros when logs or diagnostics need safe object and room
names:

```gml
// Safe room/object tags for logs and diagnostics.
show_debug_message("[" + GMCU_ROOM_NAME + ":" + GMCU_OBJECT_NAME + "] Ready");
```

Use `GMCU_DELTA_TIME_SECONDS` for elapsed-time calculations expressed in seconds:

```gml
// Delta time converted to seconds.
remaining_seconds -= GMCU_DELTA_TIME_SECONDS;
```

Use `gmcu_singleton()` in a Create event when an object should remain as one
persistent shared manager:

```gml
// Destroy duplicates and keep the surviving instance persistent.
if (gmcu_singleton()) {
	return;
}
```

Select the `DevBuild` GameMaker configuration when development-only behavior
should be enabled through `GMCU_IS_DEV_BUILD`. Running from the GameMaker IDE does
not enable this macro automatically.

## Resources

- `scripts/gmcu_core`: Declares the shared macros, initializes notification
  handler state, and provides safe object-name, room-name, and notification
  registration helpers.

## Dependencies

| Module | Responsibility |
| --- | --- |
| None | `Core` is the base module used by the rest of Common Utils. |

## API

| Item | Kind | Description |
| --- | --- | --- |
| `GMCU_GAME_SPEED` | Macro | Current GameMaker game speed in frames per second. |
| `GMCU_OBJECT_NAME` | Macro | Current instance object name, or `GMCU_UNKNOWN_OBJECT` when unavailable. |
| `GMCU_ROOM_NAME` | Macro | Current room name, or `GMCU_UNKNOWN_ROOM` when unavailable. |
| `GMCU_UNKNOWN_OBJECT` | Macro | Fallback string for missing object names. |
| `GMCU_UNKNOWN_ROOM` | Macro | Fallback string for missing room names. |
| `GMCU_DELTA_TIME_SECONDS` | Macro | Current `delta_time` converted from microseconds to seconds. |
| `GMCU_LAYER_DEPTH_MIN` | Macro | Minimum valid instance depth used for frontmost drawing. |
| `GMCU_LAYER_DEPTH_MAX` | Macro | Maximum valid instance depth used for backmost drawing. |
| `GMCU_GUI_PRIORITY_DEFAULT` | Macro | Shared default LayeredGUI priority. |
| `GMCU_GUI_PRIORITY_LEADERBOARD_OVERLAY` | Macro | Shared leaderboard overlay LayeredGUI priority. |
| `GMCU_GUI_PRIORITY_UNIVERSAL_CURSOR` | Macro | Shared universal cursor LayeredGUI priority. |
| `GMCU_GUI_PRIORITY_TRANSITION_OVERLAY` | Macro | Shared transition overlay LayeredGUI priority. |
| `GMCU_GUI_PRIORITY_DEV_MENU` | Macro | Shared Dev Menu LayeredGUI priority. |
| `GMCU_ANY_INPUT` | Macro | Whether any keyboard key or the left mouse button was released this Step. |
| `GMCU_INT_MAX` | Macro | Large sentinel value used to initialize numeric comparisons. |
| `GMCU_IS_DEV_BUILD` | Macro | `true` only when the GameMaker `DevBuild` configuration is selected. |
| `gmcu_get_current_object_name()` | Function | Returns the current instance object name with a safe fallback. |
| `gmcu_get_current_room_name()` | Function | Returns the current room name with a safe fallback. |
| `gmcu_singleton()` | Function | Destroys later duplicates of the current object and marks the surviving instance as persistent. |
| `gmcu_set_notification_handler(_handler)` | Function | Registers or clears the optional visual notification handler used by [`Logging`](logging.md). |
| `global.gmcu_notifications_enabled` | Global | Whether a notification handler is currently registered. |
| `global.gmcu_notification_handler` | Global | Registered notification callback, or `undefined` when disabled. |

## Contributing

For editable submodule use, keep this consumer `.yyp` path local:

- `scripts/gmcu_core/gmcu_core.yy`

Then symlink `scripts/gmcu_core` to the matching folder under
`vendor/gamemaker-common-utils`.
