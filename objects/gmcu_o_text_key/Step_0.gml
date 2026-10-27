if (gmcu_o_input_hub.current_input_owner() != "text_input") {
    pressed = false;
    exit;
}

if (pressed && current_time >= held_due && (action == "LEFT" || action == "RIGHT" || action == "DEL")) {
    if (mouse_check_button(mb_left) || gmcu_o_input_hub.input_state_down(gmcu_gamepad_input_state(gp_face1),"text_input")) {
        held_due = current_time + 80;
        if (instance_exists(keyboard_area.target)) {
            keyboard_area.target.edit_action(action);
        }
    } else {
        pressed = false;
    }
}
