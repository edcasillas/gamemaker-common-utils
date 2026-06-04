# LayeredGUI

`LayeredGUI` lets instances register an `on_draw_gui` callback with a priority
so GUI drawing can happen in a stable order from one Draw GUI manager.

## Resources

- `objects/gmcu_o_layered_gui_manager`
- `scripts/gmcu_layered_gui_subscribe`
- `scripts/gmcu_layered_gui_unsubscribe`

## Dependencies

Import after:

1. `Core`
2. `Drawing`
3. `Logging`

The manager uses `DrawingParameters` to restore draw state after each
subscriber, and logging for invalid subscriber diagnostics.

## API

Object:

- `gmcu_o_layered_gui_manager`

Functions:

- `gmcu_layered_gui_subscribe(_priority)`
- `gmcu_layered_gui_unsubscribe()`

Subscribers define:

```gml
function on_draw_gui() {
}
```

## Consumer Notes

Call `gmcu_layered_gui_subscribe(_priority)` from Create and
`gmcu_layered_gui_unsubscribe()` from Clean Up. Larger priority values are drawn
earlier by the current manager implementation; use project-level conventions
for priority ranges.

For editable submodule use, keep the consumer `.yyp` paths local and symlink
the local resource folders to `vendor/gamemaker-common-utils`.
