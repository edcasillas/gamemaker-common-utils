if (gmcu_singleton()) { return; }

gamepads = [];
monitored_keyboard_keys = [
	vk_escape,
	vk_enter,
	vk_space,
	vk_left,
	vk_right,
	vk_up,
	vk_down
];

gamepad_buttons = [
gp_face1, //	Top button 1 (this maps to the "A" on an Xbox controller and the cross on a PS controller)
gp_face2, //	Top button 2 (this maps to the "B" on an Xbox controller and the circle on a PS controller)
gp_face3, //	Top button 3 (this maps to the "X" on an Xbox controller and the square on a PS controller)
gp_face4, //	Top button 4 (this maps to the "Y" on an Xbox controller and the triangle on a PS controller)
gp_shoulderl, //	Left shoulder button
gp_shoulderlb, //	Left shoulder trigger
gp_shoulderr, //	Right shoulder button
gp_shoulderrb, //	Right shoulder trigger
gp_select, //	The select button (on a PS controller, this triggers when you press the touchpad down)
gp_start, //	The start button (this is the "options" button on a PS controller)
gp_stickl, //	The left stick pressed (as a button)
gp_stickr, //	The right stick pressed (as a button)
gp_padu, //	D-pad up
gp_padd, //	D-pad down
gp_padl, //	D-pad left
gp_padr, //	D-pad right
// gp_home, //	The "home" button on Switch controllers, and the PS/XBOX logo buttons on some controllers
// gp_touchpadbutton, //	The touchpad button on a PS controller
// gp_paddler, //	Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1)
// gp_paddlel, //	Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3)
// gp_paddlerb, //	Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2)
// gp_paddlelb, //	Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4)
// gp_extra1, //	An extra button that may be mapped to anything
// gp_extra2, //	An extra button that may be mapped to anything
// gp_extra3, //	An extra button that may be mapped to anything
// gp_extra4, //	An extra button that may be mapped to anything
// gp_extra5, //	An extra button that may be mapped to anything
// gp_extra6, //	An extra button that may be mapped to anything
];

h_axis = 0;
v_axis = 0;
keyboard_input_states = {};
gamepad_input_states = {};

/**
 * @description Builds the default routed-input state for one monitored key or button.
 * @returns {Struct} Fresh interaction state.
 */
function create_input_state() {
	return {
		is_down: false,
		owner: GMCU_INPUT_OWNER_GAMEPLAY,
		pressed_gameplay: false,
		released_gameplay: false,
		pressed_dev_menu: false,
		released_dev_menu: false
	};
}

/**
 * @description Returns the owner that should receive a newly pressed interaction this Step.
 * @returns {String} `dev_menu` when the Dev Menu is open, otherwise `gameplay`.
 */
function current_input_owner() {
	if (gmcu_dev_menu_is_open()) return GMCU_INPUT_OWNER_DEV_MENU;
	return GMCU_INPUT_OWNER_GAMEPLAY;
}

/**
 * @description Returns the routed input state for one monitored keyboard key.
 * @param {Real} _key GameMaker vk_* key constant.
 * @returns {Struct|Undefined} State struct, or undefined when the key is not monitored.
 */
function keyboard_input_state(_key) {
	var _key_str = string(_key);
	if (!variable_struct_exists(keyboard_input_states, _key_str)) return undefined;
	return keyboard_input_states[$ _key_str];
}

/**
 * @description Returns the routed input state for one monitored gamepad button.
 * @param {Real} _button GameMaker gp_* button constant.
 * @returns {Struct|Undefined} State struct, or undefined when the button is not monitored.
 */
function gamepad_input_state(_button) {
	var _button_str = string(_button);
	if (!variable_struct_exists(gamepad_input_states, _button_str)) return undefined;
	return gamepad_input_states[$ _button_str];
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
 * @description Checks whether a monitored keyboard key was released for the requested owner this Step.
 * @param {Real} _key GameMaker vk_* key constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when the owner received the release edge this Step.
 */
function gmcu_keyboard_key_released(_key, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_released(keyboard_input_state(_key), _owner);
}

/**
 * @description Checks whether a monitored keyboard key was pressed for the requested owner this Step.
 * @param {Real} _key GameMaker vk_* key constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when the owner received the press edge this Step.
 */
function gmcu_keyboard_key_pressed(_key, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_pressed(keyboard_input_state(_key), _owner);
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
	return input_state_released(gamepad_input_state(_button), _owner);
}

/**
 * @description Checks whether a gamepad button was pressed on gamepad slot 0 this Step.
 * @param {Real} _button GameMaker gp_* button constant.
 * @param {String} _owner Optional owner name. Defaults to gameplay.
 * @returns {Bool} True when a connected gamepad pressed the button.
 */
function gmcu_gamepad_button_pressed(_button, _owner = GMCU_INPUT_OWNER_GAMEPLAY) {
	return input_state_pressed(gamepad_input_state(_button), _owner);
}

for (var _i = 0; _i < array_length(monitored_keyboard_keys); _i++) {
	keyboard_input_states[$ string(monitored_keyboard_keys[_i])] = create_input_state();
}

for (var _j = 0; _j < array_length(gamepad_buttons); _j++) {
	gamepad_input_states[$ string(gamepad_buttons[_j])] = create_input_state();
}
