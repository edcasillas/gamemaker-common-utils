function log_info(_message) {
	if (!ENABLE_INFO_LOG) return;

	var _msg = "[INFO]" + get_log_tags() + " " + string(_message);
	show_debug_message(_msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_INFO, _msg);
	gmcu_log_send_telemetry(GMCU_LOG_LEVEL_INFO, _msg);
}
