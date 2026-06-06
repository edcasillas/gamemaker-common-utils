#macro ENABLE_DEBUG_LOG false
#macro DevBuild:ENABLE_DEBUG_LOG true

#macro ENABLE_INFO_LOG true
#macro ENABLE_WARN_LOG true
#macro ENABLE_ERROR_LOG true

#macro GMCU_LOG_LEVEL_DEBUG "debug"
#macro GMCU_LOG_LEVEL_INFO "info"
#macro GMCU_LOG_LEVEL_WARN "warn"
#macro GMCU_LOG_LEVEL_ERROR "error"
#macro GMCU_LOG_LEVEL_EXCEPTION "exception"

function gmcu_log_buffer_ensure_initialized() {
	if (!variable_global_exists("gmcu_log_buffer") || !is_array(global.gmcu_log_buffer)) {
		global.gmcu_log_buffer = [];
	}
	if (!variable_global_exists("gmcu_log_buffer_capacity")
		|| !is_real(global.gmcu_log_buffer_capacity)) {
		global.gmcu_log_buffer_capacity = 200;
	}
}

function gmcu_log_buffer_push(_level, _message) {
	if (!IS_DEV_BUILD) return;
	gmcu_log_buffer_ensure_initialized();

	array_push(global.gmcu_log_buffer, {
		level: _level,
		message: string(_message),
		time_ms: current_time
	});

	var _overflow = array_length(global.gmcu_log_buffer) - global.gmcu_log_buffer_capacity;
	if (_overflow > 0) {
		array_delete(global.gmcu_log_buffer, 0, _overflow);
	}
}

function gmcu_log_buffer_clear() {
	gmcu_log_buffer_ensure_initialized();
	global.gmcu_log_buffer = [];
}

function gmcu_log_buffer_get() {
	gmcu_log_buffer_ensure_initialized();
	return global.gmcu_log_buffer;
}

function gmcu_log_buffer_set_capacity(_capacity) {
	gmcu_log_buffer_ensure_initialized();
	global.gmcu_log_buffer_capacity = max(1, floor(_capacity));
	var _overflow = array_length(global.gmcu_log_buffer) - global.gmcu_log_buffer_capacity;
	if (_overflow > 0) {
		array_delete(global.gmcu_log_buffer, 0, _overflow);
	}
}
