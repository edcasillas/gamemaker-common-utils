if(!visible) return; // Skip processing inputs if cursor is not visible.

// Get the current mouse position in GUI space
var _current_mouse_x = device_mouse_x_to_gui(0);
var _current_mouse_y = device_mouse_y_to_gui(0);

// Update cursor position if mouse moves
if(_current_mouse_x != last_mouse_x || _current_mouse_y != last_mouse_y) {
	gui_x = _current_mouse_x;
	last_mouse_x = _current_mouse_x;
	gui_y = _current_mouse_y;
	last_mouse_y = _current_mouse_y;
}

// Handle directional navigation (arrow keys or D-Pad)
if (keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(0, gp_padu)) {
    navigate(GMCU_DIRECTION_ANGLE.UP);
} else if (keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(0, gp_padd)) {
    navigate(GMCU_DIRECTION_ANGLE.DOWN);
} else if (keyboard_check_pressed(vk_left) || gamepad_button_check_pressed(0, gp_padl)) {
    navigate(GMCU_DIRECTION_ANGLE.LEFT);
} else if (keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_padr)) {
    navigate(GMCU_DIRECTION_ANGLE.RIGHT);
}

// Handle analog stick movement for gamepad
if(instance_exists(gmcu_o_input_hub) && array_length(gmcu_o_input_hub.gamepads) > 0) {
	var _axis_x = gamepad_axis_value(0, gp_axislh);
	var _axis_y = gamepad_axis_value(0, gp_axislv);

	if (abs(_axis_x) > 0.2 || abs(_axis_y) > 0.2) {  // Deadzone check
	    gui_x += _axis_x * analog_speed;
		gui_x = clamp(gui_x, 0, display_get_gui_width() - sprite_width);
		
	    gui_y -= _axis_y * analog_speed;
		gui_y = clamp(gui_y, 0, display_get_gui_height() - sprite_height);
	}
}


// Detect hovering over interactables
var _invalid_indices = ds_list_create(); // List to keep track of invalid indices

var _is_hovering = false;
for (var _i = 0; _i < ds_list_size(interactables); _i++) {
    var _interactable = interactables[| _i];
	
    if (_interactable == noone || !instance_exists(_interactable)) {
        log_error("Invalid instance subscribed to gmcu_o_universal_cursor. Make sure to unsubscribe objects in the Clean Up event.");
        ds_list_add(_invalid_indices, _i); // Mark index for removal
        continue;
    }
	
	// Define interactable boundaries based on its GUI position and dimensions
	var _interactable_x = _interactable.x - (_interactable.sprite_width / 2);
	var _interactable_y = _interactable.y - (_interactable.sprite_height / 2);
	var _interactable_width = _interactable.sprite_width;
	var _interactable_height = _interactable.sprite_height;
	
    if (point_in_rectangle(gui_x, gui_y, _interactable_x, _interactable_y, _interactable_x + _interactable_width, _interactable_y + _interactable_height)) {
		if(hovered_interactable != _interactable) { // New interactable hover detected
			if(hovered_interactable != noone) {
				try {
					hovered_interactable.on_hover_leave(); // Trigger exit event on previously hovered interactable
				} catch(_exception) {
					log_exception(_exception, "on_hover_leave");
					ds_list_add(_invalid_indices, _i); // Mark index for removal
					continue;
				}
			}
			
			hovered_interactable = _interactable;
			
			try {
				hovered_interactable.on_hover_enter(); // Trigger enter event on new interactable
			} catch(_exception) {
				log_exception(_exception, "on_hover_enter");
				ds_list_add(_invalid_indices, _i); // Mark index for removal
				continue;
			}
		}
        _is_hovering = true;
        break;
    }
}

var _invalid_indices_count = ds_list_size(_invalid_indices);
if(_invalid_indices_count) {
	// Remove all invalid indices from the subscribers list after the loop
	for (var _j = 0; _j < _invalid_indices_count; _j++) {
	    var _index_to_remove = _invalid_indices[| _j];
	    ds_list_delete(interactables, _index_to_remove);
	}
	var _interactables_count = ds_list_size(interactables);
	log_warn(string(_invalid_indices_count) + " invalid indices were detected to be subscribed in gmcu_o_universal_cursor and have been unsubscribed. " + string(_interactables_count) + " remain subscribed.");
}

// Clean up the temporary list
ds_list_destroy(_invalid_indices);

// Handle hover exit if not hovering over any interactable
if(!_is_hovering) {
	if(hovered_interactable != noone) {
		hovered_interactable.on_hover_leave(); // Trigger hover exit on previously hovered interactable
	}
	hovered_interactable = noone;
}

// Check for interaction events if hovering over an interactable
if(_is_hovering && hovered_interactable != noone) {
	// Trigger on_pressed for different input methods
	var _has_gamepad = instance_exists(gmcu_o_input_hub) && gmcu_o_input_hub.gmcu_has_connected_gamepad();
	if (mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_enter) || (_has_gamepad && gamepad_button_check_pressed(0, gp_face1))) {
		hovered_interactable.on_pressed();
	}
	
	// Trigger on_released for different input methods
	if (mouse_check_button_released(mb_left) || keyboard_check_released(vk_enter) || (_has_gamepad && gamepad_button_check_released(0, gp_face1))) {
		hovered_interactable.on_released();
	}
}
