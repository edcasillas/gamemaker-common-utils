# Core

`Core` provides the shared macros, runtime helpers, and notification-handler
state used by other Common Utils modules.

## Usage

Import `Core` before every other Common Utils module. Its macros and functions
become available when `scripts/gmcu_core` is registered in the consuming
project.

Use the context macros when logs or diagnostics need safe object and room
names:

```gml
show_debug_message("[" + GMCU_ROOM_NAME + ":" + GMCU_OBJECT_NAME + "] Ready");
```

Use `GMCU_DELTA_TIME_SECONDS` for elapsed-time calculations expressed in seconds:

```gml
remaining_seconds -= GMCU_DELTA_TIME_SECONDS;
```

Select the `DevBuild` GameMaker configuration when development-only behavior
should be enabled through `GMCU_IS_DEV_BUILD`. Running from the GameMaker IDE does
not enable this macro automatically.

## Resources

- `scripts/gmcu_core`: Declares the shared macros, initializes notification
  handler state, and provides safe object-name, room-name, and notification
  registration helpers.

## Dependencies

`Core` has no Common Utils module dependencies.

## API

Runtime macros:

- `GMCU_GAME_SPEED`: Current GameMaker game speed in frames per second.
- `GMCU_OBJECT_NAME`: Name of the current instance's object, or `GMCU_UNKNOWN_OBJECT`
  when the name cannot be resolved.
- `GMCU_ROOM_NAME`: Name of the current room, or `GMCU_UNKNOWN_ROOM` when the name cannot
  be resolved.
- `GMCU_UNKNOWN_OBJECT`: Fallback string returned when the current object name is
  unavailable.
- `GMCU_UNKNOWN_ROOM`: Fallback string returned when the current room name is
  unavailable.
- `GMCU_DELTA_TIME_SECONDS`: Current `delta_time` converted from microseconds to
  seconds.
- `GMCU_LAYER_DEPTH_MIN`: Minimum valid instance depth used for frontmost drawing.
- `GMCU_LAYER_DEPTH_MAX`: Maximum valid instance depth used for backmost drawing.
- `GMCU_ANY_INPUT`: Whether any keyboard key or the left mouse button was released
  this Step.
- `GMCU_INT_MAX`: Large sentinel value, `2147483648`, used to initialize numeric
  comparisons such as nearest-distance searches.

Build configuration macro:

- `GMCU_IS_DEV_BUILD`: `false` by default and `true` only when the GameMaker
  `DevBuild` configuration is selected.

Functions:

- `gmcu_get_current_object_name()`: Returns the current instance's object name,
  falling back to `GMCU_UNKNOWN_OBJECT` when called without a resolvable object
  context.
- `gmcu_get_current_room_name()`: Returns the current room name, falling back to
  `GMCU_UNKNOWN_ROOM` when it cannot be resolved.
- `gmcu_set_notification_handler(_handler)`: Registers a function used
  by [`Logging`](logging.md) to request optional visual notifications. Passing
  `undefined` removes the handler and disables notification requests.

Globals:

- `global.gmcu_notifications_enabled`: Whether a notification handler is
  currently registered.
- `global.gmcu_notification_handler`: Registered notification callback, or
  `undefined` when notifications are disabled.

## Contributing

For editable submodule use, keep this consumer `.yyp` path local:

- `scripts/gmcu_core/gmcu_core.yy`

Then symlink `scripts/gmcu_core` to the matching folder under
`vendor/gamemaker-common-utils`.
