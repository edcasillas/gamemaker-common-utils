function gmcu_universal_cursor_hide(_restore_system_cursor = true) {
	if(instance_exists(gmcu_o_universal_cursor)) {
		gmcu_o_universal_cursor.visible = false;
	}
	
	if(_restore_system_cursor) {
		window_set_cursor(cr_default);
	}
}
