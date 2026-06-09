/**
 * @description Subscribes the calling instance to the Universal Cursor.
 * @param {String|Undefined} _diagnostic_name Optional instance label for diagnostics.
 */
function gmcu_universal_cursor_subscribe(_diagnostic_name = undefined) {
	if(!instance_exists(gmcu_o_universal_cursor)) {
		instance_create_depth(0, 0, 0, gmcu_o_universal_cursor);
	}
	gmcu_o_universal_cursor.subscribe(self, _diagnostic_name);
	gmcu_log_debug("Subscribed to universal cursor");
}
