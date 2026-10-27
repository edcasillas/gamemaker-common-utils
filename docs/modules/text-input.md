# Text Input

Use `gmcu_o_textbox` for editable text and `gmcu_o_text_keyboard` for its on-screen
keyboard. The host places and labels fields, handles submitted values, and decides
when clipboard actions are available.

## Add it to a room

1. Register the Text Input resources in the consumer `.yyp`:
   - Objects: `gmcu_o_textbox`, `gmcu_o_text_keyboard`, `gmcu_o_text_key`.
   - Scripts: `gmcu_text_state`, `gmcu_text_input_events`,
     `gmcu_text_clipboard_copy`.
   - Extension: `gmcu_text_input_html5`.
2. Register the module dependencies: [Input Hub](input-hub.md),
   [Universal Cursor](universal-cursor.md), [Layered GUI](layered-gui.md),
   [Event Bus](event-bus.md), and [Logging](logging.md).
3. Place the dependency managers required by those modules in the room. At
   minimum, Text Input needs `gmcu_o_input_hub`,
   `gmcu_o_universal_cursor`, and `gmcu_o_layered_gui_manager`.
4. Place one `gmcu_o_text_keyboard` for each keyboard location. Give each a
   unique `area_id`, set its size, and position it in GUI coordinates. Its `x/y`
   is the center of the key area.
5. Place each `gmcu_o_textbox`. Set a unique `textbox_id`, its keyboard's
   `keyboard_area_id`, and the field options below. Its `x/y` is the center of
   the field. Do not place `gmcu_o_text_key`; the keyboard creates keys while
   editing.
6. Add a host controller that subscribes to submitted values (example below).
   Build for HTML5 with the registered extension enabled.

## Configuration checks

At creation, the textbox checks:

- a nonempty alphabet without duplicate characters (including case-equivalent
  characters when case-insensitive), a positive integer length, and an initial
  string that fits and uses only allowed characters;
- `textbox_id` and `keyboard_area_id`, one `X` per editable mask position, and
  `keyboard_layout` set to `alphabetic` or `qwerty`;
- QWERTY characters limited to uppercase A–Z, 0–9, and space. Alphabetic keys
  are generated from the supplied alphabet, so they need no fixed character set.

When editing opens, it checks for an HTML5 browser runtime and exactly one
keyboard area with the requested `area_id`. A failed check logs the room, object,
`textbox_id`, runtime instance ID, and reason, then removes the textbox before
it takes input focus. `gmcu_log_error()` requests a visual notification in
DevBuild when the host has registered a notification handler. Direct callers of
`gmcu_TextState` inspect its `config_error` field.

## Room Editor variables

Set these on each `gmcu_o_textbox` instance:

| Variable | Purpose |
| --- | --- |
| `textbox_id` | Unique host-facing field ID; included in submit events. |
| `label` | Label drawn above the field. |
| `initial_value` | Starting text; omitted characters leave empty slots. |
| `alphabet` | Accepted characters. QWERTY accepts uppercase A–Z, digits, and optional space. |
| `text_length` | Exact number of editable positions. |
| `keyboard_area_id` | `area_id` of the keyboard area used by this field. |
| `keyboard_layout` | `alphabetic` or `qwerty`. Alphabetic arranges the supplied alphabet in three rows. |

Optional textbox variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `case_sensitive` | `true` | If false, normalize case using the alphabet. |
| `mask` | empty | Display pattern with one `X` per position; other characters are separators. |
| `wrap_caret` | `false` | Wrap caret movement at either end. |
| `allow_delete` | `true` | Show and enable `DEL`. Deletion leaves an empty slot. |
| `paste_mode` | `none` | `none`, `replace_all`, or `from_caret`. |
| `skin` | `clean` | `clean` or `retro`; independent of keyboard skin. |
| `field_width`, `field_height` | `620`, `54` | Draw and hit-target size in GUI pixels. |
| `font` | empty | Font asset used by the field and its generated keys. |
| `text_color`, `placeholder_color`, `background_color`, `accent_color` | built-in colors | Clean-skin colors. |

Set these on each `gmcu_o_text_keyboard` instance:

| Variable | Default | Purpose |
| --- | --- | --- |
| `area_id` | empty | Unique ID referenced by textbox instances. |
| `area_width`, `area_height` | `760`, `290` | Keyboard layout bounds in GUI pixels. |
| `skin` | `clean` | `clean` or `retro`. |

Set textbox and keyboard positions/sizes for the room's GUI dimensions. A space
in `alphabet` creates a wide `SPACE` key. The action row contains `LEFT`,
`RIGHT`, optional `DEL` and `PASTE`, then `CANCEL` and `DONE`.

## Handle submitted text

Subscribe before assigning the host's `on_event` handler:

```gml
gmcu_eventbus_subscribe(GMCU_EVENT_TEXT_SUBMITTED);
on_event = function(_event_name, _event_args) {
    switch (_event_name) {
        case GMCU_EVENT_TEXT_SUBMITTED:
            switch (_event_args.textbox_id) {
                case "password":
                    // _event_args.value is complete text without mask separators.
                    break;
            }
            break;
    }
};
```

Unsubscribe when the host is destroyed. Textboxes also expose `activate()` and
`finish(_submit)`. `finish(false)` cancels and keeps the draft; `finish(true)`
submits only when every slot is valid. Closed incomplete fields show validation.
The submit event is the host's committed-value boundary. `state.slots` preserves
empty positions; `state.text()` omits them and is not a lossless draft format.

## Input and clipboard

- Keyboard characters enter accepted characters directly; physical arrows move
  the caret. Enter/START submit; Escape/B cancel. Virtual directions navigate
  keys, A activates, and the stick moves Universal Cursor.
- Clicking or tapping a field opens its keyboard. Tapping outside closes it and
  keeps the draft. The module captures browser keyboard input without opening
  the mobile OS keyboard.
- `gmcu_text_clipboard_copy(text)` copies host-provided text. Keep the host's
  copy button separate from the keyboard and enable it only when the host's
  validation passes.
- HTML5 clipboard writes require a trusted browser gesture. Canvas taps copy
  synchronously on pointer release. For virtual-controller A, the extension
  matches the pressed button's `pointerId` across pointer capture and copies
  synchronously on that trusted release. Gamepad polling cannot substitute for
  a browser pointer gesture.
- Paste uses the Clipboard API and may be denied by browser permissions or
  iframe policy. `gmcu_text_clipboard_last_error()` returns the latest failure.

For custom presentation, assign a bound method to `custom_draw` on a textbox or
keyboard area; its argument is the field or key instance and it owns that
element's drawing. The built-in `clean` and `retro` skins provide defaults.

## Scope

The capture adapter targets HTML5. Selection copy, IME composition, keyboard
pages, and emoji/grapheme editing are not supported. Test the exported artifact
on intended browsers and devices; desktop or mocked tests do not establish
mobile clipboard support.
