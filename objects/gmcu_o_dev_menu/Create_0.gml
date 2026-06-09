if (instance_number(object_index) > 1) {
	instance_destroy();
	return;
}

persistent = true;
is_open = false;
config = undefined;
pages = [];
page_stack = [];
selected_index = 0;
scroll_offset = 0;
row_height = 28;
header_height = 54;
panel_margin = 24;
last_mouse_x = -1;
last_mouse_y = -1;
mouse_active = false;
layered_gui_available = false;
layered_gui_items = [];

/**
 * @description Applies Dev Menu pages, callbacks, input behavior, and visual theme defaults.
 * @param {Struct} _config Declarative Dev Menu configuration.
 */
function configure(_config) {
	config = _config;
	pages = variable_struct_exists(config, "pages") ? config.pages : [];
	if (array_length(pages) == 0) {
		pages = [gmcu_dev_menu_page("main", "Dev Menu")];
	}
	var _has_layered_gui_page = false;
	for (var _i = 0; _i < array_length(pages); _i++) {
		if (pages[_i].id == "gmcu_layered_gui") {
			_has_layered_gui_page = true;
			break;
		}
	}
	if (!_has_layered_gui_page) {
		array_push(pages, gmcu_dev_menu_page("gmcu_layered_gui", "Layered GUI"));
		pages[array_length(pages) - 1].type = "layered_gui";
	}
	if (!variable_struct_exists(config, "trigger_pressed")) {
		config.trigger_pressed = gmcu_dev_menu_default_trigger;
	}
	if (!variable_struct_exists(config, "block_game_instances")) {
		config.block_game_instances = true;
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

function current_page() {
	if (array_length(page_stack) == 0) return pages[0];
	return get_page(page_stack[array_length(page_stack) - 1]);
}

/**
 * @description Builds the visible item array for the current static or generated Dev Menu page.
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
		}
	}
	var _items = !is_undefined(_page.get_items) ? _page.get_items() : _page.items;
	if (_page.id == pages[0].id && layered_gui_available) {
		var _root_items = [];
		for (var _i = 0; _i < array_length(_items); _i++) {
			array_push(_root_items, _items[_i]);
		}
		_items = _root_items;
		array_push(_items, gmcu_dev_menu_submenu("Layered GUI", "gmcu_layered_gui"));
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
 * @description Opens the modal Dev Menu and snapshots optional diagnostic modules.
 */
function open_menu() {
	if (is_open || is_undefined(config)) return;
	refresh_layered_gui_items();
	is_open = true;
	page_stack = [pages[0].id];
	selected_index = 0;
	scroll_offset = 0;
	if (config.block_game_instances) {
		instance_deactivate_all(true);
		instance_activate_object(gmcu_o_notification_from_top);
	}
	try {
		if (variable_struct_exists(config, "on_open")) config.on_open();
		if (variable_struct_exists(config, "pause")) config.pause();
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_o_dev_menu.open_menu");
	}
}

function close_menu(_notify = true) {
	if (!is_open) return;
	is_open = false;
	page_stack = [];
	if (config.block_game_instances) {
		instance_activate_all();
	}
	if (_notify) {
		try {
			if (variable_struct_exists(config, "resume")) config.resume();
			if (variable_struct_exists(config, "on_close")) config.on_close();
		} catch (_exception) {
			gmcu_log_exception(_exception, "gmcu_o_dev_menu.close_menu");
		}
	}
}

function push_page(_page_id) {
	if (is_undefined(get_page(_page_id))) return;
	array_push(page_stack, _page_id);
	selected_index = 0;
	scroll_offset = 0;
}

function go_back() {
	if (array_length(page_stack) <= 1) {
		close_menu();
		return;
	}
	array_pop(page_stack);
	selected_index = 0;
	scroll_offset = 0;
}

function item_enabled(_item) {
	if (!variable_struct_exists(_item, "enabled") || is_undefined(_item.enabled)) return true;
	return _item.enabled();
}

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

function move_selection(_delta) {
	var _items = current_items();
	var _count = array_length(_items);
	if (_count == 0) return;
	selected_index = (selected_index + _delta + _count) mod _count;
}
