# Dev Menu

`Dev Menu` provides a programmatically configured, persistent development
overlay. It is available only when `GMCU_IS_DEV_BUILD` is true and does not require
an object to be placed in a room.

## Usage

Create a root page and pass it to `gmcu_dev_menu_init`. The function creates or
reconfigures the persistent menu singleton.

The consumer owns a plain `config` struct. That struct tells the singleton:

- which pages exist
- how the menu should open
- whether opening it is modal or non-modal
- which lifecycle callbacks should run
- how the theme should look

## Resources

- `scripts/gmcu_dev_menu`
- `objects/gmcu_o_dev_menu`

## Dependencies

- [`Core`](core.md): Supplies DevBuild policy and shared constants.
- [`Drawing`](drawing.md): Protects overlay draw state.
- [`Logging`](logging.md): Reports callback failures and supplies log history.
- [`InputHub`](input-hub.md): Supplies keyboard/gamepad navigation.
- Optional [`LayeredGUI`](layered-gui.md): Supplies subscriber diagnostics when
  its manager exists in the current room.
- Optional [`UniversalCursor`](universal-cursor.md): Supplies interactable and
  hover diagnostics while its singleton exists.

Initialize the singleton:

```gml
var _config = {
    pages: [
        // gmcu_dev_menu_page(id, title, items)
        // "main" is the root page id. Submenus can open this page by id.
        // "Dev Menu" is the visible page title shown in the header.
        gmcu_dev_menu_page("main", "Dev Menu", [
            // gmcu_dev_menu_action(label, callback)
            // This creates one selectable row in the page.
            gmcu_dev_menu_action("Run action", function() {
                show_debug_message("Action");
            })
        ])
    ]
};

// Creates the persistent singleton the first time, or reconfigures it later.
gmcu_dev_menu_init(_config);
```

Minimal non-modal example:

```gml
gmcu_dev_menu_init({
    block_game_instances: false,
    pages: [
        // Root page shown when the menu opens.
        gmcu_dev_menu_page("main", "Dev Menu", [
            // A single action row that restarts the current room.
            gmcu_dev_menu_action("Restart room", function() {
                room_restart();
            })
        ])
    ]
});
```

Dynamic root-page example:

```gml
function build_root_items() {
    return [
        // Opens another page whose id is "gameplay".
        gmcu_dev_menu_submenu("Gameplay", "gameplay"),

        // Runs a callback immediately when the row is activated.
        gmcu_dev_menu_action("Reload current room", function() {
            room_restart();
        })
    ];
}

gmcu_dev_menu_init({
    pages: [
        // Root page:
        // - id: "main"
        // - title: "Dev Menu"
        // - items: [] because this page is dynamic
        // - get_items: build_root_items
        gmcu_dev_menu_page("main", "Dev Menu", [], build_root_items),

        // Secondary page opened by the submenu above.
        gmcu_dev_menu_page("gameplay", "Gameplay", [
            // Toggle rows ask for the current value and a setter callback.
            gmcu_dev_menu_toggle("God mode", function() { return global.god_mode; }, function(_value) {
                global.god_mode = _value;
            })
        ])
    ]
});
```

`gmcu_dev_menu_init` creates the persistent object, or reconfigures and returns
the existing instance. Outside `DevBuild` it returns `noone`.

The default trigger is F1. Supply `trigger_pressed` in the config to replace
it. Optional `pause`, `resume`, `on_open`, and `on_close` callbacks let the
consumer own simulation policy.

By default, opening the menu deactivates all other instances and closing it
reactivates them. This makes the overlay modal and prevents gameplay, UI,
mouse, keyboard, gamepad, and EventBus consumers from receiving input while it
is open. Set `block_game_instances: false` only when the consumer implements
its own complete input and simulation blocking policy.

In-game notification instances remain active while the menu is open so
exceptions caught by menu callbacks can still appear above the overlay.
Callbacks invoked by the menu are exception-isolated: failures are reported
through Logging instead of escaping the menu Step event.

## API

### Config Struct

`gmcu_dev_menu_init(_config)` accepts a consumer-owned struct with these fields:

- `pages`
  Array of page structs. Optional but strongly recommended. If omitted or empty,
  the menu creates a default root page.
- `trigger_pressed`
  Optional callback returning true on the Step where the menu should open or
  close. Default: `gmcu_dev_menu_default_trigger()`, which checks `F1`.
- `block_game_instances`
  Optional bool. `true` makes the menu modal by deactivating other instances on
  open and reactivating them on close. Default: `true`.
- `pause`
  Optional callback run after opening the menu.
- `resume`
  Optional callback run when the menu closes.
- `on_open`
  Optional callback run when the menu opens.
- `on_close`
  Optional callback run when the menu closes.
- `theme`
  Optional struct overriding overlay/panel/text/log colors and font.

### Page Builders

- `gmcu_dev_menu_page(_id, _title, _items = [], _get_items = undefined)`
  Creates a page definition. Use `_items` for static rows and `_get_items` for
  dynamic rows.
- `gmcu_dev_menu_action(_label, _action, _enabled = undefined)`
  Creates a row that runs a callback.
- `gmcu_dev_menu_submenu(_label, _page_id)`
  Creates a row that opens another page.
- `gmcu_dev_menu_toggle(_label, _get_value, _set_value)`
  Creates a boolean row that toggles on activation.
- `gmcu_dev_menu_value(_label, _get_value, _change_value)`
  Creates a row that changes with left/right input.

### Runtime Helpers

- `gmcu_dev_menu_default_trigger()`
  Returns true when the default open/close trigger fires.
- `gmcu_dev_menu_init(_config)`
  Creates or reconfigures the singleton menu object.
- `gmcu_dev_menu_is_open()`
  Returns whether the singleton is currently open.
- `gmcu_ui_overlay_blocks_pointer_input()`
  Returns whether overlay UI currently owns gameplay pointer input.

### Built-In Page Adapters

- `gmcu_dev_menu_add_rooms(_config, _settings = {})`
  Adds a generated Rooms page and root submenu.
- `gmcu_dev_menu_add_languages(_config, _settings)`
  Adds a generated Language page and root submenu.
- `gmcu_dev_menu_add_logs(_config)`
  Adds the built-in Logs page and root submenu.

The room module supports filter, label, sorting, and transition callbacks.
Language integration is callback-based. The log viewer reads the bounded
structured buffer maintained by the Logging module. Log rows use severity
colors by default: debug is white, info is muted gray, warnings are yellow,
and errors or exceptions are red. Override these theme fields when needed:

- `log_debug_color`
- `log_info_color`
- `log_warn_color`
- `log_error_color`

Log rows are copyable. Select one and press Enter, the gamepad confirmation
button, or click it to copy the complete message to the clipboard.

When [`LayeredGUI`](layered-gui.md) is also imported, the root page
automatically includes `Layered GUI` while its manager exists in the current
room. The page shows priority, object name, optional diagnostic name, and
instance id in actual draw order. Its rows use the same clipboard interaction
as logs. The snapshot is taken before the menu deactivates gameplay instances
and refreshes each time the menu opens. The integration resolves the optional
manager by asset name, so Dev Menu does not require LayeredGUI.

When [`UniversalCursor`](universal-cursor.md) is imported, the root page also
adds `Universal Cursor` while its singleton exists. The page lists object name,
optional diagnostic name, instance id, and the subscriber that was hovered
when the menu opened. Its rows are copyable. The optional cursor is resolved
by asset name, so Dev Menu does not require UniversalCursor.

Keyboard, gamepad, mouse hover, click, and wheel input are supported. Mobile
gestures can later be implemented through a custom `trigger_pressed` callback.

## Input Flow

The open/close trigger is checked by `gmcu_o_dev_menu` in its `Step` event, not
by `gmcu_dev_menu_default_trigger()` itself.

The flow is:

1. `gmcu_dev_menu_init(_config)` stores the consumer config on the singleton.
2. If `_config.trigger_pressed` is missing, `configure()` assigns
   `gmcu_dev_menu_default_trigger`.
3. Each Step, `gmcu_o_dev_menu/Step_1.gml` calls `config.trigger_pressed()`.
4. When that callback returns true:
   - if the menu is closed, it calls `open_menu()`
   - if the menu is open, it calls `close_menu()`

That same `Step` event also handles menu navigation while `is_open` is true:

- `Esc` or gamepad cancel -> `go_back()`
- `Up` / `Down` -> selection movement
- `Left` / `Right` -> value change activation
- `Enter` / `Space` / gamepad confirm -> item activation
- mouse move / click / wheel -> hover, click, and scroll

## HTML5 Callback Safety

GameMaker HTML5 may lose locally captured variables from functions stored for
later execution. Standard room, language, and log pages therefore keep their
arguments and providers as explicit struct fields instead of closure-generated
callbacks.

Use named scripts or callbacks that do not depend on captured local variables
for consumer actions that must work on HTML5. Validate opening every dynamic
page and executing every deferred action in an actual HTML5 runner; a
successful VM compile does not detect these runtime failures.

## Room Navigation

The room adapter changes rooms but cannot initialize game-specific persistent
state. Consumers whose rooms depend on a controller, save state, or progression
object must provide a `goto_room` callback that prepares that state before
calling `room_goto`.

Rooms intended for direct IDE testing should also bootstrap their required
state independently rather than assuming they were entered through normal
progression.

## Contributing

Keep `scripts/gmcu_dev_menu` and `objects/gmcu_o_dev_menu` as local consumer
paths and symlink their folders to Common Utils.
