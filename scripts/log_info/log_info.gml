/**
 * @description Writes an informational message, stores it for the Dev Menu, and forwards it to telemetry.
 * @param {Any} _message Value to log.
 */
function log_info(_message) {
	if (!ENABLE_INFO_LOG) return;

	var _msg = "[INFO]" + get_log_tags() + " " + string(_message);
	gmcu_log_write_output(GMCU_LOG_LEVEL_INFO, _msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_INFO, _msg);
	gmcu_log_send_telemetry(GMCU_LOG_LEVEL_INFO, _msg);
}
