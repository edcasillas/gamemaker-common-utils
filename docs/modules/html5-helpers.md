# HTML5 Helpers

`HTML5 Helpers` provides small browser integrations through a GameMaker HTML5
JavaScript extension plus small HTML5-specific helper scripts.

## Quickstart

Call these helpers only on HTML5, or guard cross-target calls with
`os_browser != browser_not_a_browser`.

```gml
if (os_browser != browser_not_a_browser) {
	// Detect mobile browsers before enabling desktop-only gameplay.
	if (gmcu_html5_is_mobile_device()) {
		gmcu_html5_block_canvas("Mobile devices are not supported.");
	}

	// Route Common Utils logs to the browser console with severity mapping.
	gmcu_html5_use_browser_console_for_logging();
}
```

## Resources

- `extensions/gmcu_html5_helpers`
- `scripts/gmcu_html5_use_browser_console_for_logging`

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Logging`](logging.md) | Provides `gmcu_log_set_output_handler()` and severity constants used by the browser-console adapter script. |

## Dependency Diagram

```mermaid
flowchart LR
    Logging[Logging] --> HTML5Helpers[HTML5 Helpers]
```

## API

| Item | Kind | Description |
| --- | --- | --- |
| `gmcu_html5_is_mobile_device()` | Function | Returns whether the current browser looks like a mobile device. |
| `gmcu_html5_block_canvas(_message)` | Function | Replaces the canvas with a blocking message. |
| `gmcu_html5_generate_uuid()` | Function | Returns a browser-generated UUID. |
| `gmcu_html5_console_debug(_message)` | Function | Writes a debug message to the browser console. |
| `gmcu_html5_console_info(_message)` | Function | Writes an info message to the browser console. |
| `gmcu_html5_console_warn(_message)` | Function | Writes a warning message to the browser console. |
| `gmcu_html5_console_error(_message)` | Function | Writes an error message to the browser console. |
| `gmcu_html5_use_browser_console_for_logging()` | Function | Routes Common Utils log output to `console.debug/info/warn/error` on HTML5. |

`gmcu_html5_generate_uuid` uses `crypto.randomUUID()` and therefore requires a
secure browser context.

`gmcu_html5_block_canvas` preserves the original dynamic canvas-disabler
presentation, including the `⚠️` marker, message, back button, and timer
cleanup.

The extension also preserves the legacy early mobile-blocking behavior through
an HTML5 `PostBody` injection of `datafiles/disable-mobile.js`. That script
wraps the existing `window.onload`, lets GameMaker initialize for analytics,
then immediately replaces the mobile view with the original warning layout.

These functions are HTML5 extension functions. Guard calls that can execute on
other targets with `os_browser != browser_not_a_browser`.

`gmcu_html5_use_browser_console_for_logging()` is a script helper for consumers
that already use the shared Logging module and want browser-native severity
levels without rewriting the adapter in each game bootstrap.

Consumers that import the included `disable-mobile.js` opt into its fixed
mobile-blocking policy and message. Analytics and game-state changes remain
consumer-owned.
