// Check keyboard directional inputs
var _left = keyboard_check(vk_left);
var _right = keyboard_check(vk_right);
var _up = keyboard_check(vk_up);
var _down = keyboard_check(vk_down);

h_axis = _right - _left; // Will be 1 for right, -1 for left
v_axis = _up - _down; // Will be 1 for up, -1 for down

// Check gamepad inputs
if(array_length(gamepads) == 0) { return; }

// Check directional inputs only if no keyboard inputs were received.
if(h_axis == 0 && v_axis == 0) {
	_left = gamepad_button_check(0, gp_padl);
	_right = gamepad_button_check(0, gp_padr);
	_up = gamepad_button_check(0, gp_padu);
	_down = gamepad_button_check(0, gp_padd);

	h_axis = _right - _left; // Will be 1 for right, -1 for left
	v_axis = _up - _down; // Will be 1 for up, -1 for down

	if (array_length(gamepads) > 0)
	{	
		if(h_axis == 0) h_axis = gamepad_axis_value(gamepads[0], gp_axislh);
		if(v_axis == 0) v_axis = gamepad_axis_value(gamepads[0], gp_axislv);
	}
}

// Check press and released gamepad buttons, and dispatch proper events.
for(var _i = 0; _i < array_length(gamepad_buttons); _i++) {
	var _button_code = gamepad_buttons[_i];
	var _button_name = global.gmcu_gamepad_buttons_mapping[$ string(_button_code)];
	if(gamepad_button_check_pressed(0, _button_code)) {
		log_debug("Button " + _button_name + " pressed", true);
		eventbus_dispatch(GMCU_EVENT_GAMEPAD_BUTTON_PRESSED, _button_code);
	}
	if(gamepad_button_check_released(0, _button_code)) {
		log_debug("Button " + _button_name + " released", true);
		eventbus_dispatch(GMCU_EVENT_GAMEPAD_BUTTON_RELEASED, _button_code);
	}
}
