/**
 * Schedule an action after a number of elapsed seconds.
 *
 * @param {real} _seconds
 * @param {function} _action
 */
function gmcu_wait_for_seconds(_seconds, _action) {
	if (!instance_exists(gmcu_o_timed_actions_manager)) {
		instance_create_depth(0, 0, 0, gmcu_o_timed_actions_manager);
	}

	gmcu_o_timed_actions_manager.gmcu_add_wait_seconds(_seconds, _action);
}
