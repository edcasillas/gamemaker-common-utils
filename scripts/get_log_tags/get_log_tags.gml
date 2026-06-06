/**
 * A simple function to return a string with the current room and object name, for use in logging.
 *
 * Usage:
 * var log_tags = get_log_tags();
 * show_debug_message(log_tags + " This is a log message.");
 */
function get_log_tags() {
	return "[" + ROOM_NAME + ":" + OBJECT_NAME + "]";
}