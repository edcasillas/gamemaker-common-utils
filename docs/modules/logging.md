# Logging

Import `Logging` after `Core`.

Resources:

- `scripts/log_config/log_config.yy`
- `scripts/get_log_tags/get_log_tags.yy`
- `scripts/log_debug/log_debug.yy`
- `scripts/log_info/log_info.yy`
- `scripts/log_warn/log_warn.yy`
- `scripts/log_error/log_error.yy`
- `scripts/log_exception/log_exception.yy`

Logging is intentionally portable. It writes to GameMaker's debug output with
`show_debug_message` and does not depend on GameAnalytics, GlobalStats.io,
HTML5 Helpers, or project-specific services.

Consumers can preserve project telemetry by registering a handler:

```gml
gmcu_log_set_telemetry_handler(function(_severity, _message) {
    analytics_send_error(_severity, _message);
});
```

The handler receives `GMCU_LOG_LEVEL_DEBUG`, `GMCU_LOG_LEVEL_INFO`,
`GMCU_LOG_LEVEL_WARN`, or `GMCU_LOG_LEVEL_ERROR`. Exceptions are reported as
error severity. `log_debug(_message, true)` remains local-only and does not
invoke the telemetry handler. Dispatch is recursion-protected so failures in
the analytics adapter cannot create an infinite logging loop.

`log_error` and `log_exception` can show visual notifications when another
module registers a notification handler through
`common_utils_set_notification_handler`.
