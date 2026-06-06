global.gmcu_language = "";
global.gmcu_loc_map = undefined;

/**
@description Loads a consumer-owned localization CSV and selects the requested or operating-system language.
@param {string} _lang_code Two-digit language code, or undefined to get the language code from the running OS.
@param {string} _csv_file_name Name of the included CSV file containing the translations. Defaults to localization.csv.
@returns {Bool} Whether the localization table was loaded successfully.
*/
function gmcu_localization_init(_lang_code = undefined, _csv_file_name = "localization.csv") {
	if(is_undefined(_lang_code)) {
		global.gmcu_language = os_get_language();
	} else {
		global.gmcu_language = _lang_code;
	}
	
	if(!file_exists(_csv_file_name)) {
		log_error("File " + _csv_file_name + " does not exist. Aborting localization initialization.");
		return false;
	}
	
	var file_grid = load_csv(_csv_file_name);
	var ww = ds_grid_width(file_grid);
	var hh = ds_grid_height(file_grid);
	
	var _lang_col_index = 1; // Start searching in column #1, since column #0 contains the keys.
	while(_lang_col_index < ww && file_grid[# _lang_col_index, 0] != global.gmcu_language) {
		_lang_col_index++;
	}
	
	if(_lang_col_index == ww) {
		log_error("Could not find language definition for lang code " + global.gmcu_language + " in file " + _csv_file_name);
		return false;
	}
	
	if(!is_undefined(global.gmcu_loc_map) && ds_exists(global.gmcu_loc_map, ds_type_map)) {
		ds_map_destroy(global.gmcu_loc_map);
	}
	
	global.gmcu_loc_map = ds_map_create();
	
	for(var _i = 1; _i < hh; _i++) {
		try {
			var _key = file_grid[# 0, _i];
			var _value = file_grid[# _lang_col_index, _i];
			
			if(_key == "") {
				log_error("Localization file " + _csv_file_name + " contains invalid empty key.");
				continue;
			}
			
			if(_value == "") {
				log_error("Localization file " + _csv_file_name + " contains invalid empty value for key '" + _key + "'");
				continue;
			}
			
			ds_map_add(global.gmcu_loc_map, _key, _value);
		} catch (_exception) {
			log_exception(_exception);
		}
	}	
	
	log_info("Localization engine has been initialized for language " + string(global.gmcu_language));
	return true;
}
