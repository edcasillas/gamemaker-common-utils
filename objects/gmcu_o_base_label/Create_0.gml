actual_text = text;
if(translate) {
	actual_text = gmcu_localization_t(text);
}

draw_alpha = 1;
draw_offset_x = 0;
draw_offset_y = 0;
label_effects = [];

function do_draw() {
	var _draw_params = new gmcu_DrawingParameters();

	draw_set_alpha(draw_alpha);
	draw_set_color(color);
	draw_set_font(font);
	draw_set_halign(fa_center);
	draw_set_valign(text_valign);
	draw_text_transformed(
		pos_x + draw_offset_x,
		pos_y + draw_offset_y,
		actual_text,
		text_scale,
		text_scale,
		0
	);

	_draw_params.apply();
}
