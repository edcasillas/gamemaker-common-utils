transition_progress = 0;
transition_has_finished = false;

on_progress = function(_current_transition_progress) {};
on_transition_ended = function() {};

if (variable_struct_exists(transition_options, "on_progress")) {
	on_progress = transition_options.on_progress;
}

if (variable_struct_exists(transition_options, "on_transition_ended")) {
	on_transition_ended = transition_options.on_transition_ended;
}

function gmcu_end_transition() {
	on_transition_ended();
	instance_destroy();
	room_goto(target_room);
}
