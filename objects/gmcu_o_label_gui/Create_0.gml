event_inherited();

gmcu_layered_gui_subscribe(gui_layer);
function on_draw_gui() {
	var _draw_params = new gmcu_DrawingParameters();

	draw_set_font(font);
	draw_set_halign(fa_center);
	draw_set_valign(text_valign);
	draw_set_color(color);
	draw_set_alpha(draw_alpha);
	gmcu_draw_text_outlined(
		pos_x + draw_offset_x,
		pos_y + draw_offset_y,
		actual_text,
		outline_thickness,
		outline_color,
		text_scale
	);

	_draw_params.apply();
}
