/**
 * Start a transition and move to another room when it finishes.
 *
 * Optional callbacks:
 * - on_progress(_progress): called each Step with progress from 0 to 1.
 * - on_transition_ended(): called before the transition instance is destroyed
 *   and before room_goto().
 *
 * @param {asset.GMRoom} _target_room
 * @param {GMCU_TRANSITION_TO_ROOM_TYPE} _transition_type
 * @param {real} _transition_seconds
 * @param {struct} _options
 */
function gmcu_transition_to_room(
	_target_room,
	_transition_type,
	_transition_seconds,
	_options = undefined
) {
	if (!is_struct(_options)) {
		_options = {};
	}

	var _transition_args = {
		target_room: _target_room,
		transition_seconds: _transition_seconds,
		transition_options: _options
	};

	gmcu_log_debug("[GMCU Transitions] Transitioning to room " + room_get_name(_target_room));

	switch (_transition_type) {
		case GMCU_TRANSITION_TO_ROOM_TYPE.FADEOUT:
			instance_create_depth(
				0,
				0,
				GMCU_LAYER_DEPTH_MIN,
				gmcu_o_transition_fadeout_to_room,
				_transition_args
			);
			break;

		case GMCU_TRANSITION_TO_ROOM_TYPE.H_CURTAIN:
			instance_create_depth(
				0,
				0,
				GMCU_LAYER_DEPTH_MIN,
				gmcu_o_transition_hcurtain_close_to_room,
				_transition_args
			);
			break;

		default:
			gmcu_log_error(
				"[GMCU Transitions] Unsupported transition type "
				+ string(_transition_type)
			);
			room_goto(_target_room);
			break;
	}
}
