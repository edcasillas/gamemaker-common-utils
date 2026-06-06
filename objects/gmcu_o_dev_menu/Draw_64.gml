if (!is_open) return;

var _draw_params = new DrawingParameters();
var _theme = config.theme;
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _panel_x = panel_margin;
var _panel_y = panel_margin;
var _panel_w = _gui_w - panel_margin * 2;
var _panel_h = _gui_h - panel_margin * 2;
var _page = current_page();
var _items = current_items();

draw_set_alpha(_theme.overlay_alpha);
draw_set_color(_theme.overlay_color);
draw_rectangle(0, 0, _gui_w, _gui_h, false);
draw_set_alpha(1);

draw_set_color(_theme.panel_color);
draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);

draw_set_font(_theme.font);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(_theme.text_color);
draw_text(_panel_x + 18, _panel_y + header_height * 0.5, _page.title);

var _visible_rows = max(1, floor((_panel_h - header_height - 12) / row_height));
if (selected_index < scroll_offset) scroll_offset = selected_index;
if (selected_index >= scroll_offset + _visible_rows) {
	scroll_offset = selected_index - _visible_rows + 1;
}
scroll_offset = clamp(scroll_offset, 0, max(0, array_length(_items) - _visible_rows));

for (var _row = 0; _row < _visible_rows; _row++) {
	var _index = scroll_offset + _row;
	if (_index >= array_length(_items)) break;
	var _item = _items[_index];
	var _y1 = _panel_y + header_height + _row * row_height;
	var _y2 = _y1 + row_height - 2;
	var _enabled = item_enabled(_item);

	if (_index == selected_index) {
		draw_set_color(_theme.selected_color);
		draw_rectangle(_panel_x + 8, _y1, _panel_x + _panel_w - 8, _y2, false);
	}

	draw_set_color(_enabled ? _theme.text_color : _theme.muted_color);
	var _label = _item.label;
	if (_item.type == "submenu") _label += " >";
	if (_item.type == "toggle") _label += ": " + (_item.get_value() ? "ON" : "OFF");
	if (_item.type == "value") _label += ": " + string(_item.get_value());
	draw_text(_panel_x + 18, (_y1 + _y2) * 0.5, _label);
}

draw_set_color(_theme.muted_color);
draw_set_halign(fa_right);
draw_text(_panel_x + _panel_w - 18, _panel_y + header_height * 0.5, "F1/Esc/B: Back");
_draw_params.apply();
