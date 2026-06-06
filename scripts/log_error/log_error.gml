function log_error(_message, _show_notification = true) {
	if (ENABLE_ERROR_LOG) {
		var _msg = "[ERROR]" + get_log_tags() + " " + string(_message);
		show_debug_message(_msg);
		gmcu_log_buffer_push(GMCU_LOG_LEVEL_ERROR, _msg);
		gmcu_log_send_telemetry(GMCU_LOG_LEVEL_ERROR, _msg);
	}

	common_utils_try_show_notification(string(_message), "error", _show_notification);
}

function common_utils_try_show_notification(_message, _kind = "info", _show_notification = true) {
	if (!IS_DEV_BUILD) return;
	if (!_show_notification) return;
	if (!global.gmcu_notifications_enabled) return;
	if (is_undefined(global.gmcu_notification_handler)) return;

	try {
		var _handler = global.gmcu_notification_handler;
		_handler(_message, _kind);
	} catch (_ex) {
		show_debug_message("[ERROR]" + get_log_tags() + " Notification handler failed: " + string(_ex));
	}
}
