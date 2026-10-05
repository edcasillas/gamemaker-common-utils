// Sample the optional gamepad once so all buttons and axes use one snapshot.
var _virtual_pad = { connected: false, buttons: [], axis_x: 0, axis_y: 0 };
if (!is_undefined(global.gmcu_virtual_gamepad_provider)) {
	_virtual_pad = global.gmcu_virtual_gamepad_provider();
}
virtual_gamepad_connected = _virtual_pad.connected;
var _physical_pad = array_length(gamepads) > 0 ? gamepads[0] : -1;
var _has_physical_pad = _physical_pad >= 0 && gamepad_is_connected(_physical_pad);

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
		if (_keyboard_state.owner != current_input_owner()) continue;
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
for (var _button_i = 0; _button_i < array_length(_registered_gamepad_buttons); _button_i++) {
	var _button_code = _registered_gamepad_buttons[_button_i];
	var _button_name = global.gmcu_gamepad_buttons_mapping[$ string(_button_code)];
	var _button_state = gmcu_gamepad_input_state(_button_code);
	_button_state.pressed_gameplay = false;
	_button_state.released_gameplay = false;
	_button_state.pressed_dev_menu = false;
	_button_state.released_dev_menu = false;
	var _button_is_down = (_has_physical_pad && gamepad_button_check(_physical_pad, _button_code))
		|| (_virtual_pad.connected && array_contains(_virtual_pad.buttons, _button_code));

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
		if (_button_state.owner != current_input_owner()) continue;
		if (_button_state.owner == GMCU_INPUT_OWNER_DEV_MENU) {
			_button_state.released_dev_menu = true;
		} else {
			_button_state.released_gameplay = true;
			gmcu_log_debug("Button " + _button_name + " released", true);
			gmcu_eventbus_dispatch(GMCU_EVENT_GAMEPAD_BUTTON_RELEASED, _button_code);
		}
	}
}

// Stronger axis wins; equal magnitudes retain the physical pad value.
var _physical_x = _has_physical_pad ? gamepad_axis_value(_physical_pad, gp_axislh) : 0;
var _physical_y = _has_physical_pad ? gamepad_axis_value(_physical_pad, gp_axislv) : 0;
var _virtual_x = _virtual_pad.connected ? _virtual_pad.axis_x : 0;
var _virtual_y = _virtual_pad.connected ? _virtual_pad.axis_y : 0;
gamepad_axis_x = abs(_virtual_x) > abs(_physical_x) ? _virtual_x : _physical_x;
gamepad_axis_y = abs(_virtual_y) > abs(_physical_y) ? _virtual_y : _physical_y;

if (h_axis == 0 && v_axis == 0) {
	_left = input_state_down(gmcu_gamepad_input_state(gp_padl), GMCU_INPUT_OWNER_GAMEPLAY);
	_right = input_state_down(gmcu_gamepad_input_state(gp_padr), GMCU_INPUT_OWNER_GAMEPLAY);
	_up = input_state_down(gmcu_gamepad_input_state(gp_padu), GMCU_INPUT_OWNER_GAMEPLAY);
	_down = input_state_down(gmcu_gamepad_input_state(gp_padd), GMCU_INPUT_OWNER_GAMEPLAY);

	h_axis = _right - _left;
	v_axis = _up - _down;

	if (h_axis == 0) h_axis = gmcu_gamepad_axis_value(gp_axislh);
	if (v_axis == 0) v_axis = gmcu_gamepad_axis_value(gp_axislv);
}

// Held gameplay directions must not move the game while another owner is active.
if (current_input_owner() != GMCU_INPUT_OWNER_GAMEPLAY) {
	h_axis = 0;
	v_axis = 0;
}
