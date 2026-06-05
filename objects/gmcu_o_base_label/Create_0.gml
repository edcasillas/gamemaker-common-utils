actual_text = text;
if(translate) {	actual_text = gmcu_localization_t(text); }

function do_draw() {
	var _draw_params = new DrawingParameters(); 

	draw_set_color(color);
	draw_set_font(font);
	draw_set_halign(fa_center);
	draw_text(pos_x, pos_y, actual_text);

	_draw_params.apply();
}
