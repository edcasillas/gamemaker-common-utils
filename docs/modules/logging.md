# Logging

`Logging` provides severity-aware output, a bounded development log buffer,
optional target output, and optional telemetry forwarding.

## Usage

Call `gmcu_log_debug`, `gmcu_log_info`, `gmcu_log_warn`, `gmcu_log_error`, or
`gmcu_log_exception`. Without adapters, messages use
`show_debug_message`.

```gml
gmcu_log_info("Game initialized");
gmcu_log_error("Save failed");
```

Register output or telemetry adapters only when the consumer needs them:

```gml
gmcu_log_set_output_handler(function(_severity, _message) {
    target_console_write(_severity, _message);
});
```

## Resources

- `scripts/gmcu_log_config`: Severity macros, adapters, recursion protection,
  and development buffer.
- `scripts/gmcu_log_get_tags`: Builds room/object context tags.
- `scripts/gmcu_log_debug`, `gmcu_log_info`, `gmcu_log_warn`,
  `gmcu_log_error`, and `gmcu_log_exception`: Public severity functions.

## Dependencies

- [`Core`](core.md): Supplies build configuration, context names, and the
  optional notification-handler registry.

## API

- `gmcu_log_debug(_message, _local_only = false)`: Writes debug output when
  `GMCU_ENABLE_DEBUG_LOG` is enabled.
- `gmcu_log_info(_message)`, `gmcu_log_warn(_message)`: Write informational or
  warning output.
- `gmcu_log_error(_message, _show_notification = true)`: Writes an error and
  optionally requests a visual notification.
- `gmcu_log_exception(_exception, _tag = "", _show_notification = true)`:
  Formats and reports an exception.
- `gmcu_log_set_output_handler(_handler)`: Replaces target output.
- `gmcu_log_set_telemetry_handler(_handler)`: Sets optional telemetry
  forwarding.
- `gmcu_log_buffer_get()`, `gmcu_log_buffer_clear()`, and
  `gmcu_log_buffer_set_capacity(_capacity)`: Manage the Dev Menu log buffer.
- `GMCU_LOG_LEVEL_*` and `GMCU_ENABLE_*_LOG`: Severity and build-policy macros.

[`InGameNotifications`](in-game-notifications.md) can register the optional
visual handler. Logging does not depend directly on analytics SDKs or HTML5.

## Contributing

Keep each `scripts/gmcu_log_*` resource path local in the consumer and symlink
the corresponding folders to Common Utils.
