# Transitions

`Transitions` provides reusable fade and horizontal-curtain room changes.

## Usage

Call `gmcu_transition_to_room` with a target room, transition type, duration,
and optional callbacks.

## Resources

- `scripts/gmcu_transition_events`
- `scripts/gmcu_transition_types`
- `scripts/gmcu_transition_to_room`
- `objects/gmcu_o_transition_to_room`
- `objects/gmcu_o_transition_fadeout_to_room`
- `objects/gmcu_o_transition_hcurtain_close_to_room`
- `objects/gmcu_o_transition_hcurtain_open`

## Dependencies

- [`Core`](core.md): Supplies timing and layer-depth constants.
- [`Drawing`](drawing.md): Protects transition draw state.
  - [`Core`](core.md)
- [`Logging`](logging.md): Reports invalid transition configuration.
  - [`Core`](core.md)
- [`EventBus`](event-bus.md): Dispatches opening-curtain completion.
  - [`Core`](core.md)
  - [`Logging`](logging.md)

## API

- `GMCU_TRANSITION_TO_ROOM_TYPE.FADEOUT`
- `GMCU_TRANSITION_TO_ROOM_TYPE.H_CURTAIN`
- `GMCU_EVENT_TRANSITION_FINISHED`
- `gmcu_transition_to_room(_target_room, _transition_type, _seconds, _options)`

The optional `_options` struct supports:

```gml
{
	on_progress: function(_progress) {},
	on_transition_ended: function() {}
}
```

`on_progress` receives values from `0` to `1`.
`on_transition_ended` runs immediately before the transition instance is
destroyed and `room_goto()` is called.

## Opening Curtain

Place `gmcu_o_transition_hcurtain_open` in a room that should begin covered by
a horizontal curtain. Configure `open_velocity` and `transition_id` as instance
properties. When complete, it dispatches `GMCU_EVENT_TRANSITION_FINISHED` with
`transition_id`.

## Consumer-Owned Behavior

Audio fades, `audio_stop_all()`, music restoration, analytics, and other
project-specific side effects do not belong to this module. Supply them through
the optional callbacks.

## Contributing

Keep the listed resource paths local and symlink their folders to Common Utils.
