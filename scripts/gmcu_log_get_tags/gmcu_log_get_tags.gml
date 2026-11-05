/**
 * @description Returns the current room, object, and runtime instance context for logging.
 * @returns {String} Context formatted as [room:object#instance], omitting the instance when no active instance exists.
 */
function gmcu_log_get_tags() {
	var _instance_tag = "";

	try {
		if (instance_exists(id)) {
			_instance_tag = "#" + string(id);
		}
	} catch (_exception) {
		_instance_tag = "";
	}

	return "[" + GMCU_ROOM_NAME + ":" + GMCU_OBJECT_NAME + _instance_tag + "]";
}
