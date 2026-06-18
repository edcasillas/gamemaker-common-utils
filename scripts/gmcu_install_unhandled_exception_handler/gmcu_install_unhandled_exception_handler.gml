/**
 * @description Builds the generic crash dialog message for an unhandled fatal error.
 * @returns {String} User-facing crash dialog message.
 */
function gmcu_crash_get_default_dialog_message() {
	var _message = game_display_name;
	if (variable_global_exists("build_number")) {
		var _build_number = global.build_number;
		if (!is_undefined(_build_number)) {
			_message += " v" + string(_build_number);
		}
	}
	_message += " has crashed. Sorry for the inconvenience.";
	return _message;
}

/**
 * @description Writes the fatal crash line through the configured logging output path.
 * @param {Any} _exception Unhandled exception value.
 * @returns {String} Formatted fatal log message.
 */
function gmcu_log_fatal(_exception) {
	var _message = "[FATAL]" + gmcu_log_get_tags() + " " + string(_exception);
	gmcu_log_write_output(GMCU_LOG_LEVEL_ERROR, _message);
	return _message;
}

/**
 * @description Installs a reusable unhandled exception flow that logs a fatal crash, runs one optional terminal callback, and shows a generic crash dialog.
 * @param {Function} _terminal_action Optional callback receiving the formatted fatal message.
 */
function gmcu_install_unhandled_exception_handler(_terminal_action = undefined) {
	exception_unhandled_handler(function(_exception) {
		var _fatal_message = gmcu_log_fatal(_exception);

		if (!is_undefined(_terminal_action)) {
			try {
				_terminal_action(_fatal_message);
			} catch (_terminal_exception) {
				gmcu_log_exception(_terminal_exception, "gmcu_install_unhandled_exception_handler", false);
			}
		}

		show_error(gmcu_crash_get_default_dialog_message(), false);
	});
}
