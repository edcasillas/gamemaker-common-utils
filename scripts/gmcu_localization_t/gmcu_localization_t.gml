/**
 * @description Returns the localized value for a key, lazily initializing the default CSV when needed.
 * @param {string} _str Localization key.
 * @returns {string} Localized value, or the original key when no translation is available.
*/
function gmcu_localization_t(_str) {
	if(!GMCU_LOCALIZATION_IS_INITIALIZED) {
		if(!gmcu_localization_init()) {
			return _str;
		}
	}
	
	if(!ds_map_exists(global.gmcu_loc_map, _str)) {
		gmcu_log_warn("Key '" + _str + "' was not found in localization file for language " + global.gmcu_language);
		return _str;
	}
	
	return global.gmcu_loc_map[? _str];
}
