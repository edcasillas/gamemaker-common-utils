if (is_undefined(config)) return;

if (config.trigger_pressed()) {
	if (is_open) close_menu(); else open_menu();
	return;
}
if (!is_open) return;

var _has_gamepad = instance_exists(gmcu_o_input_hub) && gmcu_o_input_hub.gmcu_has_connected_gamepad();
if (keyboard_check_pressed(vk_escape) || (_has_gamepad && gamepad_button_check_pressed(0, gp_face2))) {
	go_back();
	return;
}
if (keyboard_check_pressed(vk_up) || (_has_gamepad && gamepad_button_check_pressed(0, gp_padu))) {
	move_selection(-1);
	mouse_active = false;
}
if (keyboard_check_pressed(vk_down) || (_has_gamepad && gamepad_button_check_pressed(0, gp_padd))) {
	move_selection(1);
	mouse_active = false;
}
if (keyboard_check_pressed(vk_left) || (_has_gamepad && gamepad_button_check_pressed(0, gp_padl))) {
	activate_item(-1);
}
if (keyboard_check_pressed(vk_right) || (_has_gamepad && gamepad_button_check_pressed(0, gp_padr))) {
	activate_item(1);
}
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)
	|| (_has_gamepad && gamepad_button_check_pressed(0, gp_face1))) {
	activate_item();
}

var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
if (_mouse_x != last_mouse_x || _mouse_y != last_mouse_y) {
	last_mouse_x = _mouse_x;
	last_mouse_y = _mouse_y;
	mouse_active = true;
}

if (mouse_active) {
	var _gui_w = display_get_gui_width();
	var _gui_h = display_get_gui_height();
	var _panel_x = panel_margin;
	var _panel_y = panel_margin;
	var _panel_w = _gui_w - panel_margin * 2;
	var _list_y = _panel_y + header_height;
	var _visible_rows = max(1, floor((_gui_h - panel_margin * 2 - header_height - 12) / row_height));
	var _hover = floor((_mouse_y - _list_y) / row_height) + scroll_offset;
	var _items = current_items();
	if (_mouse_x >= _panel_x && _mouse_x <= _panel_x + _panel_w
		&& _hover >= 0 && _hover < array_length(_items)) {
		selected_index = _hover;
		if (mouse_check_button_pressed(mb_left)) activate_item();
	}

	var _wheel = mouse_wheel_down() - mouse_wheel_up();
	if (_wheel != 0) {
		scroll_offset = clamp(
			scroll_offset + _wheel,
			0,
			max(0, array_length(_items) - _visible_rows)
		);
	}
}
