# GlobalStats.io

`GlobalStats.io` provides a defensive facade over a consumer-installed
GlobalStats.io client.

## Resource

- `scripts/gmcu_globalstats`

## Dependencies

Import after:

1. `Logging`
2. A consumer-owned GlobalStats.io controller and its `gs_*` client scripts

## API

- `gmcu_globalstats_is_available()`
- `gmcu_globalstats_request_leaderboard(_gtd, _num_entries = 10)`
- `gmcu_globalstats_share(_player_id, _player_name, _values)`
- `gmcu_globalstats_request_rank_section(_gtd, _player_id = undefined)`

Leaderboard entry counts are clamped to the supported range of 1 through 100.
The rank-section helper uses the controller's current player ID when one is not
provided explicitly.

## Consumer-Owned Requirements

The GlobalStats.io controller, HTTP client scripts, credentials, GTD
identifiers, player identity policy, persistence, response events, and payload
schema remain in the consumer. Never place credentials or project-specific GTD
keys in Common Utils.

The facade catches client exceptions and returns `false` when the controller or
required player identity is unavailable.
