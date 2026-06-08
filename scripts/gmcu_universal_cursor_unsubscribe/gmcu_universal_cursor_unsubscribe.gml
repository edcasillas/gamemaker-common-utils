function gmcu_universal_cursor_unsubscribe() {
	if(!instance_exists(gmcu_o_universal_cursor)) {
		return;
	}
	gmcu_o_universal_cursor.unsubscribe(self);
	gmcu_log_debug("Unsubscribed from universal cursor");
}
