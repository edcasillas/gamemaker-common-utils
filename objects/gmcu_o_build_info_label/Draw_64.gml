var _prev_draw_params = new DrawingParameters();

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

draw_set_color(c_black);
draw_rectangle(_gui_w - string_width(text), _gui_h - string_height(text), _gui_w, _gui_h, false);

draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text(_gui_w, _gui_h, text);
_prev_draw_params.apply();
