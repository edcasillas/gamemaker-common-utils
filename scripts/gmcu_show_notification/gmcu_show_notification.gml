global.gmcu_in_game_notifications_tail = noone;

/**
 * @description Queues an in-game notification from text or presentation settings.
 * @param {String|gmcu_InGameNotificationSettings} _notification_settings Text or settings to display.
 */
function gmcu_show_notification(_notification_settings) {
	if (is_string(_notification_settings)) {
		_notification_settings = new gmcu_InGameNotificationSettings(_notification_settings);
	}

	var _notif = instance_create_depth(0, 0, GMCU_LAYER_DEPTH_MIN, gmcu_o_notification_from_top, _notification_settings);

	var _previous_notif = global.gmcu_in_game_notifications_tail;
	if (_previous_notif != noone && instance_exists(_previous_notif)) {
		_previous_notif.next = _notif;
		_notif.previous = _previous_notif;
		_notif.offset_y = _previous_notif.get_bottom_pos();
	}

	global.gmcu_in_game_notifications_tail = _notif;
}

gmcu_set_notification_handler(function(_message, _kind) {
	var _notif = new gmcu_InGameNotificationSettings(_message);

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

	gmcu_show_notification(_notif);
	delete _notif;
});
