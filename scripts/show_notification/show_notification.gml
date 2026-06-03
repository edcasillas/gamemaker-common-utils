global.in_game_notifications_tail = noone;

/**
@param {String OR InGameNotificationSettings} _notification_settings
*/
function show_notification(_notification_settings) {
	if (is_string(_notification_settings)) {
		_notification_settings = new InGameNotificationSettings(_notification_settings);
	}

	var _notif = instance_create_depth(0, 0, LAYER_DEPTH_MIN, o_notification_from_top, _notification_settings);

	var _previous_notif = global.in_game_notifications_tail;
	if (_previous_notif != noone && instance_exists(_previous_notif)) {
		_previous_notif.next = _notif;
		_notif.previous = _previous_notif;
		_notif.offset_y = _previous_notif.get_bottom_pos();
	}

	global.in_game_notifications_tail = _notif;
}

common_utils_set_notification_handler(function(_message, _kind) {
	var _notif = new InGameNotificationSettings(_message);

	switch (_kind) {
		case "error":
		case "exception":
			_notif.back_color = c_red;
			_notif.font_color = c_white;
			break;
		case "warning":
			_notif.back_color = c_yellow;
			_notif.font_color = c_black;
			break;
	}

	show_notification(_notif);
	delete _notif;
});

