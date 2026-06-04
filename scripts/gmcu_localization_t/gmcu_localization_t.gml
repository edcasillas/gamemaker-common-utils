/**
Localizes _str to the language currently set in the localization engine.
*/
function gmcu_localization_t(_str) {
	if(!GMCU_LOCALIZATION_IS_INITIALIZED) {
		log_warn("Localization engine has not been initialized.");
		return _str;
	}
	
	if(!ds_map_exists(global.gmcu_loc_map, _str)) {
		log_warn("Key '" + _str + "' was not found in localization file for language " + global.gmcu_language);
		return _str;
	}
	
	return global.gmcu_loc_map[? _str];
}
