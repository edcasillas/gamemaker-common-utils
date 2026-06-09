# UniversalCursor

`UniversalCursor` gives GUI controls one interaction path for mouse, keyboard,
and gamepad input. Instead of implementing separate Mouse events, keyboard
selection, and gamepad focus in every control, an instance subscribes once and
handles four callbacks:

```gml
on_hover_enter
on_hover_leave
on_pressed
on_released
```

Use it for menus and other sprite-based interfaces that should behave
consistently across input devices. It is unnecessary for mouse-only controls,
native GameMaker UI layers, or interfaces whose focus and hit-testing rules do
not match the cursor behavior described below.

## How It Works

The persistent cursor singleton owns:

- A GUI-space cursor position and consumer-provided sprite.
- A list of interactable instances.
- The currently hovered instance.
- Mouse, arrow-key, D-pad, analog-stick, Enter, and gamepad confirmation input.

Mouse movement places the universal cursor at the system pointer. Arrow keys
and the D-pad move it to a nearby subscriber in the requested direction. The
left analog stick moves it freely. Left click, Enter, and the first gamepad
face button call the same press and release callbacks.

The system cursor is hidden while the universal cursor is shown. Its sprite is
drawn through [`LayeredGUI`](layered-gui.md) at priority `-1000`.

## Basic Setup

Show the cursor when entering an interface and pass a consumer-owned sprite:

```gml
// Menu controller Create
gmcu_universal_cursor_show(spr_cursor);
```

Hide it when leaving the interface:

```gml
gmcu_universal_cursor_hide();
```

`gmcu_universal_cursor_hide()` restores the default system cursor unless
`false` is passed. Hiding does not destroy the singleton or remove subscribers.

## Creating An Interactable

Subscribe from Create after the instance is initialized:

```gml
gmcu_universal_cursor_subscribe("play_button");

function on_hover_enter() {
	image_index = 1;
}

function on_hover_leave() {
	image_index = 0;
}

function on_pressed() {
	image_xscale = 0.95;
	image_yscale = 0.95;
}

function on_released() {
	image_xscale = 1;
	image_yscale = 1;
	do_menu_action();
}
```

Unsubscribe from Clean Up:

```gml
gmcu_universal_cursor_unsubscribe();
```

Every subscriber must provide all four callbacks. Callback exceptions and
destroyed subscribers are logged, but error recovery is not a replacement for
unsubscribing correctly.

Common Utils GUI buttons already implement this contract and subscribe through
`gmcu_o_base_button_gui`. Child button objects normally configure or override
button behavior instead of subscribing a second time.

The optional subscription argument is a diagnostic name. GameMaker does not
expose Room Editor instance names from runtime ids, so pass an existing stable
identifier when several subscribers share an object. Common Utils buttons pass
their `button_id` automatically.

## Dev Menu Diagnostics

When [`Dev Menu`](dev-menu.md) is also imported, its root page automatically
adds `Universal Cursor` while the cursor singleton exists. The page lists each
subscriber as:

```text
hover marker | object name | diagnostic name | instance id
```

`*` marks the subscriber that was hovered when the menu opened. The snapshot
is taken before the modal menu deactivates gameplay instances. Select a row and
press Enter, the gamepad confirmation button, or click it to copy the complete
row to the clipboard. No consumer configuration is required.

## Position And Hit Testing

The cursor treats each subscriber as a rectangle centered on:

```gml
subscriber.x
subscriber.y
```

The rectangle uses `sprite_width` and `sprite_height`. Directional navigation
also compares subscriber `x` and `y` positions. This works directly for
sprite-based GUI instances whose room coordinates match their Draw GUI
coordinates.

Do not use the default implementation unchanged when:

- The control draws somewhere other than its `x` and `y`.
- Its interactive area differs from its sprite dimensions.
- GUI scaling or camera transforms make room and GUI coordinates differ.
- The control has no suitable sprite.
- Navigation needs explicit neighbors, wrapping, disabled-item filtering, or
  overlapping-control precedence.

The cursor does not inspect a variable such as `is_interactable`. Subscribers
own that policy inside their callbacks, or must unsubscribe while disabled.
Common Utils buttons keep their callbacks registered and ignore interaction
when their `is_interactable` property is false.

## Lifecycle

`gmcu_universal_cursor_show()` and `gmcu_universal_cursor_subscribe()` both
create the singleton when necessary. The singleton persists across rooms and
deletes accidental duplicate manager instances.

Use these operations for different responsibilities:

- `show`: Select the cursor sprite, make it visible, process input, and hide the
  system cursor.
- `hide`: Stop cursor input and drawing, optionally restoring the system cursor.
- `subscribe`: Add an interactable instance.
- `unsubscribe`: Remove an interactable instance before destruction.

Because the manager persists, room-owned interactables must unsubscribe in
Clean Up. A menu controller should explicitly show or hide the cursor when
changing between cursor-driven UI and gameplay.

## Resources

- `objects/gmcu_o_universal_cursor`: Persistent input, navigation, hover,
  callback, and drawing manager.
- `scripts/gmcu_universal_cursor_show`: Creates or reveals the cursor and
  selects its sprite.
- `scripts/gmcu_universal_cursor_hide`: Hides the cursor and optionally restores
  the system cursor.
- `scripts/gmcu_universal_cursor_subscribe`: Registers the calling instance as
  an interactable.
- `scripts/gmcu_universal_cursor_unsubscribe`: Removes the calling instance.

## Dependencies

- [`InputHub`](input-hub.md): Supplies connected-gamepad and button helpers.
  - [`Core`](core.md)
- [`LayeredGUI`](layered-gui.md): Draws the cursor in the shared GUI order.
  - [`Drawing`](drawing.md)
    - [`Core`](core.md)
  - [`Logging`](logging.md)
    - [`Core`](core.md)
- [`Logging`](logging.md): Reports duplicate managers, invalid subscribers, and
  callback failures.
  - [`Core`](core.md)
- [`Core`](core.md): Supplies direction constants and shared limits.

## API

- `gmcu_universal_cursor_show(_sprite_index)`: Shows the universal cursor using
  the supplied sprite and hides the system cursor.
- `gmcu_universal_cursor_hide(_restore_system_cursor = true)`: Hides the
  universal cursor and optionally restores the default system cursor.
- `gmcu_universal_cursor_subscribe(_diagnostic_name = undefined)`: Registers
  `self` for hover, navigation, and activation. The optional name appears only
  in diagnostics.
- `gmcu_universal_cursor_unsubscribe()`: Removes `self` when registered.

Subscriber callbacks take no parameters and return no value:

```gml
function on_hover_enter() {}
function on_hover_leave() {}
function on_pressed() {}
function on_released() {}
```

## Consumer Ownership

Cursor sprites, menu actions, disabled-state policy, sounds, visual feedback,
and room transition policy remain in the consuming project.

For editable submodule use, keep the consumer `.yyp` paths local and symlink
the local resource folders to `vendor/gamemaker-common-utils`.
