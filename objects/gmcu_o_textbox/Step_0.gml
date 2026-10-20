if (!editing || current_time == opened_at) exit;
if (gmcu_ui_overlay_blocks_pointer_input()) exit;
var events = json_parse(gmcu_text_capture_poll());
for (var i = 0; i < array_length(events); i++) {
    var e = events[i];
    if (!editing) break;
    if (e.kind == "char") {
        var character = state.normalize(e.value);
        if (character != "") {
            state.type(character);
            area.flash_character(character);
        }
    }
    else if (e.kind == "paste") { if (paste_mode != "none") state.paste(e.value, paste_mode); }
    else if (e.kind == "feedback") feedback=e.value;
    else if (e.kind == "action") edit_action(e.value);
    else if (e.kind == "clipboard" && e.owner == string(id) && e.token == clipboard_token) {
        if (!e.ok) feedback = "Clipboard unavailable";
        else if (e.action == "copy") feedback = "Copied";
        else if (e.value == "") feedback = "Clipboard is empty";
        else { feedback = state.paste(e.value, paste_mode) ? "Pasted" : "No permitted characters"; }
    }
}
if (!editing) exit;
var action = keyboard_check(vk_left) ? "LEFT" : (keyboard_check(vk_right) ? "RIGHT" : ((keyboard_check(vk_backspace) || keyboard_check(vk_delete)) ? "DEL" : ""));
if (action == "") repeat_key = "";
else if (action != repeat_key) { repeat_key = action; repeat_due = current_time + 400; edit_action(action); }
else if (current_time >= repeat_due) { repeat_due = current_time + 80; edit_action(action); }
if (!editing) exit;
if (gmcu_o_input_hub.gmcu_gamepad_button_pressed(gp_face2,"text_input")) finish(false);
// Only the actual canvas pointer can cause outside-click cancellation. HTML pad
// touches are captured by its adapter and never reach the runner's mouse lane.
if (editing && mouse_check_button_pressed(mb_left)) {
    var px = device_mouse_x_to_gui(0); var py = device_mouse_y_to_gui(0);
    if (!is_undefined(global.gmcu_gui_pointer_provider)) {
        var pointer = global.gmcu_gui_pointer_provider();
        if (array_length(pointer) == 2) { px = pointer[0]; py = pointer[1]; }
    }
    var in_field = point_in_rectangle(px, py, x-field_width/2, y-field_height/2, x+field_width/2, y+field_height/2);
    var in_keys = point_in_rectangle(px, py, area.x-area.area_width/2, area.y-area.area_height/2, area.x+area.area_width/2, area.y+area.area_height/2);
    if (!in_field && !in_keys) finish(false, false);
}

if (editing) gmcu_text_copy_snapshot(copy_mode == "all" ? copy_text() : "", copy_mode == "all");
