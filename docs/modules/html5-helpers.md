# HTML5 Helpers

`HTML5 Helpers` provides small browser integrations through a GameMaker HTML5
JavaScript extension.

## Resource

- `extensions/gmcu_html5_helpers`

## API

- `gmcu_html5_is_mobile_device()`
- `gmcu_html5_block_canvas(_message)`
- `gmcu_html5_console_error(_message)`

`gmcu_html5_block_canvas` hides `gm4html5_div_id` and inserts an accessible DOM
message with a browser-back button. The message is added with `textContent`, so
consumer text is not interpreted as HTML.

The extension also preserves the legacy early mobile-blocking behavior through
an HTML5 `PostBody` injection of `datafiles/disable-mobile.js`. That script
wraps the existing `window.onload`, lets GameMaker initialize for analytics,
then immediately replaces the mobile view with the original warning layout.

## Consumer-Owned Requirements

Consumers that import the included `disable-mobile.js` opt into its fixed
mobile-blocking policy and message. Analytics and game-state changes remain
consumer-owned.

These functions are HTML5 extension functions. Guard calls that can execute on
other targets with `os_browser != browser_not_a_browser`.
