if (!editing || current_time == opened_at) exit;
if (pending_close != -1) {
    if (current_time >= close_due) finish(pending_close == 1);
    exit;
}

if (gmcu_ui_overlay_blocks_pointer_input()) exit;
// Physical keyboard and clipboard events waiting for this textbox.
var events = [];
if (os_browser != browser_not_a_browser) {
    events = json_parse(gmcu_text_capture_poll());
} else {
    // GameMaker collects printable native keyboard input between Step events.
    var typed_text = keyboard_string;
    keyboard_string = "";
    for (var typed_index = 1; typed_index <= string_length(typed_text); typed_index++) {
        array_push(events, { kind: "char", value: string_char_at(typed_text, typed_index) });
    }

    if (keyboard_check_pressed(vk_enter)) array_push(events, { kind: "action", value: "DONE" });
    if (keyboard_check_pressed(vk_escape)) array_push(events, { kind: "action", value: "CANCEL" });
}
// Index for this sequence.
for (var i = 0; i < array_length(events); i++) {
    // Event being applied to the active textbox.
    var e = events[i];
    if (!editing || pending_close != -1) break;
    if (e.kind == "char") {
        // Character normalized against the active alphabet.
        var character = state.normalize(e.value);
        if (character != "") {
            state.type(character);
            area.flash_key(character);
        }
    }
    else if (e.kind == "paste") {
        if (paste_mode != "none") state.paste(e.value, paste_mode);
    }
    else if (e.kind == "shortcut") {
        if (e.value == "PASTE" && paste_mode != "none") area.flash_key(e.value);
    }
    else if (e.kind == "feedback") feedback=e.value;
    else if (e.kind == "action") edit_action(e.value);
    else if (e.kind == "clipboard" && e.owner == string(id) && e.token == clipboard_token) {
        if (!e.ok) feedback = "Clipboard unavailable";
        else if (e.action == "copy") feedback = "Copied";
        else if (e.value == "") feedback = "Clipboard is empty";
        else {
            feedback = state.paste(e.value, paste_mode) ? "Pasted" : "No permitted characters";
        }
    }
}

if (!editing || pending_close != -1) exit;
// Physical key action to repeat or apply.
var action = keyboard_check(vk_left) ? "LEFT" : (keyboard_check(vk_right) ? "RIGHT" : ((keyboard_check(vk_backspace) || keyboard_check(vk_delete)) ? "DEL" : ""));
if (action == "") repeat_key = "";
else if (action != repeat_key) {
    repeat_key = action;
    repeat_due = current_time + 400;
    edit_action(action);
}
else if (current_time >= repeat_due) {
    repeat_due = current_time + 80;
    edit_action(action);
}

if (!editing || pending_close != -1) exit;
if (gmcu_o_input_hub.gmcu_gamepad_button_pressed(gp_face2,"text_input")) edit_action("CANCEL");
else if (gmcu_o_input_hub.gmcu_gamepad_button_pressed(gp_start,"text_input")) edit_action("DONE");
if (pending_close != -1) exit;
// Only the actual canvas pointer can cause outside-click cancellation. HTML pad
// touches are captured by its adapter and never reach the runner's mouse lane.
if (editing && mouse_check_button_pressed(mb_left)) {
    var px = device_mouse_x_to_gui(0); // Canvas pointer's GUI x coordinate.
    var py = device_mouse_y_to_gui(0); // Canvas pointer's GUI y coordinate.
    if (!is_undefined(global.gmcu_gui_pointer_provider)) {
        // Host-provided GUI pointer coordinates.
        var pointer = global.gmcu_gui_pointer_provider();
        if (array_length(pointer) == 2) {
            px = pointer[0];
            py = pointer[1];
        }
    }

    // Whether the pointer is inside the textbox.
    var in_field = point_in_rectangle(px, py, x-field_width/2, y-field_height/2, x+field_width/2, y+field_height/2);
    // Whether the pointer is inside the keyboard area.
    var in_keys = point_in_rectangle(px, py, area.x-area.area_width/2, area.y-area.area_height/2, area.x+area.area_width/2, area.y+area.area_height/2);
    if (!in_field && !in_keys) finish(false, false);
}
