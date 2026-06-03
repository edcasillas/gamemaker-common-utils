box_w = display_get_gui_width() * 0.8;

var _draw_params = new DrawingParameters();
if (font != noone) draw_set_font(font);
var _text_height = string_height(text);
_draw_params.apply();

box_h = _text_height + 20;
box_x = display_get_gui_width() * 0.1;
box_y = -box_h;

current_state = 0; // 0 = enter, 1 = stay, 2 = exit

enter_speed = box_h / enter_time;
exit_speed = box_h / exit_time;
time_showing = 0;

function get_bottom_pos() {
	return offset_y + box_y + box_h;
}

function set_offset_y_recursive(_new_offset_y) {
	offset_y = _new_offset_y;
	if (next != noone && instance_exists(next)) {
		next.set_offset_y_recursive(get_bottom_pos());
	}
}

