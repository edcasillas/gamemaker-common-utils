if(instance_number(object_index) > 1) {
	gmcu_log_warn("[GMCU LayeredGUI] Instance already exists. Deleting duplicate.");
	instance_destroy();
	return;
}
persistent = true;

// List to hold subscribers in sorted order
subscribers = ds_list_create();

function subscribe(_instance, _priority) {
    // Structure to store instance and its priority
    var _entry = { instance: _instance, priority: _priority };
    
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

function unsubscribe(_instance) {
    for (var _i = 0; _i < ds_list_size(subscribers); _i++) {
        if (subscribers[| _i].instance == _instance) {
            ds_list_delete(subscribers, _i);
            break;
        }
    }
}
