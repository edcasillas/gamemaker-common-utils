/**
 * @description Creates a clickable/selectable row that runs a callback when activated.
 * @param {String} _label Visible row label.
 * @param {Function} _action Callback executed on activation.
 * @param {Function|Undefined} _enabled Optional predicate; false disables the row.
 * @returns {Struct}
 */
function gmcu_dev_menu_action(_label, _action, _enabled = undefined) {
	return {
		type: "action",
		label: _label,
		action: _action,
		enabled: _enabled
	};
}

/**
 * @description Creates a selectable row that queues a callback to run after the Dev Menu closes.
 * @param {String} _label Visible row label and queued-action label.
 * @param {Function} _action Callback executed after the menu closes.
 * @param {Function|Undefined} _enabled Optional predicate; false disables the row.
 * @returns {Struct}
 */
function gmcu_dev_menu_deferred_action(_label, _action, _enabled = undefined) {
	return {
		type: "deferred_action",
		label: _label,
		action: _action,
		enabled: _enabled
	};
}

/**
 * @description Creates a row that opens another Dev Menu page.
 * @param {String} _label Visible row label.
 * @param {String} _page_id Target page id.
 * @returns {Struct}
 */
function gmcu_dev_menu_submenu(_label, _page_id) {
	return {
		type: "submenu",
		label: _label,
		page_id: _page_id
	};
}

/**
 * @description Creates a boolean row that toggles through getter/setter callbacks.
 * @param {String} _label Visible row label.
 * @param {Function} _get_value Returns the current boolean value.
 * @param {Function} _set_value Receives the next boolean value.
 * @returns {Struct}
 */
function gmcu_dev_menu_toggle(_label, _get_value, _set_value) {
	return {
		type: "toggle",
		label: _label,
		get_value: _get_value,
		set_value: _set_value
	};
}

/**
 * @description Creates a value row that changes with left/right input.
 * @param {String} _label Visible row label.
 * @param {Function} _get_value Returns the current visible value.
 * @param {Function} _change_value Receives -1 or 1 from left/right activation.
 * @returns {Struct}
 */
function gmcu_dev_menu_value(_label, _get_value, _change_value) {
	return {
		type: "value",
		label: _label,
		get_value: _get_value,
		change_value: _change_value
	};
}

/**
 * @description Creates a Dev Menu page with a fixed array of items.
 * @param {String} _id Stable page id used by submenus.
 * @param {String} _title Page header text.
 * @param {Array<Struct>} _items Static page items.
 * @returns {Struct}
 */
function gmcu_dev_menu_static_page(_id, _title, _items = []) {
	return {
		id: _id,
		title: _title,
		items: _items
	};
}

/**
 * @description Creates a Dev Menu page whose items are rebuilt by a callback.
 * @param {String} _id Stable page id used by submenus.
 * @param {String} _title Page header text.
 * @param {Function} _build_items_func Callback returning the current item array.
 * @returns {Struct}
 */
function gmcu_dev_menu_dynamic_page(_id, _title, _build_items_func) {
	return {
		id: _id,
		title: _title,
		build_items_func: _build_items_func
	};
}

/**
 * @description Appends an item to the root page, supporting both static and dynamic roots.
 * @param {Struct} _config Dev Menu config being assembled.
 * @param {Struct} _item Root-page item to append.
 */
function gmcu_dev_menu_add_root_item(_config, _item) {
	if (array_length(_config.pages) == 0) return;

	var _root_page = _config.pages[0];
	if (!variable_struct_exists(_root_page, "root_items")) {
		_root_page.root_items = [];
	}
	array_push(_root_page.root_items, _item);
}

/**
 * @description Returns the default open/close trigger for the Dev Menu singleton.
 * @returns {Bool} True on the Step where F1 or Start was released.
 */
function gmcu_dev_menu_default_trigger() {
	var _is_open = gmcu_dev_menu_is_open();
	var _owner = _is_open ? GMCU_INPUT_OWNER_DEV_MENU : GMCU_INPUT_OWNER_GAMEPLAY;
	var _f1_released = keyboard_check_released(vk_f1);
	if (instance_exists(gmcu_o_input_hub)) {
		_f1_released = _f1_released || gmcu_o_input_hub.gmcu_keyboard_key_released(vk_f1, _owner);
		return _f1_released || gmcu_o_input_hub.gmcu_gamepad_button_released(gp_start, _owner);
	}
	return _f1_released;
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
function gmcu_ui_overlay_blocks_pointer_input() { return gmcu_dev_menu_is_open(); } // TODO Is it really necessary to have this function only pointing to another one?

/**
 * @description Creates or reconfigures the persistent Dev Menu singleton.
 * @param {Struct} _config Consumer-owned Dev Menu configuration.
 * @returns {gmcu_o_dev_menu|Real} The singleton instance, or noone outside DevBuild.
 */
function gmcu_dev_menu_init(_config) {
	if (!GMCU_IS_DEV_BUILD) return noone;

	var _instance = instance_find(gmcu_o_dev_menu, 0);
	if (_instance == noone) {
		_instance = instance_create_depth(0, 0, 0, gmcu_o_dev_menu);
	}
	_instance.configure(_config);
	return _instance;
}

/**
 * @description Adds a generated room-navigation page and root submenu entry.
 * @param {Struct} _config Dev Menu config being assembled.
 * @param {Struct} _settings Optional room adapter callbacks and filters.
 * @returns {Struct}
 */
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

	array_push(_config.pages, gmcu_dev_menu_static_page("gmcu_rooms", "Rooms", _items));
	gmcu_dev_menu_add_root_item(_config, gmcu_dev_menu_submenu("Rooms", "gmcu_rooms"));
	return _config;
}

/**
 * @description Adds a generated language-selection page and root submenu entry.
 * @param {Struct} _config Dev Menu config being assembled.
 * @param {Struct} _settings Language provider callbacks.
 * @returns {Struct}
 */
function gmcu_dev_menu_add_languages(_config, _settings) {
	var _page = gmcu_dev_menu_static_page("gmcu_languages", "Language");
	_page.type = "languages";
	_page.get_languages = _settings.get_languages;
	_page.get_current = _settings.get_current;
	_page.set_language = _settings.set_language;
	array_push(_config.pages, _page);
	gmcu_dev_menu_add_root_item(_config, gmcu_dev_menu_submenu("Language", "gmcu_languages"));
	return _config;
}

/**
 * @description Adds the built-in log viewer page and root submenu entry.
 * @param {Struct} _config Dev Menu config being assembled.
 * @returns {Struct}
 */
function gmcu_dev_menu_add_logs(_config) {
	var _page = gmcu_dev_menu_static_page("gmcu_logs", "Logs");
	_page.type = "logs";
	array_push(_config.pages, _page);
	gmcu_dev_menu_add_root_item(_config, gmcu_dev_menu_submenu("Logs", "gmcu_logs"));
	return _config;
}
