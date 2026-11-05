state = new gmcu_TextState(alphabet, text_length, case_sensitive, wrap_caret, initial_value); // Fixed-position text and caret state.

editing = false;			// True while this textbox owns the active editing session.
touched = false;			// True after the field closes at least once; enables validation feedback.
hovered = false;			// Universal Cursor hover state for the field.
feedback = "";				// Current status or clipboard feedback shown below the field.
last_status = undefined;	// Last published validation and feedback state; avoids duplicate events.
pending_close = -1;			// Pending close result: -1 none, 0 cancel, 1 submit.
close_due = 0;				// Time when the DONE/CANCEL feedback beat ends.
keyboard_area = noone;		// Keyboard object that renders keys and receives editing actions.
is_interactable = true;		// Lets Universal Cursor target this textbox.
hit_width = 0;				// Updated from the assigned sprite width and Room Editor scale.
hit_height = 0;				// Updated from the assigned sprite height and Room Editor scale.
repeat_key = "";			// Physical key currently repeating, or empty when released.
repeat_due = 0;				// Next repeat time for held arrow/delete keys.
opened_at = -1;				// Time editing opened; ignores input from the opening press.
clipboard_token = 0;		// Clipboard request ID; rejects responses from older requests.
inputs_registered = false;	// Set after registering B/Start; Clean Up skips unregistering them if Create exited before registration.

/** Log an error with this field's ID.
 * @param {Any} _message Error detail.
 */
function log_error(_message) { gmcu_log_error("textbox_id=" + string(textbox_id) + ": " + string(_message)); }

// Require a visible Room Editor sprite.
if (sprite_index == noone) {
    log_error("assign a sprite to the textbox object");
    instance_destroy();
    return;
}

// Require a centered sprite origin for drawing and hit detection.
if (sprite_get_xoffset(sprite_index) != floor(sprite_get_width(sprite_index) / 2) || sprite_get_yoffset(sprite_index) != floor(sprite_get_height(sprite_index) / 2)) {
    log_error("textbox sprite origin must be centered");
    instance_destroy();
    return;
}

image_speed = 0;
hit_width = sprite_get_width(sprite_index) * abs(image_xscale);
hit_height = sprite_get_height(sprite_index) * abs(image_yscale);

// Reject invalid text-state configuration.
if (state.config_error != "") {
    log_error(state.config_error);
    instance_destroy();
    return;
}

// Require IDs for host events and keyboard wiring.
if (textbox_id == "" || keyboard_area_id == "") {
    log_error("textbox_id and keyboard_area_id are required");
    instance_destroy();
    return;
}

// Require one mask X per text position.
if (mask != "" && string_count("X", mask) != text_length) {
    log_error("mask must have one X per position");
    instance_destroy();
    return;
}

// Require a supported keyboard layout.
if (keyboard_layout != "alphabetic" && keyboard_layout != "qwerty") {
    log_error("unsupported keyboard_layout=" + string(keyboard_layout));
    instance_destroy();
    return;
}

// Require every QWERTY character to have a visible key.
if (keyboard_layout == "qwerty") {
    for (var alphabet_index = 1; alphabet_index <= string_length(alphabet); alphabet_index++) {
        var character = string_char_at(alphabet, alphabet_index); // Character that needs a selectable QWERTY key.
        if (string_pos(character, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ") == 0) {
            log_error("QWERTY layout supports uppercase ASCII letters, digits and space");
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
    if (editing) {
        return;
    }

    // Require one matching keyboard area.
    var resolved_keyboard = gmcu_text_resolve_keyboard_area(keyboard_area_id); // Unique keyboard object, or noone on configuration error.
    if (resolved_keyboard == noone) {
        instance_destroy();
        return;
    }

    keyboard_area = resolved_keyboard;

    if (instance_exists(global.gmcu_active_textbox)) {
        global.gmcu_active_textbox.finish(false, false);
    }

    editing = true;
    global.gmcu_active_textbox = id;
    opened_at = current_time;
    pending_close = -1;
    feedback = "";
    repeat_key = "";
    
    keyboard_string = "";	// Native GameMaker input uses keyboard_string; clear text typed before this field took focus.

    // Capture browser input without opening the mobile keyboard.
    if (os_browser != browser_not_a_browser) {
        gmcu_text_capture_begin();
    }

    // Limit cursor targets to this editing session.
    gmcu_o_universal_cursor.text_input_owner = id;

    // Route gamepad input to this field.
    gmcu_o_input_hub.focus_owner = id;
    gmcu_o_input_hub.focus_route = "text_input";

    // Open this field's keyboard.
    keyboard_area.open(id);
}

/** Close editing and dispatch a complete value only when requested.
 * @param {Bool} _submit Whether to submit a valid value.
 * @param {Bool} _restore_cursor Whether to return the cursor to this field.
 */
function finish(_submit, _restore_cursor = true) {
    if (!editing) {
        return;
    }

    editing = false;
    touched = true;
    repeat_key = "";
    clipboard_token++;
	
    if (os_browser != browser_not_a_browser) {
        gmcu_text_capture_end();
    } else {
        keyboard_string = "";
    }

    if (instance_exists(keyboard_area)) {
        keyboard_area.close();
    }

    if (instance_exists(gmcu_o_universal_cursor)) {
        gmcu_o_universal_cursor.text_input_owner = noone;
        if (_restore_cursor) {
            gmcu_o_universal_cursor.gui_x = x;
            gmcu_o_universal_cursor.gui_y = y;
        }
    }

    if (instance_exists(gmcu_o_input_hub) && gmcu_o_input_hub.focus_owner == id) {
        gmcu_o_input_hub.focus_owner = noone;
    }

    global.gmcu_active_textbox = noone;
    if (_submit && state.valid()) {
        gmcu_eventbus_dispatch(GMCU_EVENT_TEXT_SUBMITTED, { textbox_id: textbox_id, value: state.text() });
    }
}

/** Return the field's displayed formatting with empty slots omitted. */
function formatted_value() {
    if (mask == "") {
        return state.text();
    }

    var result = ""; // Formatted text assembled from the mask.
    var slot = 0; // Editable position represented by the next X.
    for (var mask_position = 1; mask_position <= string_length(mask); mask_position++) {
        var mask_character = string_char_at(mask, mask_position); // Placeholder or separator at this position.
        if (mask_character == "X") {
            result += state.slots[slot];
            slot++;
        } else {
            result += mask_character;
        }
    }

    return result;
}

/** Apply one virtual key action to the active field.
 * @param {String} _action Character or editing action name.
 */
function edit_action(_action) {
    if (!editing || pending_close != -1) {
        return;
    }

    keyboard_area.flash_key(_action);
    switch (_action) {
        case "SPACE":
            state.type(" ");
            break;
        case "LEFT":
            state.move(-1);
            break;
        case "RIGHT":
            state.move(1);
            break;
        case "DEL":
            if (allow_delete) {
                state.erase();
            }

            break;
        case "DONE":
        case "CANCEL":
            // Show press feedback before closing.
            pending_close = (_action == "DONE");
            close_due = current_time + 150;
            break;
        case "PASTE":
            if (paste_mode != "none") {
                if (os_browser != browser_not_a_browser) {
                    clipboard_token++;
                    gmcu_text_clipboard("paste", "", string(id), clipboard_token);
                } else {
                    try {
                        feedback = state.paste(clipboard_get_text(), paste_mode) ? "Pasted" : "Clipboard is empty or has no permitted characters";
                    } catch (_clipboard_error) {
                        log_error("native clipboard read failed: " + string(_clipboard_error));
                        feedback = "Clipboard unavailable";
                    }
                }
            }

            break;
        default:
            state.type(_action);
            break;
    }
}

/** Receive pointer/controller focus. */
function on_hover_enter() { hovered = true; }

/** Release pointer/controller focus. */
function on_hover_leave() { hovered = false; }

/** Open editing on activation; the opening release cannot enter a character. */
function on_pressed() { activate();}

/** Opening a field consumes its press, so release has no editing action. */
function on_released() { }

/** Draw the field, persistent mask, editing blink, and closed-field validation. */
function on_draw_gui() {
    var saved = new gmcu_DrawingParameters(); // Drawing state restored after this field renders.
    if (font != noone && font_exists(font)) {
        draw_set_font(font);
    }

    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    var left = x - hit_width / 2; // Left edge of the assigned sprite.
    var top = y - hit_height / 2; // Top edge of the assigned sprite.
    var invalid = touched && !editing && !state.valid(); // Closed field missing required characters.
    var retro = skin == "retro"; // Whether to draw the unframed pixel-style field.
    var pattern = mask == "" ? string_repeat("X", text_length) : mask; // Editable slots and visible separators.
    var advance = min(retro ? 12 : 25, (hit_width - 24) / string_length(pattern)); // Distance between glyphs.
    var origin = x - string_length(pattern) * advance / 2; // Center of the first glyph.
    var slot = 0; // Editable slot represented by the next X in the mask.
    var blink = (current_time div 400) mod 2 == 0; // Caret's visible phase.

    draw_self();

    if (!retro && (invalid || editing || hovered)) {
        draw_set_color(invalid ? c_red : accent_color);
        draw_rectangle(left, top, left + hit_width, top + hit_height, true);
    }

    // Render slots, separators, and caret.
    for (var mask_position = 1; mask_position <= string_length(pattern); mask_position++) {
        var character = string_char_at(pattern, mask_position); // Mask separator or editable placeholder.
        var color = retro ? make_color_rgb(28, 88, 202) : placeholder_color; // Empty-slot color.
        if (character == "X") {
            var filled = state.slots[slot] != "";
            character = filled ? state.slots[slot] : "X";
            color = filled ? (retro ? make_color_rgb(44, 255, 92) : text_color) : color;
            if (editing && slot == state.caret && blink) {
                character = filled ? "" : "_";
                color = retro ? c_white : text_color;
            }

            slot++;
        }

        draw_set_color(color);
        if (retro) {
            draw_text_transformed(origin + (mask_position - 1) * advance, y, character, 0.6, 0.6, 0);
        } else {
            draw_text(origin + (mask_position - 1) * advance, y, character);
        }
    }

    saved.apply();
}

/** Limit active editing to text fields and keys.
 * @param {Instance} _target Cursor candidate.
 * @returns {Boolean} Whether the cursor may select it while editing.
 */
function accepts_cursor_target(_target) {
    return _target.object_index == gmcu_o_textbox || _target.object_index == gmcu_o_text_key;
}
