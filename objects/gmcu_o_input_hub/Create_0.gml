if (gmcu_singleton()) { return; }

gamepads = [];
h_axis = 0;
v_axis = 0;
gmcu_input_registration_ensure_init();

/**
 * @description Returns the owner that should receive a newly pressed interaction this Step.
 * @returns {String} `dev_menu` when the Dev Menu is open, otherwise `gameplay`.
 */
function current_input_owner() {
	if (gmcu_dev_menu_is_open()) return GMCU_INPUT_OWNER_DEV_MENU;
	return GMCU_INPUT_OWNER_GAMEPLAY;
}

/**
 * @description Returns whether the requested routed press edge is available for the given owner.
 * @param {Struct|Undefined} _state Routed interaction state.
 * @param {String} _owner Owner requesting the interaction.
 * @returns {Bool} True when the owner owns the press edge this Step.
 */
function input_state_pressed(_state, _owner) {
	if (is_undefined(_state)) return false;
	if (_owner == GMCU_INPUT_OWNER_DEV_MENU) return _state.pressed_dev_menu;
	return _state.pressed_gameplay;
}

/**
 * @description Returns whether the requested routed release edge is available for the given owner.
 * @param {Struct|Undefined} _state Routed interaction state.
 * @param {String} _owner Owner requesting the interaction.
 * @returns {Bool} True when the owner owns the release edge this Step.
 */
function input_state_released(_state, _owner) {
	if (is_undefined(_state)) return false;
	if (_owner == GMCU_INPUT_OWNER_DEV_MENU) return _state.released_dev_menu;
	return _state.released_gameplay;
}

/**
 * @description Returns whether the routed held state is active for the given owner.
 * @param {Struct|Undefined} _state Routed interaction state.
 * @param {String} _owner Owner requesting the interaction.
 * @returns {Bool} True when the interaction is currently held by this owner.
 */
function input_state_down(_state, _owner) {
	if (is_undefined(_state)) return false;
	return _state.is_down && _state.owner == _owner;
}

/**
 * @description Returns the current combined keyboard or gamepad direction.
 * @returns {Real|Undefined} GameMaker direction angle, or undefined when idle.
 */
function gmcu_get_direction() {
	if(h_axis != 0 || v_axis != 0) {
		return point_direction(0, 0, h_axis, v_axis);
	} else {
		return undefined;
	}
}

/**
 * @description Returns whether Input Hub has tracked at least one connected gamepad.
 * @returns {Bool} True when a gamepad is connected.
 */
function gmcu_has_connected_gamepad() {
	return array_length(gamepads) > 0;
}

/**
 * @description Checks whether a registered keyboard key was released for the requested owner this Step.
 * @param {Real} _key GameMaker vk_* key constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when the owner received the release edge this Step.
 */
function gmcu_keyboard_key_released(_key, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_released(gmcu_keyboard_input_state(_key), _owner);
}

/**
 * @description Checks whether a registered keyboard key was pressed for the requested owner this Step.
 * @param {Real} _key GameMaker vk_* key constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when the owner received the press edge this Step.
 */
function gmcu_keyboard_key_pressed(_key, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_pressed(gmcu_keyboard_input_state(_key), _owner);
}

/**
 * @description Reduces the current input direction to one of four cardinal angles.
 * @returns {Real|Undefined} A cardinal GMCU_DIRECTION_ANGLE value, or undefined when idle.
 */
function gmcu_get_four_way_direction() {
	var _dir = gmcu_get_direction();
	if(_dir == undefined) {
		return undefined;
	}
	
	var _x = round(lengthdir_x(1, _dir));
	var _y = round(lengthdir_y(1, _dir));
	
	if(abs(_y) > abs(_x)) { // vertical movement
		if(_y > 0) {
			return GMCU_DIRECTION_ANGLE.UP; // 90
		} else {
			return GMCU_DIRECTION_ANGLE.DOWN; // 270
		}
	} else { // horizontal movement
		if(_x > 0) {
			return GMCU_DIRECTION_ANGLE.RIGHT; // 0
		} else {
			return GMCU_DIRECTION_ANGLE.LEFT; // 180
		}
	}
}

/**
 * @description Checks whether a gamepad button was released on gamepad slot 0 this Step.
 * @param {Real} _button GameMaker gp_* button constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when a connected gamepad released the button.
 */
function gmcu_gamepad_button_released(_button, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_released(gmcu_gamepad_input_state(_button), _owner);
}

/**
 * @description Checks whether a gamepad button was pressed on gamepad slot 0 this Step.
 * @param {Real} _button GameMaker gp_* button constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when a connected gamepad pressed the button.
 */
function gmcu_gamepad_button_pressed(_button, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_pressed(gmcu_gamepad_input_state(_button), _owner);
}
