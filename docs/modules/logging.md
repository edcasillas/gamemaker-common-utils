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
`show_debug_message` and does not depend on GameAnalytics, JSUtils,
GlobalStats.io, NoMobileWeb, or project-specific services.

`log_error` and `log_exception` can show visual notifications when another
module registers a notification handler through
`common_utils_set_notification_handler`.

