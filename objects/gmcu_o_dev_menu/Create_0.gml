if (instance_number(object_index) > 1) {
	instance_destroy();
	return;
}

persistent = true;
is_open = false;
config = undefined; // Consumer-owned configuration passed through gmcu_dev_menu_init.
pages = [];
page_stack = []; // Page id stack; root page lives at index 0.
selected_index = 0; // Index inside the current visible items array.
scroll_offset = 0; // First visible row index for long pages.
row_height = 28;
header_height = 54;
panel_margin = 24;
last_mouse_x = -1;
last_mouse_y = -1;
mouse_active = false; // True after the mouse moves; false after d-pad/keyboard navigation.
layered_gui_available = false;
layered_gui_items = [];
universal_cursor_available = false;
universal_cursor_items = [];

gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEV_MENU, "Dev Menu");

/**
 * @description Draws the Dev Menu overlay through Layered GUI or direct Draw GUI fallback.
 */
function on_draw_gui() {
	if (!is_open) return;

	var _draw_params = new gmcu_DrawingParameters();
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

		var _text_color = _theme.text_color;
		if (variable_struct_exists(_item, "level")) {
			switch (_item.level) {
				case GMCU_LOG_LEVEL_INFO:
					_text_color = _theme.log_info_color;
					break;
				case GMCU_LOG_LEVEL_WARN:
					_text_color = _theme.log_warn_color;
					break;
				case GMCU_LOG_LEVEL_ERROR:
				case GMCU_LOG_LEVEL_EXCEPTION:
					_text_color = _theme.log_error_color;
					break;
				default:
					_text_color = _theme.log_debug_color;
					break;
			}
		}
		draw_set_color(_enabled ? _text_color : _theme.muted_color);
		var _label = _item.label;
		if (_item.type == "submenu") _label += " >";
		if (_item.type == "toggle") _label += ": " + (_item.get_value() ? "ON" : "OFF");
		if (_item.type == "value") _label += ": " + string(_item.get_value());
		draw_text(_panel_x + 18, (_y1 + _y2) * 0.5, _label);
	}

	draw_set_color(_theme.muted_color);
	draw_set_halign(fa_right);
	var _help = "F1/Esc/B: Back";
	if (array_length(_items) > 0
		&& selected_index >= 0
		&& selected_index < array_length(_items)
		&& _items[selected_index].type == "copy_text") {
		_help = "Enter/A/Click: Copy | " + _help;
	}
	draw_text(_panel_x + _panel_w - 18, _panel_y + header_height * 0.5, _help);
	_draw_params.apply();
}

/**
 * @description Applies Dev Menu pages, trigger behavior, and visual theme defaults.
 * @param {Struct} _config Declarative Dev Menu configuration.
 */
function configure(_config) {
	config = _config;
	pages = variable_struct_exists(config, "pages") ? config.pages : [];
	if (array_length(pages) == 0) {
		pages = [gmcu_dev_menu_static_page("main", "Dev Menu")];
	}
	var _has_layered_gui_page = false;
	var _has_universal_cursor_page = false;
	for (var _i = 0; _i < array_length(pages); _i++) {
		if (pages[_i].id == "gmcu_layered_gui") {
			_has_layered_gui_page = true;
		}
		if (pages[_i].id == "gmcu_universal_cursor") {
			_has_universal_cursor_page = true;
		}
	}
	if (!_has_layered_gui_page) {
		array_push(pages, gmcu_dev_menu_static_page("gmcu_layered_gui", "Layered GUI"));
		pages[array_length(pages) - 1].type = "layered_gui";
	}
	if (!_has_universal_cursor_page) {
		array_push(pages, gmcu_dev_menu_static_page("gmcu_universal_cursor", "Universal Cursor"));
		pages[array_length(pages) - 1].type = "universal_cursor";
	}
	if (!variable_struct_exists(config, "trigger_pressed")) {
		config.trigger_pressed = gmcu_dev_menu_default_trigger;
	}
	if (!variable_struct_exists(config, "theme")) config.theme = {};
	var _theme = config.theme;
	if (!variable_struct_exists(_theme, "overlay_color")) _theme.overlay_color = c_black;
	if (!variable_struct_exists(_theme, "overlay_alpha")) _theme.overlay_alpha = 0.82;
	if (!variable_struct_exists(_theme, "panel_color")) _theme.panel_color = make_color_rgb(20, 24, 32);
	if (!variable_struct_exists(_theme, "selected_color")) _theme.selected_color = make_color_rgb(55, 90, 145);
	if (!variable_struct_exists(_theme, "text_color")) _theme.text_color = c_white;
	if (!variable_struct_exists(_theme, "muted_color")) _theme.muted_color = make_color_rgb(160, 165, 175);
	if (!variable_struct_exists(_theme, "log_debug_color")) _theme.log_debug_color = c_white;
	if (!variable_struct_exists(_theme, "log_info_color")) _theme.log_info_color = _theme.muted_color;
	if (!variable_struct_exists(_theme, "log_warn_color")) _theme.log_warn_color = c_yellow;
	if (!variable_struct_exists(_theme, "log_error_color")) _theme.log_error_color = c_red;
	if (!variable_struct_exists(_theme, "font")) _theme.font = -1;
	close_menu(false);
}

function get_page(_id) {
	for (var _i = 0; _i < array_length(pages); _i++) {
		if (pages[_i].id == _id) return pages[_i];
	}
	return undefined;
}

/**
 * @description Returns the page currently being shown by the menu stack.
 * @returns {Struct|Undefined}
 */
function current_page() {
	if (array_length(page_stack) == 0) return pages[0];
	return get_page(page_stack[array_length(page_stack) - 1]);
}

/**
 * @description Builds the visible item array for the current static or dynamic Dev Menu page.
 * @returns {Array<Struct>} Items ready for navigation and rendering.
 */
function current_items() {
	var _page = current_page();
	if (is_undefined(_page)) return [];
	if (variable_struct_exists(_page, "type")) {
		switch (_page.type) {
			case "languages":
				var _language_items = [];
				var _languages = _page.get_languages();
				var _current_language = _page.get_current();
				for (var _i = 0; _i < array_length(_languages); _i++) {
					var _language = _languages[_i];
					var _label = string(_language);
					if (_language == _current_language) _label = "* " + _label;
					array_push(_language_items, {
						type: "language",
						label: _label,
						language: _language,
						set_language: _page.set_language
					});
				}
				return _language_items;
			case "logs":
				var _log_items = [{
					type: "clear_logs",
					label: "Clear logs"
				}];
				var _logs = gmcu_log_buffer_get();
				for (var _j = array_length(_logs) - 1; _j >= 0; _j--) {
					var _entry = _logs[_j];
					array_push(_log_items, {
						type: "copy_text",
						label: _entry.message,
						copy_text: _entry.message,
						level: _entry.level
					});
				}
				return _log_items;
			case "layered_gui":
				return layered_gui_items;
			case "universal_cursor":
				return universal_cursor_items;
		}
	}
	var _items = variable_struct_exists(_page, "build_items_func")
		? _page.build_items_func()
		: _page.items;
	if (_page.id == pages[0].id && (layered_gui_available || universal_cursor_available)) {
		var _root_items = [];
		for (var _i = 0; _i < array_length(_items); _i++) {
			array_push(_root_items, _items[_i]);
		}
		_items = _root_items;
		if (layered_gui_available) {
			array_push(_items, gmcu_dev_menu_submenu("Layered GUI", "gmcu_layered_gui"));
		}
		if (universal_cursor_available) {
			array_push(_items, gmcu_dev_menu_submenu("Universal Cursor", "gmcu_universal_cursor"));
		}
	}
	if (_page.id == pages[0].id && variable_struct_exists(_page, "root_items")) {
		var _root_items = [];
		for (var _i = 0; _i < array_length(_items); _i++) {
			array_push(_root_items, _items[_i]);
		}
		_items = _root_items;
		for (var _j = 0; _j < array_length(_page.root_items); _j++) {
			array_push(_items, _page.root_items[_j]);
		}
	}
	return _items;
}

/**
 * @description Captures Layered GUI subscribers before modal instance deactivation.
 */
function refresh_layered_gui_items() {
	layered_gui_available = false;
	layered_gui_items = [];

	var _manager_object = asset_get_index("gmcu_o_layered_gui_manager");
	if (_manager_object == -1) return;

	var _manager = instance_find(_manager_object, 0);
	if (_manager == noone || !variable_instance_exists(_manager, "subscribers")) return;
	layered_gui_available = true;

	var _subscribers = _manager.subscribers;
	for (var _i = 0; _i < ds_list_size(_subscribers); _i++) {
		var _entry = _subscribers[| _i];
		var _subscriber = _entry.instance;
		var _label = string(_entry.priority) + " | <invalid subscriber>";
		if (_subscriber != noone && instance_exists(_subscriber)) {
			_label = string(_entry.priority)
				+ " | " + object_get_name(_subscriber.object_index);
			if (variable_struct_exists(_entry, "diagnostic_name")
				&& !is_undefined(_entry.diagnostic_name)
				&& string(_entry.diagnostic_name) != "") {
				_label += " | " + string(_entry.diagnostic_name);
			}
			_label += " | id " + string(_subscriber.id);
		}
		array_push(layered_gui_items, {
			type: "copy_text",
			label: _label,
			copy_text: _label
		});
	}

	if (array_length(layered_gui_items) == 0) {
		array_push(layered_gui_items, {
			type: "text",
			label: "No subscribers"
		});
	}
}

/**
 * @description Captures Universal Cursor subscribers before modal instance deactivation.
 */
function refresh_universal_cursor_items() {
	universal_cursor_available = false;
	universal_cursor_items = [];

	var _cursor_object = asset_get_index("gmcu_o_universal_cursor");
	if (_cursor_object == -1) return;

	var _cursor = instance_find(_cursor_object, 0);
	if (_cursor == noone || !variable_instance_exists(_cursor, "interactables")) return;
	universal_cursor_available = true;

	var _interactables = _cursor.interactables;
	for (var _i = 0; _i < ds_list_size(_interactables); _i++) {
		var _entry = _interactables[| _i];
		var _interactable = _entry.instance;
		var _label = "<invalid subscriber>";
		if (_interactable != noone && instance_exists(_interactable)) {
			_label = _interactable == _cursor.hovered_interactable ? "* " : "  ";
			_label += object_get_name(_interactable.object_index);
			if (variable_struct_exists(_entry, "diagnostic_name")
				&& !is_undefined(_entry.diagnostic_name)
				&& string(_entry.diagnostic_name) != "") {
				_label += " | " + string(_entry.diagnostic_name);
			}
			_label += " | id " + string(_interactable.id);
		}
		array_push(universal_cursor_items, {
			type: "copy_text",
			label: _label,
			copy_text: _label
		});
	}

	if (array_length(universal_cursor_items) == 0) {
		array_push(universal_cursor_items, {
			type: "text",
			label: "No subscribers"
		});
	}
}

/**
 * @description Opens the Dev Menu and publishes the opened event.
 */
function open_menu() {
	if (is_open || is_undefined(config)) return;
	refresh_layered_gui_items();
	refresh_universal_cursor_items();
	is_open = true;
	page_stack = [pages[0].id];
	selected_index = 0;
	scroll_offset = 0;
	try {
		gmcu_eventbus_dispatch(GMCU_EVENT_DEV_MENU_OPENED);
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_o_dev_menu.open_menu");
	}
}

/**
 * @description Closes the menu and publishes the closed event.
 * @param {Bool} _notify Whether the closed event should be dispatched.
 */
function close_menu(_notify = true) {
	if (!is_open) return;
	is_open = false;
	page_stack = [];
	if (_notify) {
		try {
			gmcu_eventbus_dispatch(GMCU_EVENT_DEV_MENU_CLOSED);
		} catch (_exception) {
			gmcu_log_exception(_exception, "gmcu_o_dev_menu.close_menu");
		}
	}
}

/**
 * @description Pushes a page id onto the navigation stack.
 * @param {String} _page_id Page to open.
 */
function push_page(_page_id) {
	if (is_undefined(get_page(_page_id))) return;
	array_push(page_stack, _page_id);
	selected_index = 0;
	scroll_offset = 0;
}

/**
 * @description Returns to the previous page, or closes the menu from the root page.
 */
function go_back() {
	if (array_length(page_stack) <= 1) {
		close_menu();
		return;
	}
	array_pop(page_stack);
	selected_index = 0;
	scroll_offset = 0;
}

/**
 * @description Returns whether an item is currently interactive.
 * @param {Struct} _item Visible menu item.
 * @returns {Bool}
 */
function item_enabled(_item) {
	if (!variable_struct_exists(_item, "enabled") || is_undefined(_item.enabled)) return true;
	return _item.enabled();
}

/**
 * @description Activates the selected item, using direction for value rows.
 * @param {Real} _direction -1 for left, 1 for right/default activation.
 */
function activate_item(_direction = 1) {
	var _items = current_items();
	if (selected_index < 0 || selected_index >= array_length(_items)) return;
	var _item = _items[selected_index];
	if (!item_enabled(_item)) return;

	switch (_item.type) {
		case "action":
			try {
				_item.action();
			} catch (_exception) {
				gmcu_log_exception(_exception, "gmcu_o_dev_menu.activate_item");
			}
			break;
		case "room":
			try {
				_item.goto_room(_item.target_room);
			} catch (_exception) {
				gmcu_log_exception(_exception, "gmcu_o_dev_menu.activate_room");
			}
			break;
		case "language":
			try {
				_item.set_language(_item.language);
			} catch (_exception) {
				gmcu_log_exception(_exception, "gmcu_o_dev_menu.activate_language");
			}
			break;
		case "clear_logs":
			gmcu_log_buffer_clear();
			selected_index = 0;
			scroll_offset = 0;
			break;
		case "submenu":
			push_page(_item.page_id);
			break;
		case "toggle":
			try {
				_item.set_value(!_item.get_value());
			} catch (_exception) {
				gmcu_log_exception(_exception, "gmcu_o_dev_menu.activate_toggle");
			}
			break;
		case "value":
			try {
				_item.change_value(_direction);
			} catch (_exception) {
				gmcu_log_exception(_exception, "gmcu_o_dev_menu.activate_value");
			}
			break;
		case "copy_text":
			clipboard_set_text(_item.copy_text);
			break;
	}
}

/**
 * @description Moves selection by a signed row delta with wraparound.
 * @param {Real} _delta Signed row delta.
 */
function move_selection(_delta) {
	var _items = current_items();
	var _count = array_length(_items);
	if (_count == 0) return;
	selected_index = (selected_index + _delta + _count) mod _count;
}
