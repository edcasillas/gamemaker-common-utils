# UniversalCursor

`UniversalCursor` provides a sprite-driven GUI cursor that can hover and press
registered interactable instances using mouse, keyboard, or gamepad input.

## Usage

Show the cursor with a consumer-owned sprite and subscribe interactable
instances during Create.

## Resources

- `objects/gmcu_o_universal_cursor`
- `scripts/gmcu_universal_cursor_show`
- `scripts/gmcu_universal_cursor_hide`
- `scripts/gmcu_universal_cursor_subscribe`
- `scripts/gmcu_universal_cursor_unsubscribe`

## Dependencies

- [`InputHub`](input-hub.md): Supplies directional navigation and gamepad
  helpers.
- [`LayeredGUI`](layered-gui.md): Orders cursor drawing.
- [`Drawing`](drawing.md): Protects draw state.
- [`Logging`](logging.md): Reports invalid subscribers.
- [`Core`](core.md)

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

## Contributing

Cursor sprites remain consumer-owned. Pass the desired cursor sprite to
`gmcu_universal_cursor_show(_sprite_index)`.

For editable submodule use, keep the consumer `.yyp` paths local and symlink
the local resource folders to `vendor/gamemaker-common-utils`.
