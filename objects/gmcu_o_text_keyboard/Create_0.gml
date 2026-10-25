keys = []; // Generated key instances owned by this area.
target = noone; // Textbox receiving key actions while open.
nav_button = -1; // D-pad direction held for navigation repeat.
nav_due = 0; // Time when held navigation repeats.
if (skin == "") skin = "clean";
custom_draw = noone; // Optional host renderer for generated keys.
/** Build visible keys for the active textbox; preserve its editing state. */
function open(_textbox) {
    close();
    target = _textbox;
    var rows = []; // Character rows for the active textbox.
    if (target.keyboard_layout == "qwerty") rows = ["0123456789", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    else {
        // Alphabet characters excluding the separate space key.
        var characters=string_replace_all(target.alphabet," ","");
        // Number of characters or positions being processed.
        var count = string_length(characters);
        // Number of character keys in a row.
        var columns = ceil(count / 3);
        // Index for this sequence.
        for (var i = 1; i <= count; i += columns) array_push(rows, string_copy(characters, i, columns));
    }
    // Whether the textbox permits a space character.
    var has_space=string_pos(" ",target.alphabet)>0;
    // Number of keyboard rows including action rows.
    var row_count = array_length(rows) + 1 + has_space;
    // Height allocated to each generated key.
    var key_height = min(50, (area_height - 16) / row_count - 8);
    // Index of the current keyboard row.
    for (var r = 0; r < array_length(rows); r++) {
        var chars = rows[r]; // Characters in this layout row.
        var filtered = ""; // Characters permitted by the active textbox.
        // Character or key at the current position.
        for (var c = 1; c <= string_length(chars); c++) if (string_pos(string_char_at(chars,c),target.alphabet)>0) filtered += string_char_at(chars,c);
        var columns = string_length(filtered); // Number of keys in this row.
        if (columns == 0) continue;
        // Width allocated to each generated key.
        var key_width = min(62, (area_width - 16) / columns - 6);
        // Character or key at the current position.
        for (var c = 0; c < columns; c++) add_key(string_char_at(filtered,c+1), r, c, columns, key_width, key_height, row_count);
    }
    if (has_space) add_key("SPACE",array_length(rows),0,1,min(320,area_width-16),key_height,row_count);
    // Editing actions placed in the bottom row.
    var actions = ["LEFT", "RIGHT"];
    if (target.allow_delete) array_push(actions,"DEL");
    if (target.paste_mode != "none") array_push(actions,"PASTE");
    array_push(actions,"CANCEL","DONE");
    // Character or key at the current position.
    for (var c = 0; c < array_length(actions); c++) add_key(actions[c], row_count-1, c, array_length(actions), min(100,(area_width-16)/array_length(actions)-6),key_height,row_count);
}
/** Create one shared interactive key in a centered row. */
function add_key(_action,_row,_column,_columns,_width,_height,_rows) {
    // Horizontal center of a generated key.
    var px = x + (_column-(_columns-1)/2)*(_width+6);
    // Vertical center of a generated key.
    var py = y + (_row-(_rows-1)/2)*(_height+8);
    // Generated or inspected keyboard key.
    var key = instance_create_depth(px,py,depth,gmcu_o_text_key, {keyboard_area:id, action:_action, hit_width:_width, hit_height:_height, row_index:_row, font:target.font});
    array_push(keys,key);
}
/** Destroy generated keys and release the editing target. */
function close() {
    // Index for this sequence.
    for (var i = 0; i < array_length(keys); i++) if (instance_exists(keys[i])) instance_destroy(keys[i]);
    keys = [];
    target = noone;
    nav_button = -1;
}
/** Navigate to an adjacent key or nearest horizontal center in the next row. */
function navigate(_direction) {
    // Key selected by Universal Cursor.
    var current = gmcu_o_universal_cursor.hovered_interactable;
    if (!instance_exists(current) || current.object_index != gmcu_o_text_key || current.keyboard_area != id) {
        gmcu_o_universal_cursor.gui_x=keys[0].x;
        gmcu_o_universal_cursor.gui_y=keys[0].y;
        return;
    }
    var best = noone; // Nearest navigable key in the requested direction.
    var distance = 1000000000; // Distance from the current key to best.
    // Index for this sequence.
    for (var i = 0; i < array_length(keys); i++) {
        var k = keys[i]; // Candidate key.
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
    // Index for this sequence.
    for (var i=0; i<array_length(keys); i++) {
        if (keys[i].action == key_action) { keys[i].flash_until=current_time+150; break; }
    }
}
