state = new gmcu_TextState(alphabet, text_length, case_sensitive, wrap_caret, initial_value);
editing = false; touched = false; hovered = false; pressed = false; feedback = "";
area = noone; is_interactable = true; hit_width = field_width; hit_height = field_height;
repeat_key = 0; repeat_due = 0; opened_at = -1; clipboard_token = 0;
if (textbox_id == "" || keyboard_area_id == "") show_error("Textbox requires textbox_id and keyboard_area_id", true);
if (mask != "" && string_count("X", mask) != text_length) show_error("Textbox mask must have one X per position", true);
if (keyboard_layout == "qwerty") {
    for (var i=1;i<=string_length(alphabet);i++) if (string_pos(string_char_at(alphabet,i),"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ")==0) show_error("QWERTY layout supports uppercase ASCII letters, digits and space",true);
}
gmcu_register_gamepad_button(gp_face2);
gmcu_universal_cursor_subscribe(textbox_id);
gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEFAULT, textbox_id);
/** Activate this field and its configured keyboard area. */
function activate() {
    if (editing) return;
    if (os_browser == browser_not_a_browser) show_error("Text Input requires the HTML5 capture adapter", true);
    if (instance_exists(global.gmcu_active_textbox)) global.gmcu_active_textbox.finish(false, false);
    area = noone;
    with (gmcu_o_text_keyboard) if (area_id == other.keyboard_area_id) {
        if (other.area != noone) show_error("Duplicate keyboard area ID", true);
        other.area = id;
    }
    if (!instance_exists(area)) show_error("Textbox keyboard area not found: " + keyboard_area_id, true);
    editing = true; global.gmcu_active_textbox = id; opened_at = current_time;
    feedback = ""; repeat_key = 0; keyboard_string = "";
    gmcu_text_capture_begin();
    gmcu_text_copy_snapshot(copy_mode == "all" ? copy_text() : "", copy_mode == "all");
    var cursor = gmcu_o_universal_cursor;
    cursor.text_input_owner = id;
    gmcu_o_input_hub.focus_owner=id; gmcu_o_input_hub.focus_route="text_input";
    area.open(id);
}
/** Close and validate; submit a complete value only when explicitly requested. */
function finish(_submit, _restore_cursor = true) {
    if (!editing) return;
    editing = false; touched = true; repeat_key = 0; clipboard_token++;
    gmcu_text_capture_end();
    if (instance_exists(area)) area.close();
    if (instance_exists(gmcu_o_universal_cursor)) {
        gmcu_o_universal_cursor.text_input_owner = noone;
        if (_restore_cursor) { gmcu_o_universal_cursor.gui_x = x; gmcu_o_universal_cursor.gui_y = y; }
    }
    if (instance_exists(gmcu_o_input_hub) && gmcu_o_input_hub.focus_owner == id) gmcu_o_input_hub.focus_owner=noone;
    global.gmcu_active_textbox = noone;
    if (_submit && state.valid()) gmcu_eventbus_dispatch(GMCU_EVENT_TEXT_SUBMITTED, { textbox_id: textbox_id, value: state.text() });
}
/** Return mask-formatted text for COPY, omitting empty positions and placeholders. */
function copy_text() {
    if (mask == "") return state.text();
    var result = ""; var slot = 0;
    for (var i = 1; i <= string_length(mask); i++) {
        var c = string_char_at(mask, i);
        if (c == "X") { result += state.slots[slot]; slot++; } else result += c;
    }
    return result;
}
/** Apply one editing action or an accepted literal character. */
function edit_action(_action) {
    if (!editing) return;
    switch (_action) {
        case "SPACE": state.type(" "); break;
        case "LEFT": state.move(-1); break;
        case "RIGHT": state.move(1); break;
        case "DEL": if (allow_delete) state.erase(); break;
        case "DONE": finish(true); break;
        case "CANCEL": finish(false); break;
        case "COPY": if (copy_mode == "all") { clipboard_token++; gmcu_text_clipboard("copy", copy_text(), string(id), clipboard_token); } break;
        case "PASTE": if (paste_mode != "none") { clipboard_token++; gmcu_text_clipboard("paste", "", string(id), clipboard_token); } break;
        default: state.type(_action); break;
    }
}
/** Receive pointer/controller focus. */
function on_hover_enter() { hovered = true; }
/** Release pointer/controller focus. */
function on_hover_leave() { hovered = false; pressed = false; }
/** Open editing on activation; the opening release cannot enter a character. */
function on_pressed() { activate(); }
/** Opening a field consumes its press, so release has no editing action. */
function on_released() { }
/** Draw the field, persistent mask, editing blink, and closed-field validation. */
function on_draw_gui() {
    var saved = new gmcu_DrawingParameters();
    if (font != noone && font_exists(font)) draw_set_font(font);
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_middle);
    var left = x - field_width / 2; var top = y - field_height / 2;
    var invalid = touched && !editing && !state.valid();
    draw_set_color(background_color); draw_rectangle(left, top, left + field_width, top + field_height, false);
    draw_set_color(invalid ? c_red : (editing || hovered ? accent_color : c_gray));
    draw_rectangle(left, top, left + field_width, top + field_height, true);
    draw_set_color(text_color); draw_text(left, top - 19, label);
    var pattern = mask == "" ? string_repeat("X", text_length) : mask;
    var advance = min(25, (field_width - 24) / string_length(pattern));
    var origin = x - string_length(pattern) * advance / 2; var slot = 0;
    var blink = (current_time div 400) mod 2 == 0;
    for (var i = 1; i <= string_length(pattern); i++) {
        var c = string_char_at(pattern, i); var color = placeholder_color;
        if (c == "X") {
            var filled = state.slots[slot] != "";
            c = filled ? state.slots[slot] : "X"; color = filled ? text_color : placeholder_color;
            if (editing && slot == state.caret && blink) { c = filled ? "" : "_"; color = text_color; }
            slot++;
        }
        draw_set_color(color); draw_text(origin + (i - 1) * advance, y, c);
    }
    if (invalid) { draw_set_color(c_red); draw_text(left, top + field_height + 18, string(text_length) + " characters required"); }
    else if (feedback != "") { draw_set_color(text_color); draw_text(left, top + field_height + 18, feedback); }
    saved.apply();
}

/** Limit active editing to text fields and keys, excluding unrelated host controls. */
function accepts_cursor_target(_target) {
    return _target.object_index == gmcu_o_textbox || _target.object_index == gmcu_o_text_key;
}
