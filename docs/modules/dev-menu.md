# Dev Menu

`Dev Menu` provides a programmatically configured, persistent development
overlay. It is available only when `IS_DEV_BUILD` is true and does not require
an object to be placed in a room.

## Resources

- `scripts/gmcu_dev_menu`
- `objects/gmcu_o_dev_menu`

## Dependencies

Import after:

1. `Core`
2. `Drawing`
3. `Logging`
4. `InputHub`

## Initialization

Create a root page and initialize the singleton:

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

## Items And Standard Pages

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
structured buffer maintained by the Logging module.

Keyboard, gamepad, mouse hover, click, and wheel input are supported. Mobile
gestures can later be implemented through a custom `trigger_pressed` callback.
