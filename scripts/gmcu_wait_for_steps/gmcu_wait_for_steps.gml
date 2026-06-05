/**
 * Schedule an action after a number of Step events.
 *
 * @param {real} _steps
 * @param {function} _action
 */
function gmcu_wait_for_steps(_steps, _action) {
	if (!instance_exists(gmcu_o_timed_actions_manager)) {
		instance_create_depth(0, 0, 0, gmcu_o_timed_actions_manager);
	}

	gmcu_o_timed_actions_manager.gmcu_add_wait_steps(_steps, _action);
}
