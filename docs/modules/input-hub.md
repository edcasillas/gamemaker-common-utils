# InputHub

`InputHub` centralizes basic keyboard and gamepad direction state, gamepad
connect/disconnect tracking, and gamepad button press/release events.

## Resources

- `scripts/gmcu_input_hub_events`
- `scripts/gmcu_gamepad_buttons_mapping`
- `objects/gmcu_o_input_hub`

## Dependencies

Import after:

1. `Core`
2. `Drawing`
3. `Logging`
4. `EventBus`
5. `InGameNotifications`

`InputHub` uses `EventBus` for button events, `Logging` for debug output, and
`InGameNotifications` for DevBuild gamepad connect/disconnect notifications.

## API

Events:

- `GMCU_EVENT_GAMEPAD_BUTTON_PRESSED`
- `GMCU_EVENT_GAMEPAD_BUTTON_RELEASED`

Direction enum:

- `GMCU_DIRECTION_ANGLE`

Object:

- `gmcu_o_input_hub`

Methods:

- `gmcu_o_input_hub.gmcu_get_direction()`
- `gmcu_o_input_hub.gmcu_get_four_way_direction()`
- `gmcu_o_input_hub.gmcu_has_connected_gamepad()`
- `gmcu_o_input_hub.gmcu_gamepad_button_pressed(_button)`
- `gmcu_o_input_hub.gmcu_gamepad_button_released(_button)`

Globals:

- `global.gmcu_gamepad_buttons_mapping`

## Consumer Notes

Place one `gmcu_o_input_hub` instance in the first room that should initialize
input. The object is persistent and deletes duplicate instances.

For editable submodule use, keep the consumer `.yyp` paths local:

- `objects/gmcu_o_input_hub/gmcu_o_input_hub.yy`
- `scripts/gmcu_input_hub_events/gmcu_input_hub_events.yy`
- `scripts/gmcu_gamepad_buttons_mapping/gmcu_gamepad_buttons_mapping.yy`

Then symlink those local folders to the matching folders under
`vendor/gamemaker-common-utils`.
