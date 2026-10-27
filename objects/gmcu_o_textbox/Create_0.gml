state = new gmcu_TextState(alphabet, text_length, case_sensitive, wrap_caret, initial_value); // Fixed-position text and caret state.

editing = false;			// True while this textbox owns the active editing session.
touched = false;			// True after the field closes at least once; enables validation feedback.
hovered = false;			// Universal Cursor hover state for the field.
pressed = false;			// Pointer press state used by the interactable control.
feedback = "";				// Current status or clipboard feedback shown below the field.
pending_close = -1;			// Pending close result: -1 none, 0 cancel, 1 submit.
close_due = 0;				// Time when the DONE/CANCEL feedback beat ends.
area = noone;				// Keyboard area assigned while this textbox is being edited.
area_count = 0;				// Number of keyboard areas matching this textbox during activation.
is_interactable = true;		// Lets Universal Cursor target this textbox.
hit_width = field_width;	// Universal Cursor hitbox width, matching the drawn field.
hit_height = field_height;	// Universal Cursor hitbox height, matching the drawn field.
custom_draw = noone;		// Optional host-provided field renderer; noone uses the built-in skin.
repeat_key = "";			// Physical key currently repeating, or empty when released.
repeat_due = 0;				// Next repeat time for held arrow/delete keys.
opened_at = -1;				// Time editing opened; ignores input from the opening press.
clipboard_token = 0;		// Clipboard request ID; rejects responses from older requests.
inputs_registered = false; // Set after registering B/Start; Clean Up skips unregistering them if Create exited before registration.
diagnostic_id = "textbox_id=" + string(textbox_id) + ", instance=" + string(id); // Stable field label and runtime instance for errors.

// gmcu_TextState validates the alphabet, length, and initial value in its constructor.
// An error means its slots do not represent the requested field, so do not register input or draw it.
if (state.config_error != "") {
    gmcu_log_error(diagnostic_id + ": " + state.config_error);
    instance_destroy();
    return;
}

// textbox_id identifies submit events; keyboard_area_id identifies the area that renders keys.
// Without either ID, this instance cannot connect those interactions to the right host or keyboard.
if (textbox_id == "" || keyboard_area_id == "") {
    gmcu_log_error(diagnostic_id + ": textbox_id and keyboard_area_id are required");
    instance_destroy();
    return;
}

// Each X in the mask reads one state slot while drawing. A different count would
// skip saved characters or read beyond the slot array.
if (mask != "" && string_count("X", mask) != text_length) {
    gmcu_log_error(diagnostic_id + ": mask must have one X per position");
    instance_destroy();
    return;
}

// The keyboard builder implements only these two layouts. An unknown value would
// silently enter its alphabetic branch, hiding a Room Editor configuration error.
if (keyboard_layout != "alphabetic" && keyboard_layout != "qwerty") {
    gmcu_log_error(diagnostic_id + ": unsupported keyboard_layout=" + string(keyboard_layout));
    instance_destroy();
    return;
}

// The QWERTY keyboard has fixed key rows. Check the supplied alphabet so every
// accepted character also has a key the player can select.
if (keyboard_layout == "qwerty") {
    // Position of the alphabet character being checked.
    for (var i=1; i<=string_length(alphabet); i++) {
        if (string_pos(string_char_at(alphabet, i), "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ") == 0) {
            gmcu_log_error(diagnostic_id + ": QWERTY layout supports uppercase ASCII letters, digits and space");
            instance_destroy();
            return;
        }
    }
}

gmcu_register_gamepad_button(gp_face2); // B button will cancel
gmcu_register_gamepad_button(gp_start);	// Start button will submit
inputs_registered = true;
gmcu_universal_cursor_subscribe(textbox_id);
gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEFAULT, textbox_id);

/** Activate this field and its configured keyboard area. */
function activate() {
    if (editing) return;

    // Physical typing is captured by the HTML5 extension. A native runner cannot
    // start that capture, so this field must not take focus there.
    if (os_browser == browser_not_a_browser) {
        gmcu_log_error(diagnostic_id + ": HTML5 browser runtime is required");
        instance_destroy();
        return;
    }

    // Match the Room Editor's keyboard_area_id against the placed keyboard areas.
    area = noone;
    area_count = 0;
    with (gmcu_o_text_keyboard) if (area_id == other.keyboard_area_id) {
        other.area_count++;
        other.area = id;
    }

    // The textbox sends actions to area.open() after taking focus. Zero matches
    // leaves no receiver; multiple matches make the chosen receiver ambiguous.
    if (area_count != 1) {
        gmcu_log_error(diagnostic_id + ": expected exactly one keyboard area with area_id=" + string(keyboard_area_id) + "; found " + string(area_count));
        instance_destroy();
        return;
    }

    if (instance_exists(global.gmcu_active_textbox)) global.gmcu_active_textbox.finish(false, false);
    editing = true;
    global.gmcu_active_textbox = id;
    opened_at = current_time;
    pending_close = -1;
    feedback = "";
    repeat_key = 0;
    keyboard_string = "";
    gmcu_text_capture_begin();
    // Shared Universal Cursor instance.
    var cursor = gmcu_o_universal_cursor;
    cursor.text_input_owner = id;
    gmcu_o_input_hub.focus_owner = id;
    gmcu_o_input_hub.focus_route = "text_input";
    area.open(id);
}

/** Close editing and dispatch a complete value only when requested.
 * @param {Bool} _submit Whether to submit a valid value.
 * @param {Bool} _restore_cursor Whether to return the cursor to this field.
 */
function finish(_submit, _restore_cursor = true) {
    if (!editing) return;
    editing = false;
    touched = true;
    repeat_key = 0;
    clipboard_token++;
    gmcu_text_capture_end();
    if (instance_exists(area)) area.close();
    if (instance_exists(gmcu_o_universal_cursor)) {
        gmcu_o_universal_cursor.text_input_owner = noone;
        if (_restore_cursor) {
            gmcu_o_universal_cursor.gui_x = x;
            gmcu_o_universal_cursor.gui_y = y;
        }
    }

    if (instance_exists(gmcu_o_input_hub) && gmcu_o_input_hub.focus_owner == id) gmcu_o_input_hub.focus_owner=noone;
    global.gmcu_active_textbox = noone;
    if (_submit && state.valid()) gmcu_eventbus_dispatch(GMCU_EVENT_TEXT_SUBMITTED, { textbox_id: textbox_id, value: state.text() });
}

/** Return the field's displayed formatting with empty slots omitted. */
function formatted_value() {
    if (mask == "") return state.text();
    var result = ""; // Formatted text assembled from the mask.
    var slot = 0; // Editable position represented by the next X.
    // Index for this sequence.
    for (var i = 1; i <= string_length(mask); i++) {
        // Character or key at the current position.
        var c = string_char_at(mask, i);
        if (c == "X") {
            result += state.slots[slot];
            slot++;
        } else {
            result += c;
        }
    }

    return result;
}

/** Apply one editing action or an accepted literal character. */
function edit_action(_action) {
    if (!editing || pending_close != -1) return;
    area.flash_key(_action);
    switch (_action) {
        case "SPACE": state.type(" "); break;
        case "LEFT": state.move(-1); break;
        case "RIGHT": state.move(1); break;
        case "DEL": if (allow_delete) state.erase(); break;
        case "DONE":
        case "CANCEL":
            // Keep the pressed key visible for its feedback beat before closing.
            pending_close = (_action == "DONE");
            close_due = current_time + 150;
            break;
        case "PASTE":
            if (paste_mode != "none") {
                clipboard_token++;
                gmcu_text_clipboard("paste", "", string(id), clipboard_token);
            }

            break;
        default: state.type(_action); break;
    }
}

/** Receive pointer/controller focus. */
function on_hover_enter() { hovered = true; }

/** Release pointer/controller focus. */
function on_hover_leave() {
    hovered = false;
    pressed = false;
}

/** Open editing on activation; the opening release cannot enter a character. */
function on_pressed() { activate(); }

/** Opening a field consumes its press, so release has no editing action. */
function on_released() { }

/** Draw the field, persistent mask, editing blink, and closed-field validation. */
function on_draw_gui() {
    if (custom_draw != noone) {
        method_call(custom_draw, [id]);
        return;
    }

    // Drawing parameters restored after rendering.
    var saved = new gmcu_DrawingParameters();
    if (font != noone && font_exists(font)) draw_set_font(font);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_middle);
    var left = x - field_width / 2; // Left edge of the drawn field.
    var top = y - field_height / 2; // Top edge of the drawn field.
    // Whether the closed field lacks required characters.
    var invalid = touched && !editing && !state.valid();
    if (skin == "retro") {
        draw_set_halign(fa_center);
        draw_set_color(text_color); draw_text_transformed(x, top - 20, string_upper(label), 0.6, 0.6, 0);
        // Displayed mask for all editable positions.
        var pattern = mask == "" ? string_repeat("X", text_length) : mask;
        // Horizontal distance between displayed glyphs.
        var advance = min(12, (field_width - 24) / string_length(pattern));
        var origin = x - string_length(pattern) * advance / 2; // First retro glyph center.
        var slot = 0; // Editable position within the mask.
        // Whether the active caret is in its visible phase.
        var blink = (current_time div 400) mod 2 == 0;
        // Index for this sequence.
        for (var i = 1; i <= string_length(pattern); i++) {
            var c = string_char_at(pattern, i); // Glyph shown at this mask position.
            var color = make_color_rgb(28, 88, 202); // Color of this retro glyph.
            if (c == "X") {
                // Whether this editable position contains a character.
                var filled = state.slots[slot] != "";
                c = filled ? state.slots[slot] : "X";
                color = filled ? make_color_rgb(44, 255, 92) : make_color_rgb(28, 88, 202);
                if (editing && slot == state.caret && blink) {
                    c = filled ? "" : "_";
                    color = c_white;
                }

                slot++;
            }

            draw_set_color(color); draw_text_transformed(origin + (i - 1) * advance, y, c, 0.6, 0.6, 0);
        }

        draw_set_halign(fa_left);
        if (invalid) {
            draw_set_color(c_red);
            draw_text_transformed(x, top + field_height + 18, string_upper(string(text_length) + " characters required"), 0.6, 0.6, 0);
        } else if (feedback != "") {
            draw_set_color(make_color_rgb(44,255,92));
            draw_text_transformed(x, top + field_height + 18, string_upper(feedback), 0.6, 0.6, 0);
        }

        saved.apply(); return;
    }

    draw_set_color(background_color); draw_rectangle(left, top, left + field_width, top + field_height, false);
    draw_set_color(invalid ? c_red : (editing || hovered ? accent_color : c_gray));
    draw_rectangle(left, top, left + field_width, top + field_height, true);
    draw_set_color(text_color); draw_text(left, top - 19, label);
    // Displayed mask for all editable positions.
    var pattern = mask == "" ? string_repeat("X", text_length) : mask;
    // Horizontal distance between displayed glyphs.
    var advance = min(25, (field_width - 24) / string_length(pattern));
    var origin = x - string_length(pattern) * advance / 2; // First clean-skin glyph center.
    var slot = 0; // Editable position within the mask.
    // Whether the active caret is in its visible phase.
    var blink = (current_time div 400) mod 2 == 0;
    // Index for this sequence.
    for (var i = 1; i <= string_length(pattern); i++) {
        var c = string_char_at(pattern, i); // Glyph shown at this mask position.
        var color = placeholder_color; // Color of this clean-skin glyph.
        if (c == "X") {
            // Whether this editable position contains a character.
            var filled = state.slots[slot] != "";
            c = filled ? state.slots[slot] : "X";
            color = filled ? text_color : placeholder_color;
            if (editing && slot == state.caret && blink) {
                c = filled ? "" : "_";
                color = text_color;
            }

            slot++;
        }

        draw_set_color(color); draw_text(origin + (i - 1) * advance, y, c);
    }

    if (invalid) {
        draw_set_color(c_red);
        draw_text(left, top + field_height + 18, string(text_length) + " characters required");
    } else if (feedback != "") {
        draw_set_color(text_color);
        draw_text(left, top + field_height + 18, feedback);
    }

    saved.apply();
}

/** Limit active editing to text fields and keys, excluding unrelated host controls. */
function accepts_cursor_target(_target) {
    return _target.object_index == gmcu_o_textbox || _target.object_index == gmcu_o_text_key;
}
