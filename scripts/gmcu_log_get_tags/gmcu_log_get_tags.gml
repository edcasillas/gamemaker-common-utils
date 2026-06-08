/**
 * A simple function to return a string with the current room and object name, for use in logging.
 *
 * Usage:
 * var log_tags = gmcu_log_get_tags();
 * show_debug_message(log_tags + " This is a log message.");
 */
function gmcu_log_get_tags() {
	return "[" + GMCU_ROOM_NAME + ":" + GMCU_OBJECT_NAME + "]";
}