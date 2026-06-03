# EventBus

Import `EventBus` after `Core` and `Logging`.

Resources:

- `scripts/event_bus/event_bus.yy`

API:

- `eventbus_subscribe(_event_name)`
- `eventbus_unsubscribe(_event_name)`
- `eventbus_dispatch(_event_name, _event_args = undefined)`

Observers subscribe from the instance that should receive events. They should
unsubscribe before cleanup and define:

```gml
on_event = function(_event_name, _event_args) {
	// handle event
}
```

Event names should be constants or macros owned by the consumer project or by a
higher-level Common Utils module.

