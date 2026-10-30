if (!editing || current_time == opened_at) {
    exit;
}

if (pending_close != -1) {
    if (current_time >= close_due) {
        finish(pending_close == 1);
    }

    exit;
}

if (gmcu_ui_overlay_blocks_pointer_input()) {
    exit;
}

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

    if (keyboard_check_pressed(vk_enter)) {
        array_push(events, { kind: "action", value: "DONE" });
    }

    if (keyboard_check_pressed(vk_escape)) {
        array_push(events, { kind: "action", value: "CANCEL" });
    }
}

for (var event_index = 0; event_index < array_length(events); event_index++) {
    var input_event = events[event_index]; // Pending browser or native input for this field.
    if (!editing || pending_close != -1) {
        break;
    }

    if (input_event.kind == "char") {
        var character = state.normalize(input_event.value); // Accepted alphabet character, or empty.
        if (character != "") {
            state.type(character);
            keyboard_area.flash_key(character);
        }
    } else if (input_event.kind == "paste") {
        if (paste_mode != "none") {
            feedback = state.paste(input_event.value, paste_mode) ? "Pasted" : "Clipboard is empty or has no permitted characters";
        }
    } else if (input_event.kind == "shortcut") {
        if (input_event.value == "PASTE" && paste_mode != "none") {
            keyboard_area.flash_key(input_event.value);
        }
    } else if (input_event.kind == "feedback") {
        feedback = input_event.value;
    } else if (input_event.kind == "action") {
        edit_action(input_event.value);
    } else if (input_event.kind == "clipboard" && input_event.owner == string(id) && input_event.token == clipboard_token) {
        if (!input_event.ok) {
            gmcu_log_error(diagnostic_id + ": HTML5 paste failed: " + input_event.error);
        } else if (input_event.action == "copy") {
            feedback = "Copied";
        } else if (input_event.value == "") {
            feedback = "Clipboard is empty";
        } else {
            feedback = state.paste(input_event.value, paste_mode) ? "Pasted" : "No permitted characters";
        }
    }
}

if (!editing || pending_close != -1) {
    exit;
}

// Physical key action to repeat or apply.
var action = keyboard_check(vk_left) ? "LEFT" : (keyboard_check(vk_right) ? "RIGHT" : ((keyboard_check(vk_backspace) || keyboard_check(vk_delete)) ? "DEL" : ""));
if (action == "") {
    repeat_key = "";
} else if (action != repeat_key) {
    repeat_key = action;
    repeat_due = current_time + 400;
    edit_action(action);
} else if (current_time >= repeat_due) {
    repeat_due = current_time + 80;
    edit_action(action);
}

if (!editing || pending_close != -1) {
    exit;
}

if (gmcu_o_input_hub.gmcu_gamepad_button_pressed(gp_face2, "text_input")) {
    edit_action("CANCEL");
} else if (gmcu_o_input_hub.gmcu_gamepad_button_pressed(gp_start, "text_input")) {
    edit_action("DONE");
}

if (pending_close != -1) {
    exit;
}

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

    var in_field = point_in_rectangle(px, py, x - hit_width / 2, y - hit_height / 2, x + hit_width / 2, y + hit_height / 2); // Pointer hits this field's sprite.
    var in_keys = point_in_rectangle(px, py, keyboard_area.x - keyboard_area.area_width / 2, keyboard_area.y - keyboard_area.area_height / 2, keyboard_area.x + keyboard_area.area_width / 2, keyboard_area.y + keyboard_area.area_height / 2); // Pointer hits this field's keyboard.
    if (!in_field && !in_keys) {
        finish(false, false);
    }
}
