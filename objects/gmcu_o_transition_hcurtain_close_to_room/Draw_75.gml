var _previous_drawing_parameters = new DrawingParameters();

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
