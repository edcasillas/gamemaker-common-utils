# Dev Menu

`Dev Menu` provides a programmatically configured, persistent development
overlay. It is available only when `GMCU_IS_DEV_BUILD` is true and does not require
an object to be placed in a room.

## Usage

Create a root page and pass it to `gmcu_dev_menu_init`. The function creates or
reconfigures the persistent menu singleton.

## Resources

- `scripts/gmcu_dev_menu`
- `objects/gmcu_o_dev_menu`

## Dependencies

- [`Core`](core.md): Supplies DevBuild policy and shared constants.
- [`Drawing`](drawing.md): Protects overlay draw state.
- [`Logging`](logging.md): Reports callback failures and supplies log history.
- [`InputHub`](input-hub.md): Supplies keyboard/gamepad navigation.

Initialize the singleton:

```gml
var _config = {
    pages: [
        gmcu_dev_menu_page("main", "Dev Menu", [
            gmcu_dev_menu_action("Run action", function() {
                show_debug_message("Action");
            })
        ])
    ]
};

gmcu_dev_menu_init(_config);
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

- `gmcu_dev_menu_action`
- `gmcu_dev_menu_submenu`
- `gmcu_dev_menu_toggle`
- `gmcu_dev_menu_value`
- `gmcu_dev_menu_page`
- `gmcu_dev_menu_add_rooms`
- `gmcu_dev_menu_add_languages`
- `gmcu_dev_menu_add_logs`

The room module supports filter, label, sorting, and transition callbacks.
Language integration is callback-based. The log viewer reads the bounded
structured buffer maintained by the Logging module. Log rows use severity
colors by default: debug is white, info is muted gray, warnings are yellow,
and errors or exceptions are red. Override these theme fields when needed:

- `log_debug_color`
- `log_info_color`
- `log_warn_color`
- `log_error_color`

Keyboard, gamepad, mouse hover, click, and wheel input are supported. Mobile
gestures can later be implemented through a custom `trigger_pressed` callback.

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
