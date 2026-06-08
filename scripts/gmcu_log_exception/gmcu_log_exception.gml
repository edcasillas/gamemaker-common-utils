/**
 * @description Writes an exception, forwards it to telemetry, and optionally displays a development notification.
 * @param {Any} _exception Exception value or struct.
 * @param {String} _tag Optional context tag.
 * @param {Bool} _show_notification Whether to request an in-game notification.
 */
function gmcu_log_exception(_exception, _tag = "", _show_notification = true) {
	var _msg = "[EXCEPTION]" + gmcu_log_get_tags();
	if (_tag != "") _msg += "[" + string(_tag) + "]";
	_msg += " " + string(_exception);

	show_debug_message(_msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_EXCEPTION, _msg);
	gmcu_log_send_telemetry(GMCU_LOG_LEVEL_ERROR, _msg);

	var _notification_message = "Exception: " + string(_exception);
	if (!is_undefined(_exception.message)) {
		_notification_message = "Exception: " + string(_exception.message);
	}

	gmcu_log_try_show_notification(_notification_message, "exception", _show_notification);
}
