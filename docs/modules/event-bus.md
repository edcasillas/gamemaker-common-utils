# EventBus

`EventBus` lets instances publish and observe named events without direct
references to one another.

## Quickstart

Subscribe from the receiving instance, implement `on_event`, and unsubscribe
in Clean Up:

```gml
// Receiver Create
gmcu_eventbus_subscribe(EVENT_PAUSE_CHANGED);

on_event = function(_event_name, _event_args) {
    if (_event_name == EVENT_PAUSE_CHANGED) {
        paused = _event_args;
    }
};

// Receiver Clean Up
gmcu_eventbus_unsubscribe(EVENT_PAUSE_CHANGED);
```

Dispatch with:

```gml
// Sender
gmcu_eventbus_dispatch(EVENT_PAUSE_CHANGED, true);
```

## Resources

- `scripts/gmcu_event_bus`: Owns the observer map and the subscribe,
  unsubscribe, and dispatch functions.

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Core`](core.md) | Supplies safe object-name diagnostics. |
| [`Logging`](logging.md) | Reports subscriptions, dispatches, stale observers, missing callbacks, and callback exceptions. |

## API

| Item | Kind | Description |
| --- | --- | --- |
| `gmcu_eventbus_subscribe(_event_name)` | Function | Subscribes `self` to a named event. |
| `gmcu_eventbus_unsubscribe(_event_name)` | Function | Removes `self` from a named event. |
| `gmcu_eventbus_dispatch(_event_name, _event_args = undefined)` | Function | Calls `on_event` on each live observer. |
| `global.gmcu_eventbus_observers_map` | Global | Internal observer registry. |

Event names are owned by the module or consumer that defines their meaning.

## Contributing

Keep `scripts/gmcu_event_bus/gmcu_event_bus.yy` as the local consumer path and
symlink its folder to Common Utils.
