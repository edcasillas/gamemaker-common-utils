keys = []; // Generated key instances owned by this area.
target = noone; // Textbox receiving key actions while open.
nav_button = -1; // D-pad direction held for navigation repeat.
nav_due = 0; // Time when held navigation repeats.
custom_draw = noone; // Optional host renderer for generated keys.
area_width = 0; // Keyboard panel width derived from its sprite and Room Editor scale.
area_height = 0; // Keyboard panel height derived from its sprite and Room Editor scale.

if (sprite_index == noone) {
    gmcu_log_error("keyboard area_id=" + string(area_id) + ", instance=" + string(id) + ": assign a sprite to the keyboard object");
    instance_destroy();
    return;
}

if (sprite_get_xoffset(sprite_index) != floor(sprite_get_width(sprite_index) / 2) || sprite_get_yoffset(sprite_index) != floor(sprite_get_height(sprite_index) / 2)) {
    gmcu_log_error("keyboard area_id=" + string(area_id) + ", instance=" + string(id) + ": keyboard sprite origin must be centered");
    instance_destroy();
    return;
}

image_speed = 0;
area_width = sprite_get_width(sprite_index) * abs(image_xscale);
area_height = sprite_get_height(sprite_index) * abs(image_yscale);
gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_TEXT_KEYBOARD, area_id);

if (skin == "") {
    skin = "clean";
}

/** Draw the host sprite behind active keys in GUI coordinates. */
function on_draw_gui() {
    if (instance_exists(target)) {
        draw_self();
    }
}

/** Build keys from the active textbox's alphabet and layout.
 * @param {Instance} _textbox Field receiving generated key actions.
 */
function open(_textbox) {
    close();
    target = _textbox;
    var rows = []; // Character rows for the active textbox.
    if (target.keyboard_layout == "qwerty") {
        rows = ["0123456789", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    } else {
        var characters = string_replace_all(target.alphabet, " ", ""); // Alphabet without the separate space key.
        var character_count = string_length(characters); // Keys distributed across three rows.
        var keys_per_row = ceil(character_count / 3); // Maximum character keys per row.
        for (var character_index = 1; character_index <= character_count; character_index += keys_per_row) {
            array_push(rows, string_copy(characters, character_index, keys_per_row));
        }
    }

    var has_space = string_pos(" ", target.alphabet) > 0; // Whether the field permits a space key.
    var row_count = array_length(rows) + 1 + has_space; // Character, action, and optional space rows.
    var key_height = min(50, (area_height - 16) / row_count - 8);
    for (var row_index = 0; row_index < array_length(rows); row_index++) {
        var row_characters = rows[row_index]; // Characters in this layout row.
        var filtered = ""; // Characters permitted by the active textbox.
        for (var character_index = 1; character_index <= string_length(row_characters); character_index++) {
            var character = string_char_at(row_characters, character_index); // Candidate key for this row.
            if (string_pos(character, target.alphabet) > 0) {
                filtered += character;
            }
        }

        var key_count = string_length(filtered); // Visible keys in this row.
        if (key_count == 0) {
            continue;
        }

        var key_width = min(62, (area_width - 16) / key_count - 6); // Width of each key in this row.
        for (var key_index = 0; key_index < key_count; key_index++) {
            add_key(string_char_at(filtered, key_index + 1), row_index, key_index, key_count, key_width, key_height, row_count);
        }
    }

    if (has_space) {
        add_key("SPACE", array_length(rows), 0, 1, min(320, area_width - 16), key_height, row_count);
    }

    var actions = ["LEFT", "RIGHT"];
    if (target.allow_delete) {
        array_push(actions, "DEL");
    }

    if (target.paste_mode != "none") {
        array_push(actions, "PASTE");
    }

    array_push(actions, "CANCEL", "DONE");
    var action_count = array_length(actions); // Keys in the bottom action row.
    var action_width = min(100, (area_width - 16) / action_count - 6); // Width of each action key.
    for (var action_index = 0; action_index < action_count; action_index++) {
        add_key(actions[action_index], row_count - 1, action_index, action_count, action_width, key_height, row_count);
    }
}

/** Create one interactive key in a centered keyboard row.
 * @param {String} _action Character or editing action.
 * @param {Real} _row Zero-based row index.
 * @param {Real} _column Zero-based column index.
 * @param {Real} _columns Number of keys in this row.
 * @param {Real} _width Key width.
 * @param {Real} _height Key height.
 * @param {Real} _rows Total visible rows.
 */
function add_key(_action,_row,_column,_columns,_width,_height,_rows) {
    var key_x = x + (_column - (_columns - 1) / 2) * (_width + 6); // Key center on the horizontal row.
    var key_y = y + (_row - (_rows - 1) / 2) * (_height + 8); // Key center on the vertical row.
    var key = instance_create_depth(key_x, key_y, depth, gmcu_o_text_key, {
        keyboard_area: id,
        action: _action,
        hit_width: _width,
        hit_height: _height,
        row_index: _row,
        font: target.font
    }); // Interactive key owned by this area.
    array_push(keys, key);
}

/** Destroy generated keys and release the editing target. */
function close() {
    for (var key_index = 0; key_index < array_length(keys); key_index++) {
        if (instance_exists(keys[key_index])) {
            instance_destroy(keys[key_index]);
        }
    }

    keys = [];
    target = noone;
    nav_button = -1;
}

/** Move selection to the adjacent key in the requested direction.
 * @param {Real} _direction Universal Cursor direction angle.
 */
function navigate(_direction) {
    // Key selected by Universal Cursor.
    var current = gmcu_o_universal_cursor.hovered_interactable;
    if (!instance_exists(current) || current.object_index != gmcu_o_text_key || current.keyboard_area != id) {
        gmcu_o_universal_cursor.gui_x = keys[0].x;
        gmcu_o_universal_cursor.gui_y = keys[0].y;
        return;
    }

    var best = noone; // Nearest navigable key in the requested direction.
    var distance = 1000000000; // Distance from the current key to best.
    for (var key_index = 0; key_index < array_length(keys); key_index++) {
        var k = keys[key_index]; // Candidate key.
        var valid = false; // Whether the candidate is in the requested direction.
        var dist = 0; // Distance from the current key to this candidate.
        switch (_direction) {
            case GMCU_DIRECTION_ANGLE.LEFT:
                valid = k.row_index == current.row_index && k.x < current.x;
                dist = current.x-k.x;
                break;
            case GMCU_DIRECTION_ANGLE.RIGHT:
                valid = k.row_index == current.row_index && k.x > current.x;
                dist = k.x-current.x;
                break;
            case GMCU_DIRECTION_ANGLE.UP:
                valid = k.row_index == current.row_index-1;
                dist = abs(k.x-current.x);
                break;
            case GMCU_DIRECTION_ANGLE.DOWN:
                valid = k.row_index == current.row_index+1;
                dist = abs(k.x-current.x);
                break;
        }

        if (valid && dist < distance) {
            distance = dist;
            best = k;
        }
    }

    if (instance_exists(best)) {
        gmcu_o_universal_cursor.gui_x = best.x;
        gmcu_o_universal_cursor.gui_y = best.y;
    }
}

/** Flash a visible character or action without moving pointer or navigation focus.
 * @param {string} _character Normalized character or action name. */
function flash_key(_character) {
    // Action identifier used to flash a visible key.
    var key_action = _character == " " ? "SPACE" : _character;
    for (var key_index = 0; key_index < array_length(keys); key_index++) {
        if (keys[key_index].action == key_action) {
            keys[key_index].flash_until = current_time + 150;
            break;
        }
    }
}
