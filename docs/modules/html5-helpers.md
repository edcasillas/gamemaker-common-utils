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

## Optional mobile blocking

Import `extensions/gmcu_disable_mobile/gmcu_disable_mobile.yy` and register
`datafiles/disable-mobile.js` as an HTML5 Included File to enable blocking.
That JavaScript file is the single implementation and owns detection, warning
text, markup, and appearance. Editable consumers link their Included File to
this shared file rather than copying its contents.

The extension supplies the `PostCanvas` injection: a synchronous `<script src>`
that loads the Included File before the game runner. The `.yy` owns only the
resource metadata and script reference, never the implementation. Consumers
register the supplied resources without writing their own injection or blocker.
The module has no dependency on `gmcu_html5_helpers`.

The warning includes a Back button. Desktop browsers remain unchanged; iPadOS
browsers using a desktop user agent are detected through touch capability.
The game initializes behind the hidden container, allowing analytics startup;
this is a presentation block, not a runtime shutdown.

Importing `gmcu_html5_helpers` alone does not enable blocking. Consumers select
`gmcu_disable_mobile` explicitly and omit it when mobile gameplay is supported.
Do not activate a mobile-controller host and the blocking extension together.

### Mandatory timing contract

Mobile blocking is an HTML-template responsibility. The warning must be visible
before the runner loads, independently of GameMaker initialization or asset
loading. Showing the loading bar before the warning is a regression.

Do not move this behavior into an extension Init function, GML, room events,
`GameMaker_Init`, or runtime-readiness callbacks. Background initialization for
analytics cannot be a prerequisite for showing the warning. This contract also
applies to resource extraction and refactoring; changing it requires an explicit
consumer-owner decision.

Validate the injected HTML with an unavailable or deliberately delayed runner:
the mobile warning must still appear and hide the game container. Verify desktop
behavior is unchanged, then check a fresh consumer HTML5 export on a mobile
browser. Tests that only call the blocker after startup do not validate timing.

These functions are HTML5 extension functions. Guard calls that can execute on
other targets with `os_browser != browser_not_a_browser`.

`gmcu_html5_use_browser_console_for_logging()` is a script helper for consumers
that already use the shared Logging module and want browser-native severity
levels without rewriting the adapter in each game bootstrap.
