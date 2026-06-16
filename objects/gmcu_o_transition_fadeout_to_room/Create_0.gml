event_inherited();

gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_TRANSITION_OVERLAY, "Transition Fadeout");

/**
 * @description Draws the fadeout transition through LayeredGUI or direct Draw GUI fallback.
 */
function on_draw_gui() {
	var _previous_drawing_parameters = new gmcu_DrawingParameters();

	draw_set_alpha(transition_progress);
	draw_set_color(fade_to_color);
	draw_rectangle(
		0,
		0,
		display_get_gui_width(),
		display_get_gui_height(),
		false
	);

	_previous_drawing_parameters.apply();
}
