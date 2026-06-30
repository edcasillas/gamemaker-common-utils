/**
 * Creates one GUI-space label instance and applies its runtime text settings.
 * @param {String} _text Literal text or localization key assigned to the label.
 * @param {Bool} _translate Whether the label should resolve `_text` through localization.
 * @param {Real} _pos_x GUI x position.
 * @param {Real} _pos_y GUI y position.
 * @param {Struct} _config Consumer-owned visual settings.
 * @returns {gmcu_o_label_gui}
 */
function gmcu_create_label_gui(_text, _translate, _pos_x, _pos_y, _config = {}) {
	var _label = instance_create_depth(0, 0, 0, gmcu_o_label_gui);

	_label.text = _text;
	_label.translate = _translate;
	_label.actual_text = _translate ? gmcu_localization_t(_text) : _text;
	_label.pos_x = _pos_x;
	_label.pos_y = _pos_y;

	if(variable_struct_exists(_config, "font")) {
		_label.font = _config.font;
	}

	if(variable_struct_exists(_config, "text_scale")) {
		_label.text_scale = _config.text_scale;
	}

	if(variable_struct_exists(_config, "text_valign")) {
		_label.text_valign = _config.text_valign;
	}

	if(variable_struct_exists(_config, "color")) {
		_label.color = _config.color;
	}

	if(variable_struct_exists(_config, "outline_thickness")) {
		_label.outline_thickness = _config.outline_thickness;
	}

	if(variable_struct_exists(_config, "outline_color")) {
		_label.outline_color = _config.outline_color;
	}

	if(variable_struct_exists(_config, "gui_layer")) {
		_label.gui_layer = _config.gui_layer;
	}

	return _label;
}
