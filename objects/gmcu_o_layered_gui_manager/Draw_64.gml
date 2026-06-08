// List to keep track of invalid indices
var _invalid_indices = ds_list_create();

var _draw_params = new gmcu_DrawingParameters();

// Loop through subscribers 
for (var _i = 0; _i < ds_list_size(subscribers); _i ++) {
    var _entry = subscribers[| _i];
    var _instance = _entry.instance;
    
    // Check if instance is invalid or has been destroyed
    if (_instance == noone || !instance_exists(_instance)) {
        gmcu_log_error("Invalid instance subscribed to gmcu_o_layered_gui_manager. Make sure to unsubscribe objects in the Clean Up event.");
        ds_list_add(_invalid_indices, _i); // Mark index for removal
        continue;
    }
	
	// Do not draw if the instance or the layer it is in are marked as not visible.
	if(!_instance.visible || (_instance.layer != -1 && !layer_get_visible(_instance.layer))) { continue; }
    
    // Check if the on_draw_gui function exists on the instance
    if (is_undefined(_instance.on_draw_gui)) {
        gmcu_log_error("Subscriber of gmcu_o_layered_gui_manager does not have a function on_draw_gui.");
        ds_list_add(_invalid_indices, _i); // Mark index for removal
        continue;
    }
    
    // Attempt to call the on_draw_gui function with error handling
    try {
        _instance.on_draw_gui();
    } catch (_exception) {
        gmcu_log_exception(_exception, "on_draw_gui for instance: " + string(_instance));
        ds_list_add(_invalid_indices, _i); // Mark index for removal
    }
	
	_draw_params.apply(); // Revert drawing parameters after each subscriber.
}

// Remove all invalid indices from the subscribers list after the loop
for (var _j = 0; _j < ds_list_size(_invalid_indices); _j++) {
    var _index_to_remove = _invalid_indices[| _j];
    ds_list_delete(subscribers, _index_to_remove);
}

// Clean up the temporary list
ds_list_destroy(_invalid_indices);
