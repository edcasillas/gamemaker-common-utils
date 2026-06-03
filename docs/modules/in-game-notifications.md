# InGameNotifications

Import `InGameNotifications` after `Core` and `Drawing`.

Resources:

- `scripts/InGameNotificationSettings/InGameNotificationSettings.yy`
- `scripts/show_notification/show_notification.yy`
- `objects/o_notification_from_top/o_notification_from_top.yy`

API:

- `new InGameNotificationSettings(_text)`
- `show_notification(_notification_settings)`
- `show_notification(_text)`

When this module is imported, it registers a notification handler for the
Logging module through `common_utils_set_notification_handler`. In dev builds,
`log_error` and `log_exception` can then show visual notifications without
Logging depending directly on this module.

