var _previous_drawing_parameters = new DrawingParameters();

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
