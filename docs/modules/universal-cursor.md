# UniversalCursor

`UniversalCursor` provides a sprite-driven GUI cursor that can hover and press
registered interactable instances using mouse, keyboard, or gamepad input.

## Resources

- `objects/gmcu_o_universal_cursor`
- `scripts/gmcu_universal_cursor_show`
- `scripts/gmcu_universal_cursor_hide`
- `scripts/gmcu_universal_cursor_subscribe`
- `scripts/gmcu_universal_cursor_unsubscribe`

## Dependencies

Import after:

1. `Core`
2. `Logging`
3. `Drawing`
4. `LayeredGUI`
5. `InputHub`

`UniversalCursor` uses `GMCU_DIRECTION_ANGLE` and `gmcu_o_input_hub` for
gamepad helpers, and `LayeredGUI` for Draw GUI ordering.

## API

Object:

- `gmcu_o_universal_cursor`

Functions:

- `gmcu_universal_cursor_show(_sprite_index)`
- `gmcu_universal_cursor_hide(_restore_system_cursor = true)`
- `gmcu_universal_cursor_subscribe()`
- `gmcu_universal_cursor_unsubscribe()`

Interactable subscribers are expected to provide:

```gml
function on_hover_enter() {}
function on_hover_leave() {}
function on_pressed() {}
function on_released() {}
```

## Consumer Notes

Cursor sprites remain consumer-owned. Pass the desired cursor sprite to
`gmcu_universal_cursor_show(_sprite_index)`.

For editable submodule use, keep the consumer `.yyp` paths local and symlink
the local resource folders to `vendor/gamemaker-common-utils`.
