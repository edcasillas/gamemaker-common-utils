global.gmcu_gameanalytics_enabled = false;

/**
 * Initialize a consumer-provided GameAnalytics SDK.
 *
 * Required options: game_key, game_secret.
 * Optional options: build, info_log, verbose_log, enabled.
 */
function gmcu_gameanalytics_init(_options) {
	if (!is_struct(_options)) {
		gmcu_log_error("[GMCU GameAnalytics] Expected an options struct.");
		return false;
	}

	if (!variable_struct_exists(_options, "game_key")
		|| !variable_struct_exists(_options, "game_secret")) {
		gmcu_log_error("[GMCU GameAnalytics] Missing consumer-owned credentials.");
		return false;
	}

	var _enabled = true;
	if (variable_struct_exists(_options, "enabled")) {
		_enabled = _options.enabled;
	}

	global.gmcu_gameanalytics_enabled = _enabled;
	if (!_enabled) {
		gmcu_log_info("[GMCU GameAnalytics] Event submission is disabled.");
		return true;
	}

	var _info_log = false;
	var _verbose_log = false;
	if (variable_struct_exists(_options, "info_log")) {
		_info_log = _options.info_log;
	}
	if (variable_struct_exists(_options, "verbose_log")) {
		_verbose_log = _options.verbose_log;
	}

	try {
		ga_setEnabledInfoLog(_info_log);
		ga_setEnabledVerboseLog(_verbose_log);

		if (variable_struct_exists(_options, "build")) {
			ga_configureBuild(string(_options.build));
		}

		ga_initialize(_options.game_key, _options.game_secret);
		return true;
	} catch (_exception) {
		global.gmcu_gameanalytics_enabled = false;
		gmcu_log_exception(_exception, "gmcu_gameanalytics_init");
		return false;
	}
}

function gmcu_gameanalytics_add_design_event(_event_id, _value = undefined) {
	if (!global.gmcu_gameanalytics_enabled) return false;

	try {
		if (is_undefined(_value)) {
			ga_addDesignEvent(_event_id);
		} else {
			ga_addDesignEvent(_event_id, _value);
		}
		return true;
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_gameanalytics_add_design_event");
		return false;
	}
}

function gmcu_gameanalytics_add_progression_event(
	_status,
	_progression_1,
	_progression_2 = "",
	_progression_3 = "",
	_score = undefined
) {
	if (!global.gmcu_gameanalytics_enabled) return false;

	try {
		if (is_undefined(_score)) {
			ga_addProgressionEvent(
				_status,
				_progression_1,
				_progression_2,
				_progression_3
			);
		} else {
			ga_addProgressionEvent(
				_status,
				_progression_1,
				_progression_2,
				_progression_3,
				_score
			);
		}
		return true;
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_gameanalytics_add_progression_event");
		return false;
	}
}

function gmcu_gameanalytics_add_error_event(_severity, _message) {
	if (!global.gmcu_gameanalytics_enabled) return false;

	try {
		ga_addErrorEvent(_severity, _message);
		return true;
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_gameanalytics_add_error_event");
		return false;
	}
}

function gmcu_gameanalytics_end_session() {
	if (!global.gmcu_gameanalytics_enabled) return false;

	try {
		ga_endSession();
		return true;
	} catch (_exception) {
		gmcu_log_exception(_exception, "gmcu_gameanalytics_end_session");
		return false;
	}
}
