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

## Consumer-Owned Requirements

The consumer decides whether mobile browsers should be blocked, supplies the
displayed message, and owns any analytics or game-state changes performed
before blocking the canvas. Common Utils does not inject a startup script or
assume that every game rejects mobile play.

These functions are HTML5 extension functions. Guard calls that can execute on
other targets with `os_browser != browser_not_a_browser`.
