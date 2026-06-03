function log_debug(_message, _local_only = false) {
	if (!ENABLE_DEBUG_LOG) return;

	var _msg = "[DEBUG]" + get_log_tags() + " " + string(_message);
	show_debug_message(_msg);
}

