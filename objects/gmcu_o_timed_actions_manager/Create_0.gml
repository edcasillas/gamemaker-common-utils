if (instance_number(object_index) > 1) {
	log_warn("[GMCU TimedActions] Manager already exists. Deleting duplicate.");
	instance_destroy();
	return;
}

persistent = true;
wait_steps_list = ds_list_create();
wait_seconds_list = ds_list_create();

function gmcu_add_wait_steps(_steps, _action) {
	ds_list_add(wait_steps_list, {
		steps: _steps,
		action: _action
	});
}

function gmcu_add_wait_seconds(_seconds, _action) {
	ds_list_add(wait_seconds_list, {
		seconds: _seconds,
		action: _action
	});
}
