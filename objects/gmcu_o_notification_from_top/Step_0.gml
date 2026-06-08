switch (current_state) {
	case 0:
		box_y += enter_speed * GMCU_DELTA_TIME_SECONDS;
		if (next != noone && instance_exists(next)) {
			next.set_offset_y_recursive(get_bottom_pos());
		}
		if (box_y >= 0) {
			box_y = 0;
			current_state = 1;
			time_showing = 0;
		}
		break;

	case 1:
		time_showing += GMCU_DELTA_TIME_SECONDS;
		if (time_showing > view_time) {
			current_state = 2;
		}
		break;

	case 2:
		var _is_out_of_view = false;
		box_y -= exit_speed * GMCU_DELTA_TIME_SECONDS;
		if (box_y <= -box_h) {
			box_y = -box_h;
			_is_out_of_view = true;
		}
		if (next != noone && instance_exists(next)) {
			next.set_offset_y_recursive(get_bottom_pos());
		}
		if (_is_out_of_view) {
			if (next != noone && instance_exists(next) && previous != noone && instance_exists(previous)) {
				previous.next = next;
			}
			instance_destroy();
		}
		break;
}

