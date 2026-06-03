global.gmcu_eventbus_observers_map = ds_map_create();

function eventbus_ensure_initialized() {
	if (is_undefined(global.gmcu_eventbus_observers_map)) {
		global.gmcu_eventbus_observers_map = ds_map_create();
	}
}

/// Subscribe the current instance to an event.
function eventbus_subscribe(_event_name) {
	eventbus_ensure_initialized();

	if (!ds_map_exists(global.gmcu_eventbus_observers_map, _event_name)) {
		var _event_observers = ds_map_create();
		ds_map_add(global.gmcu_eventbus_observers_map, _event_name, _event_observers);
	}

	log_debug("Subscribed instance of " + OBJECT_NAME + " to event " + string(_event_name));
	global.gmcu_eventbus_observers_map[? _event_name][? self] = true;
}

/// Unsubscribe the current instance from an event.
function eventbus_unsubscribe(_event_name) {
	eventbus_ensure_initialized();

	if (!ds_map_exists(global.gmcu_eventbus_observers_map, _event_name)) return;
	if (!ds_map_exists(global.gmcu_eventbus_observers_map[? _event_name], self)) return;

	ds_map_delete(global.gmcu_eventbus_observers_map[? _event_name], self);
	log_debug("Unsubscribed instance of " + OBJECT_NAME + " from event " + string(_event_name));

	if (ds_map_size(global.gmcu_eventbus_observers_map[? _event_name]) == 0) {
		ds_map_destroy(global.gmcu_eventbus_observers_map[? _event_name]);
		ds_map_delete(global.gmcu_eventbus_observers_map, _event_name);
	}
}

/// Dispatch an event to all observers.
function eventbus_dispatch(_event_name, _event_args = undefined) {
	eventbus_ensure_initialized();

	var _event_log_str = "'" + string(_event_name) + "'(" + string(_event_args) + ")";
	log_debug("Dispatching " + _event_log_str);

	if (!ds_map_exists(global.gmcu_eventbus_observers_map, _event_name)) return;

	var _observers = ds_map_keys_to_array(global.gmcu_eventbus_observers_map[? _event_name]);

	for (var _i = 0; _i < array_length(_observers); _i++) {
		var _instance = _observers[_i];

		if (!instance_exists(_instance)) {
			log_warn("Observer instance for event '" + string(_event_name) + "' no longer exists. Observers should unsubscribe before deletion.");
			ds_map_delete(global.gmcu_eventbus_observers_map[? _event_name], _instance);
			continue;
		}

		if (is_undefined(_instance.on_event)) {
			log_error("Observer " + object_get_name(_instance.object_index) + " lacks the 'on_event' function.");
			continue;
		}

		try {
			with (_instance) {
				on_event(_event_name, _event_args);
			}
		} catch (_exception) {
			log_exception(_exception, _event_log_str + ":" + object_get_name(_instance.object_index));
		}
	}
}
