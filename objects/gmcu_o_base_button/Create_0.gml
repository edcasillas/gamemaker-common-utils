created = false;
if(button_id == "") {
	log_error("Button ID has not been defined; instance will be removed.");
	instance_destroy();
	return;
}

if(sprite_index == noone) {
	log_error("Button '" + button_id + "' does not have a sprite assigned; instance will be removed.");
	instance_destroy();
	return;
}

log_debug("Creating Button ID: " + button_id);

image_speed = 0;
image_index = 0;

if(text != "" && localize_text) {
	text = gmcu_localization_t(text);
	log_debug("Text has been localized to '" + text + "'");
}

/*
The button should only do its action after mouse released when it previously received a
mouse pressed event. This flag tells us whether the button has received the pressed event.
*/
is_pressed = false;

created = true;

/**
This function will be called by inheritors of o_base_button in either draw or draw GUI events.
*/
function do_draw() {
	draw_self();

	if(text == "") return;

	var _draw_params = new DrawingParameters(); 

	if(font != noone) draw_set_font(font);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(text_color);
	draw_text(x, y, text);

	_draw_params.apply();
}

function on_pressed() {
	if(debug_events) {
		var _message = button_id + " pressed; interactable: " + string(is_interactable);
		log_debug(_message);
		common_utils_try_show_notification(_message);
	}
	if(!is_interactable) return;
	image_index = 2;
	is_pressed = true;
}

function on_released() {
	if(debug_events) {
		var _message = button_id + " released; interactable: " + string(is_interactable);
		log_debug(_message);
		common_utils_try_show_notification(_message);
	}
	if(!is_interactable) return;
	image_index = 1;

	if(!is_pressed) return;
	is_pressed = false;
	if(click_sound != noone && audio_exists(click_sound)) {
		audio_play_sound(click_sound, click_sound_priority, false);
	}

	if(action_delay == 0) action_delay = 1;
	alarm[0] = action_delay;
}

function on_hover_enter() {
	if(debug_events) {
		var _message = button_id + " hover enter; interactable: " + string(is_interactable);
		log_debug(_message);
		common_utils_try_show_notification(_message);
	}
	if(!is_interactable) return;
	image_index = 1;
}

function on_hover_leave() {
	if(debug_events) {
		var _message = button_id + " hover leave; interactable: " + string(is_interactable);
		log_debug(_message);
		common_utils_try_show_notification(_message);
	}
	if(!is_interactable) return;
	is_pressed = false;
	image_index = 0;
}
