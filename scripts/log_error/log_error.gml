/**
 * @description Writes an error, forwards it to telemetry, and optionally displays a development notification.
 * @param {Any} _message Value to log.
 * @param {Bool} _show_notification Whether to request an in-game notification.
 */
function log_error(_message, _show_notification = true) {
	if (ENABLE_ERROR_LOG) {
		var _msg = "[ERROR]" + get_log_tags() + " " + string(_message);
		gmcu_log_write_output(GMCU_LOG_LEVEL_ERROR, _msg);
		gmcu_log_buffer_push(GMCU_LOG_LEVEL_ERROR, _msg);
		gmcu_log_send_telemetry(GMCU_LOG_LEVEL_ERROR, _msg);
	}

	common_utils_try_show_notification(string(_message), "error", _show_notification);
}

/**
 * @description Sends a message to the optional in-game notification handler in DevBuild.
 * @param {string} _message Notification text.
 * @param {string} _kind Notification category used by the consumer handler.
 * @param {Bool} _show_notification Whether notification display is enabled for this call.
 */
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
