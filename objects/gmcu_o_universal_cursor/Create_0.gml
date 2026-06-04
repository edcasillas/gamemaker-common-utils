if(instance_number(object_index) > 1) {
	log_warn("[GMCU UniversalCursor] Instance already exists. Deleting duplicate.");
	instance_destroy();
	return;
}
persistent = true;

// Initialize last known mouse positions
last_mouse_x = device_mouse_x(0);
last_mouse_y = device_mouse_y(0);

// Position in the GUI space (centered initially)
gui_x = display_get_gui_width() / 2;
gui_y = display_get_gui_height() / 2;

// To store interactable objects and track the currently hovered interactable
hovered_interactable = noone;
interactables = ds_list_create();

/**
Subscribe a new interactable object to be detected by the cursor.
@param {Id.Instance} _instance
*/
function subscribe(_instance) { 
	ds_list_add(interactables, _instance);
}

/**
Unsubscribe an interactable object from cursor detection
@param {Id.Instance} _instance
*/
function unsubscribe(_instance) {
	var _pos = ds_list_find_index(interactables, _instance);
	if(_pos >= 0) {
		ds_list_delete(interactables, _pos);
	}
}

/**
Navigate between interactables in a specified direction (up, down, left, right).
@param {real} _direction GMCU_DIRECTION_ANGLE.UP | GMCU_DIRECTION_ANGLE.DOWN | GMCU_DIRECTION_ANGLE.LEFT | GMCU_DIRECTION_ANGLE.RIGHT
*/
function navigate(_direction) {
	log_debug("Navigating " + string(_direction));
    var _best_interactable = noone; // Stores the closest interactable in the specified direction
    var _min_dist = INT_MAX; // Initialize minimum distance to a very high value
    
	// Loop through all interactables to find the best one based on direction
    for (var _i = 0; _i < ds_list_size(interactables); _i++) {
        var _interactable = interactables[| _i];
        
        if (_interactable != hovered_interactable) { // Ignore currently hovered interactable
            var _dx = _interactable.x - gui_x;
            var _dy = _interactable.y - gui_y;
            
			// Select the interactable closest in the specified direction
            switch (_direction) {
                case GMCU_DIRECTION_ANGLE.UP: if (_dy < 0 && abs(_dy) > abs(_dx) && abs(_dy) < _min_dist) { _min_dist = abs(_dy); _best_interactable = _interactable; } break;
                case GMCU_DIRECTION_ANGLE.DOWN: if (_dy > 0 && abs(_dy) > abs(_dx) && abs(_dy) < _min_dist) { _min_dist = abs(_dy); _best_interactable = _interactable; } break;
                case GMCU_DIRECTION_ANGLE.LEFT: if (_dx < 0 && abs(_dx) > abs(_dy) && abs(_dx) < _min_dist) { _min_dist = abs(_dx); _best_interactable = _interactable; } break;
                case GMCU_DIRECTION_ANGLE.RIGHT: if (_dx > 0 && abs(_dx) > abs(_dy) && abs(_dx) < _min_dist) { _min_dist = abs(_dx); _best_interactable = _interactable; } break;
            }
        }
    }
	
	// If no interactable was found in the specified direction, default to the first interactable if none is selected
	if(_best_interactable == noone && hovered_interactable == noone && ds_list_size(interactables) > 0) {
		_best_interactable = interactables[| 0];
	}
    
	// Update cursor position to the selected interactable's position
    if (_best_interactable != noone) {
        gui_x = _best_interactable.x;
        gui_y = _best_interactable.y;
    }
}
	
gmcu_layered_gui_subscribe(-1000);
function on_draw_gui() {
	draw_sprite(sprite_index, 0, gui_x, gui_y);
}
