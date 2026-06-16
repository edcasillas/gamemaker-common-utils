event_inherited();
if(!created) { return; } // instance_destroy was called on parent.

gmcu_universal_cursor_subscribe(button_id);

gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEFAULT, button_id);
function on_draw_gui() { 
	do_draw();

	// Uncomment to debug bounding box
	//draw_set_color(c_red);
	//draw_rectangle(_button_x, _button_y, _button_x + _button_width, _button_y + _button_height, true);
}
