/**
 * @description Routes Common Utils log output to the browser console with per-severity mapping when running on HTML5.
 */
function gmcu_html5_use_browser_console_for_logging() {
	if (os_browser == browser_not_a_browser) return;

	gmcu_log_set_output_handler(function(_severity, _message) {
		switch(_severity) {
			case GMCU_LOG_LEVEL_DEBUG:
				gmcu_html5_console_debug(_message);
				break;
			case GMCU_LOG_LEVEL_INFO:
				gmcu_html5_console_info(_message);
				break;
			case GMCU_LOG_LEVEL_WARN:
				gmcu_html5_console_warn(_message);
				break;
			default:
				gmcu_html5_console_error(_message);
				break;
		}
	});
}
