/**
 * Destroys an instance id only when the instance still exists.
 * @param {Instance|Real} _instance Instance id to destroy.
 * @returns {Bool}
 */
function gmcu_instance_destroy(_instance) {
	if(!instance_exists(_instance)) return false;

	with(_instance) {
		instance_destroy();
	}

	return true;
}
