if (curtain_size > 0) {
	curtain_size -= open_velocity;
} else {
	eventbus_dispatch(GMCU_EVENT_TRANSITION_FINISHED, transition_id);
	instance_destroy();
}
