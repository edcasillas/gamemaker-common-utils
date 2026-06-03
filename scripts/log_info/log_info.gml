function log_info(_message) {
	if (!ENABLE_INFO_LOG) return;

	var _msg = "[INFO]" + get_log_tags() + " " + string(_message);
	show_debug_message(_msg);
}

