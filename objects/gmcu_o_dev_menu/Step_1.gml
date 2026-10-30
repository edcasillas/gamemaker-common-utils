/// @description Handle Inputs

// TODO Is this logic replicating the logic in the universal cursor?
// If so, maybe we should extract functions and just call them in both places.

if (is_undefined(config)) return;

if (config.trigger_pressed()) {
	if (is_open) close_menu();
	else open_menu();
	return;
}
if (!is_open) return;

#region Keyboard + Gamepad

if (check_input_pressed(vk_escape, gp_face2)) {
	go_back();
	return;
}
var _vertical_direction = check_input_down(vk_up, gp_padu)
	? -1
	: (check_input_down(vk_down, gp_padd) ? 1 : 0);

if (_vertical_direction == 0) {
	vertical_repeat_direction = 0;
} else if (_vertical_direction != vertical_repeat_direction) {
	move_selection(_vertical_direction);
	vertical_repeat_direction = _vertical_direction;
	vertical_repeat_at = current_time + 400;
	mouse_active = false;
} else if (current_time >= vertical_repeat_at) {
	move_selection(_vertical_direction);
	vertical_repeat_at = current_time + 80;
	mouse_active = false;
}

var _items = current_items();
var _selected_item = selected_index >= 0 && selected_index < array_length(_items)
	? _items[selected_index]
	: undefined;
	
var _horizontal_direction = check_input_down(vk_left, gp_padl)
	? -1
	: (check_input_down(vk_right, gp_padr) ? 1 : 0);
var _horizontal_repeated = false;

if (_horizontal_direction == 0) {
	horizontal_repeat_direction = 0;
} else if (_horizontal_direction != horizontal_repeat_direction) {
	horizontal_repeat_direction = _horizontal_direction;
	horizontal_repeat_at = current_time + 400;
	_horizontal_repeated = true;
} else if (current_time >= horizontal_repeat_at) {
	horizontal_repeat_at = current_time + 80;
	_horizontal_repeated = true;
}

if (_horizontal_repeated && _horizontal_direction < 0) {
	if (!is_undefined(_selected_item) && _selected_item.type == "log_filters") {
		log_filter_chip_index = (log_filter_chip_index - 1 + array_length(log_filter_levels)) mod array_length(log_filter_levels);
	} else {
		activate_item(-1);
	}
	mouse_active = false;
}
if (_horizontal_repeated && _horizontal_direction > 0) {
	if (!is_undefined(_selected_item) && _selected_item.type == "log_filters") {
		log_filter_chip_index = (log_filter_chip_index + 1) mod array_length(log_filter_levels);
	} else {
		activate_item(1);
	}
	mouse_active = false;
}
if (check_input_released(vk_enter, gp_face1)) {
	activate_item();
	mouse_active = false;
}

#endregion

#region Mouse

var _pointer = current_gui_pointer();
var _mouse_x = _pointer[0];
var _mouse_y = _pointer[1];
if (_mouse_x != last_mouse_x || _mouse_y != last_mouse_y) {
	last_mouse_x = _mouse_x;
	last_mouse_y = _mouse_y;
	mouse_active = true;
}

if (mouse_active) {
	var _gui_w = display_get_gui_width();
	var _gui_h = display_get_gui_height();
	var _panel_x = panel_margin;
	var _panel_y = panel_margin;
	var _panel_w = _gui_w - panel_margin * 2;
	var _list_y = _panel_y + header_height;
	var _visible_rows = max(1, floor((_gui_h - panel_margin * 2 - header_height - 12) / row_height));
	var _hover = floor((_mouse_y - _list_y) / row_height) + scroll_offset;
	var_items = current_items();
	if (_mouse_x >= _panel_x && _mouse_x <= _panel_x + _panel_w
		&& _hover >= 0 && _hover < array_length(_items)) {
		selected_index = _hover;
		var _hovered_item = _items[_hover];
		if (_hovered_item.type == "log_filters") {
			var _row = _hover - scroll_offset;
			var _y1 = _panel_y + header_height + _row * row_height;
			var _y2 = _y1 + row_height - 2;
			var _chip_x = _panel_x + 18 + 108;
			for (var _chip_i = 0; _chip_i < array_length(log_filter_levels); _chip_i++) {
				var _chip_label = string_upper(log_filter_levels[_chip_i]);
				var _chip_width = string_width(_chip_label) + 16;
				var _chip_x2 = _chip_x + _chip_width;
				if (_mouse_x >= _chip_x && _mouse_x <= _chip_x2
					&& _mouse_y >= _y1 + 5 && _mouse_y <= _y2 - 5) {
					log_filter_chip_index = _chip_i;
					if (mouse_check_button_pressed(mb_left)) {
						activate_item();
					}
					break;
				}
				_chip_x = _chip_x2 + 8;
			}
		} else if (mouse_check_button_pressed(mb_left)) {
			activate_item();
		}
	}

	var _wheel = mouse_wheel_down() - mouse_wheel_up();
	if (_wheel != 0) {
		scroll_offset = clamp(
			scroll_offset + _wheel,
			0,
			max(0, array_length(_items) - _visible_rows)
		);
	}
}

#endregion
