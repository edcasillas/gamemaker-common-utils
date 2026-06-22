/// @description Registers discrete keyboard and gamepad inputs for Input Hub monitoring.

/**
 * @description Builds the routed interaction state tracked for one registered key or button.
 * @returns {Struct} Fresh registered-input state.
 */
function gmcu_input_registration_create_state() {
	return {
		registration_count: 0,
		is_down: false,
		owner: GMCU_INPUT_OWNER_GAMEPLAY,
		pressed_gameplay: false,
		released_gameplay: false,
		pressed_dev_menu: false,
		released_dev_menu: false
	};
}

/**
 * @description Ensures the global keyboard and gamepad registration registries exist.
 */
function gmcu_input_registration_ensure_init() {
	if (!variable_global_exists("gmcu_registered_keyboard_keys")) global.gmcu_registered_keyboard_keys = [];
	if (!variable_global_exists("gmcu_registered_gamepad_buttons")) global.gmcu_registered_gamepad_buttons = [];
	if (!variable_global_exists("gmcu_keyboard_input_states")) global.gmcu_keyboard_input_states = {};
	if (!variable_global_exists("gmcu_gamepad_input_states")) global.gmcu_gamepad_input_states = {};
}

/**
 * @description Returns the registered routed state for one keyboard key.
 * @param {Real} _key GameMaker `vk_*` key constant.
 * @returns {Struct|Undefined} Registered state, or undefined when the key is not registered.
 */
function gmcu_keyboard_input_state(_key) {
	gmcu_input_registration_ensure_init();
	var _key_str = string(_key);
	if (!variable_struct_exists(global.gmcu_keyboard_input_states, _key_str)) return undefined;
	return global.gmcu_keyboard_input_states[$ _key_str];
}

/**
 * @description Returns the registered routed state for one gamepad button.
 * @param {Real} _button GameMaker `gp_*` button constant.
 * @returns {Struct|Undefined} Registered state, or undefined when the button is not registered.
 */
function gmcu_gamepad_input_state(_button) {
	gmcu_input_registration_ensure_init();
	var _button_str = string(_button);
	if (!variable_struct_exists(global.gmcu_gamepad_input_states, _button_str)) return undefined;
	return global.gmcu_gamepad_input_states[$ _button_str];
}

/**
 * @description Registers one keyboard key for Input Hub monitoring.
 * @param {Real} _key GameMaker `vk_*` key constant.
 */
function gmcu_register_keyboard_key(_key) {
	gmcu_input_registration_ensure_init();

	var _state = gmcu_keyboard_input_state(_key);
	if (is_undefined(_state)) {
		_state = gmcu_input_registration_create_state();
		global.gmcu_keyboard_input_states[$ string(_key)] = _state;
		array_push(global.gmcu_registered_keyboard_keys, _key);
	}

	_state.registration_count++;
}

/**
 * @description Unregisters one keyboard key from Input Hub monitoring when its last owner releases it.
 * @param {Real} _key GameMaker `vk_*` key constant.
 */
function gmcu_unregister_keyboard_key(_key) {
	var _state = gmcu_keyboard_input_state(_key);
	if (is_undefined(_state)) return;

	_state.registration_count = max(0, _state.registration_count - 1);
	if (_state.registration_count > 0) return;

	var _registered_keys = global.gmcu_registered_keyboard_keys;
	for (var _i = 0; _i < array_length(_registered_keys); _i++) {
		if (_registered_keys[_i] == _key) {
			array_delete(global.gmcu_registered_keyboard_keys, _i, 1);
			break;
		}
	}

	variable_struct_remove(global.gmcu_keyboard_input_states, string(_key));
}

/**
 * @description Registers one gamepad button for Input Hub monitoring.
 * @param {Real} _button GameMaker `gp_*` button constant.
 */
function gmcu_register_gamepad_button(_button) {
	gmcu_input_registration_ensure_init();

	var _state = gmcu_gamepad_input_state(_button);
	if (is_undefined(_state)) {
		_state = gmcu_input_registration_create_state();
		global.gmcu_gamepad_input_states[$ string(_button)] = _state;
		array_push(global.gmcu_registered_gamepad_buttons, _button);
	}

	_state.registration_count++;
}

/**
 * @description Unregisters one gamepad button from Input Hub monitoring when its last owner releases it.
 * @param {Real} _button GameMaker `gp_*` button constant.
 */
function gmcu_unregister_gamepad_button(_button) {
	var _state = gmcu_gamepad_input_state(_button);
	if (is_undefined(_state)) return;

	_state.registration_count = max(0, _state.registration_count - 1);
	if (_state.registration_count > 0) return;

	var _registered_buttons = global.gmcu_registered_gamepad_buttons;
	for (var _i = 0; _i < array_length(_registered_buttons); _i++) {
		if (_registered_buttons[_i] == _button) {
			array_delete(global.gmcu_registered_gamepad_buttons, _i, 1);
			break;
		}
	}

	variable_struct_remove(global.gmcu_gamepad_input_states, string(_button));
}
