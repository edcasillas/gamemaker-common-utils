if (editing) finish(false);
gmcu_universal_cursor_unsubscribe();
gmcu_layered_gui_unsubscribe();
if (inputs_registered) {
    gmcu_unregister_gamepad_button(gp_face2);
    gmcu_unregister_gamepad_button(gp_start);
}
