if(instance_number(object_index) > 1) {
	log_warn("[GMCU InputHub] Instance already exists. Deleting duplicate.");
	instance_destroy();
	return;
}
persistent = true;
gamepads = [];
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
 * @returns {Bool} True when a connected gamepad released the button.
 */
function gmcu_gamepad_button_released(_button) {
	return gmcu_has_connected_gamepad() && gamepad_button_check_released(0, _button);
}

/**
 * @description Checks whether a gamepad button was pressed on gamepad slot 0 this Step.
 * @param {Real} _button GameMaker gp_* button constant.
 * @returns {Bool} True when a connected gamepad pressed the button.
 */
function gmcu_gamepad_button_pressed(_button) {
	return gmcu_has_connected_gamepad() && gamepad_button_check_pressed(0, _button);
}
