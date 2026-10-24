# Text Input

HTML5 character entry composed from Room Editor objects. The textbox owns editing
and validation; the keyboard area owns generated keys and their navigation.
The host owns labels, placement, and the business meaning of a submitted string.

## Resources and setup

Register `gmcu_o_textbox`, `gmcu_o_text_keyboard`, `gmcu_o_text_key`,
`gmcu_text_state`, `gmcu_text_input_events`, and `gmcu_text_input_html5`, together
with [Input Hub](input-hub.md), [Universal Cursor](universal-cursor.md),
[LayeredGUI](layered-gui.md), and [Event Bus](event-bus.md) and their dependencies.
Place Input Hub in the room. Place textboxes and keyboard areas using GUI-space
coordinates; their instance `x/y` is the center of their drawn rectangle.

| Object | Room Editor variables |
| --- | --- |
| Textbox | `textbox_id`, `label`, `initial_value`, `alphabet`, `case_sensitive`, `text_length`, `mask`, `wrap_caret`, `allow_delete`, `keyboard_area_id`, `keyboard_layout`, `paste_mode`, `skin`, `field_width`, `field_height`, `font`, colors |
| Keyboard area | Unique `area_id`, `area_width`, `area_height`, `skin` |

`keyboard_area_id` selects the area. Layout choices are `alphabetic` (three
centered character rows) and `qwerty` (digits plus three uppercase letter rows).
QWERTY accepts uppercase ASCII letters, digits, and optional space. Alphabetic
layout follows the supplied alphabet. A permitted space gets a wide separate key.
The host must allocate enough area for its alphabet and font.

Textboxes and keyboard areas expose independent `skin` choices (`clean` or
`retro`). These styles change the field and generated key presentation while
leaving editing state, layout, hit testing, and navigation unchanged. The retro
skin uses unboxed compact text, with distinct colors for characters and actions;
the clean skin uses filled controls. Keyboard areas also expose an optional
`custom_draw` method. The area owns key generation and input; key drawing owns
presentation. A host can assign a method to one keyboard area to provide a
custom key renderer:

```gml
keyboard_area.custom_draw = method(keyboard_area, function(_key) {
    // Draw _key using its x/y, action, hit_width, and hit_height.
});
```

The renderer receives the generated key instance and must draw within its hit
rectangle. Built-in skins handle character/action captions and hover/press
feedback. A custom renderer takes responsibility for those visual states and
must keep each key aligned with its hit target.

Textboxes expose the same `custom_draw` hook for host-specific field rendering:

```gml
textbox.custom_draw = method(textbox, function(_field) {
    // Draw _field's label, value, caret, validation, and feedback states.
});
```

The callback receives the textbox instance and owns its complete rendering.

`text_length` is the exact number of editable slots. `mask` has one `X` per slot;
other characters are visual separators. An empty mask displays unseparated slots.
Case-insensitive input maps to the character as spelled in the alphabet; ambiguous
case variants are rejected. `wrap_caret` selects wrapping versus clamped movement.

`paste_mode`: `none`, `replace_all`, or `from_caret`. Disabled paste is absent
from the keyboard and ignored by shortcuts. Copy is a host action and does not
appear in the text keyboard.

## Host contract

Subscribe before assigning the host handler:

```gml
gmcu_eventbus_subscribe(GMCU_EVENT_TEXT_SUBMITTED);
on_event = function(_event_name, _event_args) {
    switch (_event_name) {
        case GMCU_EVENT_TEXT_SUBMITTED:
            // _event_args.textbox_id identifies the field.
            // _event_args.value contains every slot, without mask separators.
            break;
    }
};
```

Unsubscribe in host cleanup. `activate()` opens editing; `finish(false)` cancels;
`finish(true)` closes and submits only when complete. Both close paths validate,
retain the draft/caret, and release focus. Invalid closed fields show an error.
The event is the host's committed-value boundary. Internal `state.slots` retains
empty positions; `state.text()` is compact text, suitable for copying but not a
lossless incomplete draft.

Physical characters and virtual keys use the same editing model. Enter/DONE
submits; Escape/CANCEL/B cancels. Physical Left/Right move the caret. D-pad moves
key focus; A activates; the stick moves Universal Cursor. Adjacent rows choose the
nearest horizontal key center, without focus wrapping. Movement and deletion
repeat after 400 ms at 80 ms intervals. Other actions require a new press.

Deleting clears the current slot without shifting, then moves backward. Paste
normalizes, filters, and truncates; an entirely rejected paste preserves the draft.
`replace_all` clears the suffix. The caret finishes after the pasted span, clamped
to the last slot. Initials can disable deletion and wrap replacement.

The textbox claims Input Hub's `text_input` focus route. Gameplay polling and
gameplay Event Bus edges are suppressed; Dev Menu keeps higher priority.
The host must use routed Input Hub APIs rather than raw keyboard/gamepad reads.
Cleanup removes cursor/draw registrations, generated keys, capture, and focus.

## HTML host and clipboard

The adapter captures browser key/copy/paste events without editable DOM elements.
It never requests the mobile OS keyboard. For a CSS-scaled canvas, configure the
existing cursor pointer-provider hook:

```gml
global.gmcu_gui_pointer_provider = function() {
    return json_parse(gmcu_text_pointer_gui(800, 600));
};
```

Use the host's GUI dimensions. Only primary canvas gestures update this pointer;
external HTML controller touches do not become outside-field clicks.

Hosts copy any string with `gmcu_text_clipboard_copy(text)`. The
`gmcu_text_input_html5` extension bundles both the GML adapter and its HTML5
clipboard bridge, so projects do not copy a host script or add a template tag.
A host can place a copy control beside any label or field and decide when that
action is enabled. Canvas hosts prepare the enabled copy value and GUI bounds
before input, then the bridge writes during the trusted canvas `pointerup` event.
When the shared HTML Virtual Controller is active, the host can also permit its
A button to copy while the copy control is under [Universal Cursor](universal-cursor.md). The bridge
then writes during the trusted DOM `pointerup` on the controller's captured
action region. The bridge records the virtual button at `pointerdown` and matches
its `pointerId` at `pointerup`, because pointer capture retargets the release to
the region. This path requires the player's touch on the virtual A button; a
physical gamepad event has no browser pointer gesture. The bridge uses a
temporary focused input and `execCommand` fallback.
`gmcu_text_clipboard_last_error()` exposes the latest bridge failure. Calling a
browser clipboard command outside the user gesture may fail.
Virtual PASTE and Ctrl/Cmd+V use the asynchronous Clipboard API. The UI
distinguishes denied or unavailable access from an empty clipboard. Browser
permissions and iframe policy can still reject clipboard access. Paste responses
are associated with the initiating field and operation token.

## Scope and limitations

- The capture adapter targets HTML5; native runners require a separate adapter.
- Textboxes do not own copy policy. Hosts should copy a field only when its value
  meets the host's requirements; the copy helper writes the exact supplied text.
- Selection copy, keyboard pages, IME composition, and emoji/grapheme editing are
  outside this implementation. Mixed case uses an explicit alphabetic layout.
- A successful desktop test does not establish mobile or physical controller
  compatibility. Verify the exact hosted artifact on the intended devices.

### Key feedback

Opening preserves the pointer position and does not select a character key.
When no key is targeted, the first D-pad direction selects the first character;
subsequent directions navigate. Mouse hover highlights the key under the cursor.
Accepted physical characters flash their normalized visible key for 150 ms,
without moving pointer or navigation focus. Rejected characters produce no flash.

Physical Left/Right and Delete/Backspace flash their visible action keys.
Ctrl/Cmd+V flashes PASTE when enabled, independently of clipboard success.
DONE/Enter/Start and CANCEL/Escape/B show a 150 ms feedback beat before
closing; further editing input is ignored during that beat. Start uses Input Hub's
active text-input route and is registered/unregistered with the textbox.
