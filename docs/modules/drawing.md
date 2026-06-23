# Drawing

`Drawing` captures and restores GameMaker draw state so reusable UI code does
not leak font, color, alignment, or alpha changes into later drawing.

## Quickstart

Create a snapshot before temporary draw changes and call `apply()` afterward:

```gml
// Capture the current draw state before changing it.
var _draw_state = new gmcu_DrawingParameters();
draw_set_color(c_red);
draw_text(32, 32, "Warning");
// Restore the previous font, color, alignment, and alpha.
_draw_state.apply();
```

## Resources

- `scripts/gmcu_draw_repeated_sprite`: Draws one sprite repeatedly in a
  horizontal row using the sprite's native width.
- `scripts/gmcu_drawing_parameters`: Declares the draw-state snapshot
  constructor and its restore method.

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Core`](core.md) | Base dependency required by the draw-state helper. |

## Dependency Diagram

```mermaid
flowchart LR
    Core[Core] --> Drawing[Drawing]
```

## API

| Item | Kind | Description |
| --- | --- | --- |
| `gmcu_draw_repeated_sprite(_x, _y, _sprite_index, _count)` | Function | Draws one sprite repeatedly from left to right using the sprite's native width. |
| `new gmcu_DrawingParameters()` | Constructor | Captures the current font, color, horizontal alignment, vertical alignment, and alpha. |
| `gmcu_DrawingParameters.apply()` | Method | Restores the captured draw state. |

## Example: Draw Repeated Icons

Use `gmcu_draw_repeated_sprite()` when a HUD wants to represent a counter with
repeated icons:

```gml
var _lives_count = 3;
gmcu_draw_repeated_sprite(32, 512, spr_life_icon, _lives_count);
```
