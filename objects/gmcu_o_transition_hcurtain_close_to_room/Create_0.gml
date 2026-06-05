event_inherited();

curtain_size = 0;
max_curtain_size = window_get_width() / 2;

var _consumer_on_progress = on_progress;
on_progress = function(_current_transition_progress) {
	curtain_size = max_curtain_size * _current_transition_progress;
	_consumer_on_progress(_current_transition_progress);
};
