#macro GMCU_ENABLE_DEBUG_LOG false
#macro DevBuild:GMCU_ENABLE_DEBUG_LOG true

#macro GMCU_ENABLE_INFO_LOG true
#macro GMCU_ENABLE_WARN_LOG true
#macro GMCU_ENABLE_ERROR_LOG true

#macro GMCU_LOG_LEVEL_DEBUG "debug"
#macro GMCU_LOG_LEVEL_INFO "info"
#macro GMCU_LOG_LEVEL_WARN "warn"
#macro GMCU_LOG_LEVEL_ERROR "error"
#macro GMCU_LOG_LEVEL_EXCEPTION "exception"

global.gmcu_log_telemetry_handler = undefined;
global.gmcu_log_telemetry_dispatching = false;
global.gmcu_log_output_handler = undefined;
global.gmcu_log_output_dispatching = false;

/**
 * @description Sets the optional handler used to write log messages to a target-specific output.
 * @param {function} _handler Function receiving severity and formatted message strings.
 */
function gmcu_log_set_output_handler(_handler) {
	global.gmcu_log_output_handler = _handler;
	global.gmcu_log_output_dispatching = false;
}

/**
 * @description Writes a formatted log message through the configured output handler, falling back to GameMaker debug output.
 * @param {string} _severity Common Utils log severity.
 * @param {string} _message Fully formatted log message.
 */
function gmcu_log_write_output(_severity, _message) {
	if (!variable_global_exists("gmcu_log_output_handler") || is_undefined(global.gmcu_log_output_handler)) {
		show_debug_message(_message);
		return;
	}
	if (!variable_global_exists("gmcu_log_output_dispatching")) {
		global.gmcu_log_output_dispatching = false;
	}
	if (global.gmcu_log_output_dispatching) {
		show_debug_message(_message);
		return;
	}

	global.gmcu_log_output_dispatching = true;
	try {
		var _handler = global.gmcu_log_output_handler;
		_handler(_severity, _message);
	} catch (_exception) {
		show_debug_message(_message);
		show_debug_message(
			"[ERROR]" + gmcu_log_get_tags()
			+ " Logging output handler failed: " + string(_exception)
		);
	}
	global.gmcu_log_output_dispatching = false;
}

/**
 * @description Sets the optional handler used to forward logs to telemetry services.
 * @param {function} _handler Function receiving severity and formatted message strings.
 */
function gmcu_log_set_telemetry_handler(_handler) {
	global.gmcu_log_telemetry_handler = _handler;
	global.gmcu_log_telemetry_dispatching = false;
	show_debug_message("[INFO]" + gmcu_log_get_tags() + " Telemetry handler has been set.");
}

/**
 * @description Sends a formatted log message to the configured telemetry handler with recursion protection.
 * @param {string} _severity Common Utils log severity.
 * @param {string} _message Fully formatted log message.
 */
function gmcu_log_send_telemetry(_severity, _message) {
	if (!variable_global_exists("gmcu_log_telemetry_handler")) return;
	if (is_undefined(global.gmcu_log_telemetry_handler)) return;
	if (!variable_global_exists("gmcu_log_telemetry_dispatching")) {
		global.gmcu_log_telemetry_dispatching = false;
	}
	if (global.gmcu_log_telemetry_dispatching) return;

	global.gmcu_log_telemetry_dispatching = true;
	try {
		var _handler = global.gmcu_log_telemetry_handler;
		_handler(_severity, _message);
	} catch (_exception) {
		show_debug_message(
			"[ERROR]" + gmcu_log_get_tags()
			+ " Logging telemetry handler failed: " + string(_exception)
		);
	}
	global.gmcu_log_telemetry_dispatching = false;
}

/**
 * @description Initializes or repairs the development log ring buffer and its capacity.
 */
function gmcu_log_buffer_ensure_initialized() {
	if (!variable_global_exists("gmcu_log_buffer") || !is_array(global.gmcu_log_buffer)) {
		global.gmcu_log_buffer = [];
	}
	if (!variable_global_exists("gmcu_log_buffer_capacity")
		|| !is_real(global.gmcu_log_buffer_capacity)) {
		global.gmcu_log_buffer_capacity = 200;
	}
}

/**
 * @description Initializes or repairs the built-in Dev Menu log severity filter state.
 */
function gmcu_log_viewer_filters_ensure_initialized() {
	if (!variable_global_exists("gmcu_log_viewer_filters") || !is_struct(global.gmcu_log_viewer_filters)) {
		gmcu_log_viewer_filters_reset();
		return;
	}

	var _filters = global.gmcu_log_viewer_filters;
	if (!variable_struct_exists(_filters, GMCU_LOG_LEVEL_DEBUG)) _filters[$ GMCU_LOG_LEVEL_DEBUG] = true;
	if (!variable_struct_exists(_filters, GMCU_LOG_LEVEL_INFO)) _filters[$ GMCU_LOG_LEVEL_INFO] = true;
	if (!variable_struct_exists(_filters, GMCU_LOG_LEVEL_WARN)) _filters[$ GMCU_LOG_LEVEL_WARN] = true;
	if (!variable_struct_exists(_filters, GMCU_LOG_LEVEL_ERROR)) _filters[$ GMCU_LOG_LEVEL_ERROR] = true;
	if (!variable_struct_exists(_filters, GMCU_LOG_LEVEL_EXCEPTION)) _filters[$ GMCU_LOG_LEVEL_EXCEPTION] = true;
}

/**
 * @description Resets the built-in Dev Menu log severity filters to show every severity.
 * @returns {Struct} Current severity filter struct.
 */
function gmcu_log_viewer_filters_reset() {
	global.gmcu_log_viewer_filters = {
		debug: true,
		info: true,
		warn: true,
		error: true,
		exception: true
	};
	return global.gmcu_log_viewer_filters;
}

/**
 * @description Returns the built-in Dev Menu log severity filters.
 * @returns {Struct} Filter flags keyed by GMCU_LOG_LEVEL_* values.
 */
function gmcu_log_viewer_filters_get() {
	gmcu_log_viewer_filters_ensure_initialized();
	return global.gmcu_log_viewer_filters;
}

/**
 * @description Returns whether a given log severity should be visible in the built-in Dev Menu log page.
 * @param {string} _level Common Utils log severity.
 * @returns {Bool} True when entries of this severity should be shown.
 */
function gmcu_log_viewer_filters_is_level_visible(_level) {
	var _filters = gmcu_log_viewer_filters_get();
	if (!variable_struct_exists(_filters, _level)) return true;
	return _filters[$ _level];
}

/**
 * @description Toggles one built-in Dev Menu log severity filter.
 * @param {string} _level Common Utils log severity.
 * @returns {Bool} New enabled state for the severity.
 */
function gmcu_log_viewer_filters_toggle_level(_level) {
	var _filters = gmcu_log_viewer_filters_get();
	if (!variable_struct_exists(_filters, _level)) return true;
	_filters[$ _level] = !_filters[$ _level];
	return _filters[$ _level];
}

/**
 * @description Appends a structured entry to the bounded development log ring buffer.
 * @param {string} _level Common Utils log severity.
 * @param {string} _message Fully formatted log message.
 */
function gmcu_log_buffer_push(_level, _message) {
	if (!GMCU_IS_DEV_BUILD) return;
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

/**
 * @description Removes every entry from the development log ring buffer.
 */
function gmcu_log_buffer_clear() {
	gmcu_log_buffer_ensure_initialized();
	global.gmcu_log_buffer = [];
}

/**
 * @description Returns the current structured development log entries.
 * @returns {Array<Struct>} Log entries containing level, message, and time_ms.
 */
function gmcu_log_buffer_get() {
	gmcu_log_buffer_ensure_initialized();
	return global.gmcu_log_buffer;
}

/**
 * @description Sets the maximum development log count and removes oldest overflow entries.
 * @param {Real} _capacity Maximum number of entries to retain.
 */
function gmcu_log_buffer_set_capacity(_capacity) {
	gmcu_log_buffer_ensure_initialized();
	global.gmcu_log_buffer_capacity = max(1, floor(_capacity));
	var _overflow = array_length(global.gmcu_log_buffer) - global.gmcu_log_buffer_capacity;
	if (_overflow > 0) {
		array_delete(global.gmcu_log_buffer, 0, _overflow);
	}
}
