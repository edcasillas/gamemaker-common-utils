function log_warn(_message) {
	if (!ENABLE_WARN_LOG) return;

	var _msg = "[WARN]" + get_log_tags() + " " + string(_message);
	show_debug_message(_msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_WARN, _msg);
}
