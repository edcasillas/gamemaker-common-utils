#macro GAME_SPEED game_get_speed(gamespeed_fps)
#macro OBJECT_NAME get_current_object_name()
#macro ROOM_NAME get_current_room_name()
#macro UNKNOWN_OBJECT "<unknown_object>"
#macro UNKNOWN_ROOM "<unknown_room>"
#macro DELTA_TIME_SECONDS delta_time * 0.000001

#macro IS_DEV_BUILD false
#macro DevBuild:IS_DEV_BUILD true

// GameMaker draws instances only inside this depth range.
#macro LAYER_DEPTH_MIN -16000
#macro LAYER_DEPTH_MAX 16000

#macro ANY_INPUT (keyboard_check_released(vk_anykey) || mouse_check_button_released(mb_left))
#macro INT_MAX 2147483648

global.gmcu_notifications_enabled = false;
global.gmcu_notification_handler = undefined;

function get_current_object_name() {
	try {
		return object_get_name(object_index);
	} catch (_ex) {
		return UNKNOWN_OBJECT;
	}
}

function get_current_room_name() {
	try {
		return room_get_name(room);
	} catch (_ex) {
		return UNKNOWN_ROOM;
	}
}

function common_utils_set_notification_handler(_handler) {
	global.gmcu_notification_handler = _handler;
	global.gmcu_notifications_enabled = !is_undefined(_handler);
}

