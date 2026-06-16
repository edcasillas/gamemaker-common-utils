#macro GMCU_GAME_SPEED game_get_speed(gamespeed_fps)
#macro GMCU_OBJECT_NAME gmcu_get_current_object_name()
#macro GMCU_ROOM_NAME gmcu_get_current_room_name()
#macro GMCU_UNKNOWN_OBJECT "<unknown_object>"
#macro GMCU_UNKNOWN_ROOM "<unknown_room>"
#macro GMCU_DELTA_TIME_SECONDS delta_time * 0.000001

#macro GMCU_IS_DEV_BUILD false
#macro DevBuild:GMCU_IS_DEV_BUILD true

// GameMaker draws instances only inside this depth range.
#macro GMCU_LAYER_DEPTH_MIN -16000
#macro GMCU_LAYER_DEPTH_MAX 16000

// Common GUI draw priorities for LayeredGUI.
// Larger values draw earlier; lower values draw later and appear on top.
#macro GMCU_GUI_PRIORITY_DEFAULT 0
#macro GMCU_GUI_PRIORITY_LEADERBOARD_OVERLAY -900
#macro GMCU_GUI_PRIORITY_UNIVERSAL_CURSOR -1000
#macro GMCU_GUI_PRIORITY_TRANSITION_OVERLAY -1500
#macro GMCU_GUI_PRIORITY_DEV_MENU -2000

#macro GMCU_ANY_INPUT (keyboard_check_released(vk_anykey) || mouse_check_button_released(mb_left))
#macro GMCU_INT_MAX 2147483648

global.gmcu_notifications_enabled = false;
global.gmcu_notification_handler = undefined;

/**
 * @description Returns the current instance's object name with a safe fallback.
 * @returns {String} Object name, or GMCU_UNKNOWN_OBJECT when it cannot be resolved.
 */
function gmcu_get_current_object_name() {
	try {
		return object_get_name(object_index);
	} catch (_ex) {
		return GMCU_UNKNOWN_OBJECT;
	}
}

/**
 * @description Returns the current room name with a safe fallback.
 * @returns {String} Room name, or GMCU_UNKNOWN_ROOM when it cannot be resolved.
 */
function gmcu_get_current_room_name() {
	try {
		return room_get_name(room);
	} catch (_ex) {
		return GMCU_UNKNOWN_ROOM;
	}
}

/**
 * @description Registers or clears the optional visual notification handler.
 * @param {Function|Undefined} _handler Notification callback, or undefined to disable notifications.
 */
function gmcu_set_notification_handler(_handler) {
	global.gmcu_notification_handler = _handler;
	global.gmcu_notifications_enabled = !is_undefined(_handler);
}
