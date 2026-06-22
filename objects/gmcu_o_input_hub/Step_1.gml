var _registered_keyboard_keys = global.gmcu_registered_keyboard_keys;
for (var _keyboard_i = 0; _keyboard_i < array_length(_registered_keyboard_keys); _keyboard_i++) {
	var _keyboard_key = _registered_keyboard_keys[_keyboard_i];
	var _keyboard_state = gmcu_keyboard_input_state(_keyboard_key);
	_keyboard_state.pressed_gameplay = false;
	_keyboard_state.released_gameplay = false;
	_keyboard_state.pressed_dev_menu = false;
	_keyboard_state.released_dev_menu = false;

	var _keyboard_is_down = keyboard_check(_keyboard_key);
	if (_keyboard_is_down && !_keyboard_state.is_down) {
		_keyboard_state.is_down = true;
		_keyboard_state.owner = current_input_owner();
		if (_keyboard_state.owner == GMCU_INPUT_OWNER_DEV_MENU) {
			_keyboard_state.pressed_dev_menu = true;
		} else {
			_keyboard_state.pressed_gameplay = true;
			gmcu_eventbus_dispatch(GMCU_EVENT_KEYBOARD_KEY_PRESSED, _keyboard_key);
		}
	}
	if (!_keyboard_is_down && _keyboard_state.is_down) {
		_keyboard_state.is_down = false;
		if (_keyboard_state.owner == GMCU_INPUT_OWNER_DEV_MENU) {
			_keyboard_state.released_dev_menu = true;
		} else {
			_keyboard_state.released_gameplay = true;
			gmcu_eventbus_dispatch(GMCU_EVENT_KEYBOARD_KEY_RELEASED, _keyboard_key);
		}
	}
}

var _left = input_state_down(gmcu_keyboard_input_state(vk_left), GMCU_INPUT_OWNER_GAMEPLAY);
var _right = input_state_down(gmcu_keyboard_input_state(vk_right), GMCU_INPUT_OWNER_GAMEPLAY);
var _up = input_state_down(gmcu_keyboard_input_state(vk_up), GMCU_INPUT_OWNER_GAMEPLAY);
var _down = input_state_down(gmcu_keyboard_input_state(vk_down), GMCU_INPUT_OWNER_GAMEPLAY);
h_axis = _right - _left;
v_axis = _up - _down;

var _registered_gamepad_buttons = global.gmcu_registered_gamepad_buttons;
for (var _gamepad_i = 0; _gamepad_i < array_length(_registered_gamepad_buttons); _gamepad_i++) {
	var _button_code = _registered_gamepad_buttons[_gamepad_i];
	var _button_state = gmcu_gamepad_input_state(_button_code);
	_button_state.pressed_gameplay = false;
	_button_state.released_gameplay = false;
	_button_state.pressed_dev_menu = false;
	_button_state.released_dev_menu = false;
}

var _has_gamepad = gmcu_has_connected_gamepad();
if (_has_gamepad) {
	for (var _button_i = 0; _button_i < array_length(_registered_gamepad_buttons); _button_i++) {
		var _button_code = _registered_gamepad_buttons[_button_i];
		var _button_name = global.gmcu_gamepad_buttons_mapping[$ string(_button_code)];
		var _button_state = gmcu_gamepad_input_state(_button_code);
		var _button_is_down = gamepad_button_check(0, _button_code);

		if (_button_is_down && !_button_state.is_down) {
			_button_state.is_down = true;
			_button_state.owner = current_input_owner();
			if (_button_state.owner == GMCU_INPUT_OWNER_DEV_MENU) {
				_button_state.pressed_dev_menu = true;
			} else {
				_button_state.pressed_gameplay = true;
				gmcu_log_debug("Button " + _button_name + " pressed", true);
				gmcu_eventbus_dispatch(GMCU_EVENT_GAMEPAD_BUTTON_PRESSED, _button_code);
			}
		}

		if (!_button_is_down && _button_state.is_down) {
			_button_state.is_down = false;
			if (_button_state.owner == GMCU_INPUT_OWNER_DEV_MENU) {
				_button_state.released_dev_menu = true;
			} else {
				_button_state.released_gameplay = true;
				gmcu_log_debug("Button " + _button_name + " released", true);
				gmcu_eventbus_dispatch(GMCU_EVENT_GAMEPAD_BUTTON_RELEASED, _button_code);
			}
		}
	}
}

if (h_axis == 0 && v_axis == 0) {
	_left = input_state_down(gmcu_gamepad_input_state(gp_padl), GMCU_INPUT_OWNER_GAMEPLAY);
	_right = input_state_down(gmcu_gamepad_input_state(gp_padr), GMCU_INPUT_OWNER_GAMEPLAY);
	_up = input_state_down(gmcu_gamepad_input_state(gp_padu), GMCU_INPUT_OWNER_GAMEPLAY);
	_down = input_state_down(gmcu_gamepad_input_state(gp_padd), GMCU_INPUT_OWNER_GAMEPLAY);

	h_axis = _right - _left;
	v_axis = _up - _down;

	if (_has_gamepad) {
		if (h_axis == 0 && current_input_owner() == GMCU_INPUT_OWNER_GAMEPLAY) {
			h_axis = gamepad_axis_value(gamepads[0], gp_axislh);
		}
		if (v_axis == 0 && current_input_owner() == GMCU_INPUT_OWNER_GAMEPLAY) {
			v_axis = gamepad_axis_value(gamepads[0], gp_axislv);
		}
	}
}
