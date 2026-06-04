function gmcu_universal_cursor_show(_sprite_index) {
	if(!instance_exists(gmcu_o_universal_cursor)) {
		instance_create_depth(0, 0, 0, gmcu_o_universal_cursor);
	}
	gmcu_o_universal_cursor.sprite_index = _sprite_index;
	gmcu_o_universal_cursor.visible = true;
	window_set_cursor(cr_none); // Hide the default cursor.
}
