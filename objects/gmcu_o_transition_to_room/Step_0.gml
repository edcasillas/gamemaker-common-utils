if (transition_progress < 1) {
	transition_progress += GMCU_DELTA_TIME_SECONDS / transition_seconds;
	transition_progress = min(transition_progress, 1);
	on_progress(transition_progress);
} else if (!transition_has_finished) {
	transition_has_finished = true;
	gmcu_end_transition();
}
