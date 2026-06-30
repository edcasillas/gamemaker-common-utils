/**
 * Adds a reusable effect struct to a label instance.
 * @param {Instance} _label Label instance that owns the effect.
 * @param {Struct} _effect Effect struct created by this module.
 * @returns {Struct}
 */
function gmcu_label_add_effect(_label, _effect) {
	if(is_undefined(_label.label_effects)) {
		_label.label_effects = [];
	}

	array_push(_label.label_effects, _effect);
	return _effect;
}

/**
 * Starts an attached label effect.
 * @param {Struct} _effect Effect struct created by this module.
 */
function gmcu_label_start_effect(_effect) {
	if(is_undefined(_effect) || _effect.completed) return;

	if(_effect.started_at < 0) {
		_effect.started_at = current_time;
	}

	_effect.running = true;
}

/**
 * Stops an attached label effect without marking it complete.
 * @param {Struct} _effect Effect struct created by this module.
 */
function gmcu_label_stop_effect(_effect) {
	if(is_undefined(_effect)) return;
	_effect.running = false;
}

/**
 * Resets one label's runtime draw state before effects reapply their offsets.
 * @param {Instance} _label Label instance being updated.
 */
function gmcu_label_effects_reset_runtime(_label) {
	_label.draw_alpha = 1;
	_label.draw_offset_x = 0;
	_label.draw_offset_y = 0;
}

/**
 * Updates every active effect attached to a label and dispatches completion events when needed.
 * @param {Instance} _label Label instance being updated.
 */
function gmcu_label_effects_update(_label) {
	gmcu_label_effects_reset_runtime(_label);

	if(is_undefined(_label.label_effects)) return;

	var _remaining_effects = [];

	for(var _i = 0; _i < array_length(_label.label_effects); _i++) {
		var _effect = _label.label_effects[_i];
		if(!is_undefined(_effect.apply_to_label)) {
			_effect.apply_to_label(_label);
		}

		if(_effect.completed && !_effect.notified_complete) {
			_effect.notified_complete = true;
			gmcu_eventbus_dispatch(GMCU_EVENT_LABEL_EFFECT_FINISHED, {
				label_id: _label.id,
				effect_kind: _effect.kind
			});
		}

		if(!_effect.completed) {
			array_push(_remaining_effects, _effect);
		}
	}

	_label.label_effects = _remaining_effects;
}

/**
 * Creates a fade effect that interpolates the label alpha over time.
 * @param {Real} _duration_seconds Total fade duration in seconds.
 * @param {Real} _from_alpha Starting alpha.
 * @param {Real} _to_alpha Ending alpha.
 * @returns {Struct}
 */
function gmcu_LabelEffectFade(_duration_seconds, _from_alpha = 1, _to_alpha = 0) constructor {
	kind = "fade";
	duration_ms = max(1, _duration_seconds * 1000);
	from_alpha = _from_alpha;
	to_alpha = _to_alpha;
	running = false;
	completed = false;
	notified_complete = false;
	started_at = -1;

	/**
	 * Applies the current fade alpha to the label while the effect is running.
	 * @param {Instance} _label Label instance being updated.
	 */
	function apply_to_label(_label) {
		if(completed) return;

		if(!running || started_at < 0) {
			_label.draw_alpha *= from_alpha;
			return;
		}

		var _elapsed = current_time - started_at;
		var _progress = clamp(_elapsed / duration_ms, 0, 1);
		_label.draw_alpha *= lerp(from_alpha, to_alpha, _progress);

		if(_progress >= 1) {
			running = false;
			completed = true;
		}
	}
}

/**
 * Creates a tremble effect that offsets a label using sinusoidal motion.
 * @param {Real} _amplitude Maximum horizontal offset in pixels.
 * @param {Real} _speed Oscillation speed multiplier.
 * @param {Real} _duration_seconds Optional total duration in seconds.
 * @returns {Struct}
 */
function gmcu_LabelEffectTremble(_amplitude, _speed, _duration_seconds = undefined) constructor {
	kind = "tremble";
	amplitude = _amplitude;
	speed = _speed;
	duration_ms = is_undefined(_duration_seconds) ? -1 : max(1, _duration_seconds * 1000);
	running = false;
	completed = false;
	notified_complete = false;
	started_at = -1;

	/**
	 * Applies the current tremble offsets to the label while the effect is running.
	 * @param {Instance} _label Label instance being updated.
	 */
	function apply_to_label(_label) {
		if(completed || !running || started_at < 0) return;

		var _elapsed = current_time - started_at;
		var _phase = (_elapsed / 1000) * speed * pi * 2;

		_label.draw_offset_x += sin(_phase) * amplitude;
		_label.draw_offset_y += cos(_phase * 0.75) * amplitude * 0.5;

		if(duration_ms >= 0 && _elapsed >= duration_ms) {
			running = false;
			completed = true;
		}
	}
}
