function log_debug(_message, _local_only = false) {
	if (!ENABLE_DEBUG_LOG) return;

	var _msg = "[DEBUG]" + get_log_tags() + " " + string(_message);
	show_debug_message(_msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_DEBUG, _msg);
	if (!_local_only) gmcu_log_send_telemetry(GMCU_LOG_LEVEL_DEBUG, _msg);
}
