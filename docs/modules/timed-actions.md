# Timed Actions

`TimedActions` schedules callbacks after a number of Step events or elapsed
seconds.

## Usage

Call `gmcu_wait_for_seconds` or `gmcu_wait_for_steps`; the manager is created
automatically on the first scheduled action.

## Resources

- `objects/gmcu_o_timed_actions_manager`
- `scripts/gmcu_wait_for_seconds`
- `scripts/gmcu_wait_for_steps`

## Dependencies

- [`Core`](core.md): Supplies delta-time and singleton support.
- [`Logging`](logging.md): Reports execution and callback failures.
  - [`Core`](core.md)

## API

- `gmcu_wait_for_seconds(_seconds, _action)`
- `gmcu_wait_for_steps(_steps, _action)`

The first scheduled action creates `gmcu_o_timed_actions_manager`. The manager
is persistent, rejects duplicate instances, catches callback exceptions, and
removes completed actions. Step-scheduled callbacks emit
`Executing scheduled action` through Logging immediately before execution.

## Contributing

Callbacks run from the manager's Step event. A callback scheduled for zero or a
negative delay runs on the next manager Step.

Keep the listed resource paths local and symlink their folders to Common Utils.
