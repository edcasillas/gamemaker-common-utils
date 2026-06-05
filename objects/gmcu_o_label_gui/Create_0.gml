event_inherited();

gmcu_layered_gui_subscribe(gui_layer);
function on_draw_gui() {
	draw_set_font(font);
	draw_set_halign(fa_center);
	draw_set_color(color);
	gmcu_draw_text_outlined(pos_x, pos_y, actual_text, outline_thickness, outline_color);
}
