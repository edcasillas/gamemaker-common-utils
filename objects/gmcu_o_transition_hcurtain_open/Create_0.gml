curtain_size = window_get_width() / 2;

gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_TRANSITION_OVERLAY, "Transition Curtain Open");

/**
 * @description Draws the opening curtain through LayeredGUI or direct Draw GUI fallback.
 */
function on_draw_gui() {
	var _previous_drawing_parameters = new gmcu_DrawingParameters();

	draw_set_color(c_black);
	draw_rectangle(0, 0, curtain_size, window_get_height(), false);
	draw_rectangle(
		window_get_width() - curtain_size,
		0,
		window_get_width(),
		window_get_height(),
		false
	);

	_previous_drawing_parameters.apply();
}
