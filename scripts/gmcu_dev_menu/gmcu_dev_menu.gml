// TODO All of these functions need documentation. Besides the descriptions of the parameters and return values, we also need better examples of how to use them in practice. For example, the config object that is used to configure the Dev Menu instance needs a description of its fields and what they do, as well as an example of how to create one.

function gmcu_dev_menu_action(_label, _action, _enabled = undefined) {
	return {
		type: "action",
		label: _label,
		action: _action,
		enabled: _enabled
	};
}

function gmcu_dev_menu_submenu(_label, _page_id) {
	return {
		type: "submenu",
		label: _label,
		page_id: _page_id
	};
}

function gmcu_dev_menu_toggle(_label, _get_value, _set_value) {
	return {
		type: "toggle",
		label: _label,
		get_value: _get_value,
		set_value: _set_value
	};
}

function gmcu_dev_menu_value(_label, _get_value, _change_value) {
	return {
		type: "value",
		label: _label,
		get_value: _get_value,
		change_value: _change_value
	};
}

function gmcu_dev_menu_page(_id, _title, _items = [], _get_items = undefined) {
	return {
		id: _id,
		title: _title,
		items: _items,
		get_items: _get_items
	};
}

function gmcu_dev_menu_default_trigger() {
	return keyboard_check_pressed(vk_f1);
}

/**
 * @description Returns whether the shared Dev Menu instance is currently open.
 * @returns {Bool} True when the Dev Menu owns gameplay input.
 */
function gmcu_dev_menu_is_open() {
	var _instance = instance_find(gmcu_o_dev_menu, 0);
	return _instance != noone && _instance.is_open;
}

/**
 * @description Returns whether overlay UI should block gameplay pointer interaction.
 * @returns {Bool} True when gameplay mouse/cursor clicks should be ignored.
 */
function gmcu_ui_overlay_blocks_pointer_input() {
	return gmcu_dev_menu_is_open();
}

function gmcu_dev_menu_init(_config) {
	if (!GMCU_IS_DEV_BUILD) return noone;

	var _instance = instance_find(gmcu_o_dev_menu, 0);
	if (_instance == noone) {
		_instance = instance_create_depth(0, 0, 0, gmcu_o_dev_menu);
	}
	_instance.configure(_config);
	return _instance;
}

function gmcu_dev_menu_add_rooms(_config, _settings = {}) {
	var _filter = variable_struct_exists(_settings, "filter")
		? _settings.filter
		: function(_room) { return true; };
	var _label = variable_struct_exists(_settings, "label")
		? _settings.label
		: function(_room) { return room_get_name(_room); };
	var _goto_room = variable_struct_exists(_settings, "goto_room")
		? _settings.goto_room
		: function(_room) { room_goto(_room); };

	var _items = [];
	var _room = room_first;
	while (_room != -1) {
		if (_filter(_room)) {
			array_push(_items, {
				type: "room",
				label: _label(_room),
				target_room: _room,
				goto_room: _goto_room
			});
		}
		_room = room_next(_room);
	}

	if (variable_struct_exists(_settings, "sort") && _settings.sort) {
		array_sort(_items, function(_a, _b) {
			if (_a.label == _b.label) return 0;
			return _a.label < _b.label ? -1 : 1;
		});
	}

	array_push(_config.pages, gmcu_dev_menu_page("gmcu_rooms", "Rooms", _items));
	array_push(_config.pages[0].items, gmcu_dev_menu_submenu("Rooms", "gmcu_rooms"));
	return _config;
}

function gmcu_dev_menu_add_languages(_config, _settings) {
	var _page = gmcu_dev_menu_page("gmcu_languages", "Language");
	_page.type = "languages";
	_page.get_languages = _settings.get_languages;
	_page.get_current = _settings.get_current;
	_page.set_language = _settings.set_language;
	array_push(_config.pages, _page);
	array_push(_config.pages[0].items, gmcu_dev_menu_submenu("Language", "gmcu_languages"));
	return _config;
}

function gmcu_dev_menu_add_logs(_config) {
	var _page = gmcu_dev_menu_page("gmcu_logs", "Logs");
	_page.type = "logs";
	array_push(_config.pages, _page);
	array_push(_config.pages[0].items, gmcu_dev_menu_submenu("Logs", "gmcu_logs"));
	return _config;
}
