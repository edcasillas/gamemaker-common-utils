for (var _i = ds_list_size(wait_steps_list) - 1; _i >= 0; _i--) {
	var _entry = wait_steps_list[| _i];
	_entry.steps -= 1;

	if (_entry.steps <= 0) {
		log_debug("Executing scheduled action");
		try {
			_entry.action();
		} catch (_exception) {
			log_exception(_exception);
		}

		ds_list_delete(wait_steps_list, _i);
	}
}

for (var _i = ds_list_size(wait_seconds_list) - 1; _i >= 0; _i--) {
	var _entry = wait_seconds_list[| _i];
	_entry.seconds -= DELTA_TIME_SECONDS;

	if (_entry.seconds <= 0) {
		try {
			_entry.action();
		} catch (_exception) {
			log_exception(_exception);
		}

		ds_list_delete(wait_seconds_list, _i);
	}
}
