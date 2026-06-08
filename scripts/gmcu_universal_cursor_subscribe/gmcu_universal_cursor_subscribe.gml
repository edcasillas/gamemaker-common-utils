function gmcu_universal_cursor_subscribe() {
	if(!instance_exists(gmcu_o_universal_cursor)) {
		instance_create_depth(0, 0, 0, gmcu_o_universal_cursor);
	}
	gmcu_o_universal_cursor.subscribe(self);
	gmcu_log_debug("Subscribed to universal cursor");
}
