/**
 * @description Writes a debug message, stores it for the Dev Menu, and optionally forwards it to telemetry.
 * @param {Any} _message Value to log.
 * @param {Bool} _local_only Whether to skip telemetry forwarding.
 */
function gmcu_log_debug(_message, _local_only = false) {
	if (!GMCU_ENABLE_DEBUG_LOG) return;

	var _msg = "[DEBUG]" + gmcu_log_get_tags() + " " + string(_message);
	gmcu_log_write_output(GMCU_LOG_LEVEL_DEBUG, _msg);
	gmcu_log_buffer_push(GMCU_LOG_LEVEL_DEBUG, _msg);
	if (!_local_only) gmcu_log_send_telemetry(GMCU_LOG_LEVEL_DEBUG, _msg);
}
