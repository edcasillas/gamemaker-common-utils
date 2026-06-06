function log_exception(_exception, _tag = "", _show_notification = true) {
	var _msg = "[EXCEPTION]" + get_log_tags();
	if (_tag != "") _msg += "[" + string(_tag) + "]";
	_msg += " " + string(_exception);

	show_debug_message(_msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_EXCEPTION, _msg);

	var _notification_message = "Exception: " + string(_exception);
	if (!is_undefined(_exception.message)) {
		_notification_message = "Exception: " + string(_exception.message);
	}

	common_utils_try_show_notification(_notification_message, "exception", _show_notification);
}
