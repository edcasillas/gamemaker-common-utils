# Transitions

`Transitions` provides reusable fade and horizontal-curtain room changes.

## Quickstart

Call `gmcu_transition_to_room` with a target room, transition type, duration,
and optional callbacks.

```gml
gmcu_transition_to_room(
	nivel02,
	GMCU_TRANSITION_TO_ROOM_TYPE.H_CURTAIN,
	0.6,
	{
		// Runs every Step while the transition progresses from 0 to 1.
		on_progress: function(_progress) {},

		// Runs immediately before the transition changes rooms.
		on_transition_ended: function() {
			audio_stop_all();
		}
	}
);
```

## Resources

- `scripts/gmcu_transition_events`
- `scripts/gmcu_transition_types`
- `scripts/gmcu_transition_to_room`
- `objects/gmcu_o_transition_to_room`
- `objects/gmcu_o_transition_fadeout_to_room`
- `objects/gmcu_o_transition_hcurtain_close_to_room`
- `objects/gmcu_o_transition_hcurtain_open`

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Core`](core.md) | Supplies timing and shared GUI priority constants. |
| [`Drawing`](drawing.md) | Protects transition draw state. |
| [`LayeredGUI`](layered-gui.md) (optional) | Owns transition overlay ordering when present, using `GMCU_GUI_PRIORITY_TRANSITION_OVERLAY`. |
| [`Logging`](logging.md) | Reports invalid transition configuration. |
| [`EventBus`](event-bus.md) | Dispatches opening-curtain completion. |

## API

| Item | Kind | Description |
| --- | --- | --- |
| `GMCU_TRANSITION_TO_ROOM_TYPE.FADEOUT` | Constant | Full-screen fadeout transition. |
| `GMCU_TRANSITION_TO_ROOM_TYPE.H_CURTAIN` | Constant | Horizontal curtain-close transition. |
| `GMCU_EVENT_TRANSITION_FINISHED` | Event | Dispatched when an opening curtain finishes. |
| `gmcu_transition_to_room(_target_room, _transition_type, _seconds, _options)` | Function | Starts a transition and changes rooms when it finishes. |

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

## GUI Ordering

When [`LayeredGUI`](layered-gui.md) is available, transition overlays subscribe
at `GMCU_GUI_PRIORITY_TRANSITION_OVERLAY`. That keeps them above normal GUI and
the universal cursor, but below the Dev Menu. If LayeredGUI is not present,
they fall back to their own `Draw GUI` events.

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
