/**
Stores the current drawing parameters so they can be restored after temporary
draw-state changes.
*/
function DrawingParameters() constructor {
	font = draw_get_font();
	color = draw_get_color();
	halign = draw_get_halign();
	valign = draw_get_valign();
	alpha = draw_get_alpha();

	static apply = function() {
		draw_set_font(font);
		draw_set_color(color);
		draw_set_halign(halign);
		draw_set_valign(valign);
		draw_set_alpha(alpha);
	}
}

