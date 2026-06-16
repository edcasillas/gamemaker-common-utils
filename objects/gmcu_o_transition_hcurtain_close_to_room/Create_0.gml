event_inherited();

curtain_size = 0;
max_curtain_size = window_get_width() / 2;

gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_TRANSITION_OVERLAY, "Transition Curtain Close");

gmcu_consumer_on_progress = on_progress;
on_progress = function(_current_transition_progress) {
	curtain_size = max_curtain_size * _current_transition_progress;
	gmcu_consumer_on_progress(_current_transition_progress);
};

/**
 * @description Draws the closing curtain through LayeredGUI or direct Draw GUI fallback.
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
