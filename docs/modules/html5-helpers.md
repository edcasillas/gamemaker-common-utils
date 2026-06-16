# HTML5 Helpers

`HTML5 Helpers` provides small browser integrations through a GameMaker HTML5
JavaScript extension.

## Quickstart

Call these helpers only on HTML5, or guard cross-target calls with
`os_browser != browser_not_a_browser`.

```gml
if (os_browser != browser_not_a_browser) {
	// Detect mobile browsers before enabling desktop-only gameplay.
	if (gmcu_html5_is_mobile_device()) {
		gmcu_html5_block_canvas("Mobile devices are not supported.");
	}
}
```

## Resources

- `extensions/gmcu_html5_helpers`

## Dependencies

| Module | Responsibility |
| --- | --- |
| None | `HTML5 Helpers` is a standalone extension module. |

## Dependency Diagram

```mermaid
flowchart LR
    HTML5Helpers[HTML5 Helpers]
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

`gmcu_html5_generate_uuid` uses `crypto.randomUUID()` and therefore requires a
secure browser context.

`gmcu_html5_block_canvas` preserves the original dynamic canvas-disabler
presentation, including the `⚠️` marker, message, back button, and timer
cleanup.

The extension also preserves the legacy early mobile-blocking behavior through
an HTML5 `PostBody` injection of `datafiles/disable-mobile.js`. That script
wraps the existing `window.onload`, lets GameMaker initialize for analytics,
then immediately replaces the mobile view with the original warning layout.

## Contributing

Consumers that import the included `disable-mobile.js` opt into its fixed
mobile-blocking policy and message. Analytics and game-state changes remain
consumer-owned.

These functions are HTML5 extension functions. Guard calls that can execute on
other targets with `os_browser != browser_not_a_browser`.
