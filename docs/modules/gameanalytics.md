# GameAnalytics

`GameAnalytics` provides a defensive facade over a consumer-installed
GameAnalytics SDK.

## Resource

- `scripts/gmcu_gameanalytics`

## Dependencies

Import after:

1. `Logging`
2. A consumer-owned GameAnalytics extension and its `ga_*` SDK scripts

## API

- `gmcu_gameanalytics_init(_options)`
- `gmcu_gameanalytics_add_design_event(_event_id, _value)`
- `gmcu_gameanalytics_add_progression_event(...)`
- `gmcu_gameanalytics_add_error_event(_severity, _message)`
- `gmcu_gameanalytics_end_session()`

Initialization accepts an options struct with consumer-owned `game_key` and
`game_secret`. Optional fields are `build`, `info_log`, `verbose_log`, and
`enabled`.

## Consumer-Owned Requirements

The GameAnalytics extension, SDK scripts, credentials, build identifiers,
consent policy, and project event taxonomy remain in the consumer. Never place
credentials in Common Utils.

The facade disables itself if initialization throws. Event functions return
whether the SDK call was attempted successfully.
