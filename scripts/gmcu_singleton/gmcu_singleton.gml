/**
 * @description Ensures the current object stays a persistent singleton.
 * @returns {Bool} True when the current instance was destroyed as a duplicate; otherwise false.
 */
function gmcu_singleton() {
	if (instance_number(object_index) > 1) {
		gmcu_log_warn("[Singleton] Instance of " + GMCU_OBJECT_NAME + " already exists. Deleting duplicates.");
		instance_destroy();
		return true;
	}

	persistent = true;
	return false;
}
