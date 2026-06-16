if (gmcu_singleton()) {
	return;
}

// List to hold subscribers in sorted order
subscribers = ds_list_create();

/**
 * @description Adds an instance to the priority-ordered Draw GUI list.
 * @param {Id.Instance} _instance Instance that owns the on_draw_gui callback.
 * @param {Real} _priority Draw priority; larger values draw earlier.
 * @param {String|Undefined} _diagnostic_name Optional human-readable instance label.
 */
function subscribe(_instance, _priority, _diagnostic_name = undefined) {
    // Structure to store instance and its priority
    var _entry = {
		instance: _instance,
		priority: _priority,
		diagnostic_name: _diagnostic_name
	};
    
    // Find the correct position in the list to insert based on priority
    var _inserted = false;
    for (var _i = 0; _i < ds_list_size(subscribers); _i++) {
        var _current_entry = subscribers[| _i];
        
        // If current priority is lower, insert here
        if (_current_entry.priority < _priority) {
            ds_list_insert(subscribers, _i, _entry);
            _inserted = true;
            break;
        }
    }
    
    // If no insertion happened, add to the end (lowest priority)
    if (!_inserted) {
        ds_list_add(subscribers, _entry);
    }
}

/**
 * @description Removes an instance from the Draw GUI list.
 * @param {Id.Instance} _instance Subscribed instance to remove.
 */
function unsubscribe(_instance) {
    for (var _i = 0; _i < ds_list_size(subscribers); _i++) {
        if (subscribers[| _i].instance == _instance) {
            ds_list_delete(subscribers, _i);
            break;
        }
    }
}
