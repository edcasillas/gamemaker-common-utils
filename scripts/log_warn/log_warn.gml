/**
 * @description Writes a warning, stores it for the Dev Menu, and forwards it to telemetry.
 * @param {Any} _message Value to log.
 */
function log_warn(_message) {
	if (!ENABLE_WARN_LOG) return;

	var _msg = "[WARN]" + get_log_tags() + " " + string(_message);
	gmcu_log_write_output(GMCU_LOG_LEVEL_WARN, _msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_WARN, _msg);
	gmcu_log_send_telemetry(GMCU_LOG_LEVEL_WARN, _msg);
}
