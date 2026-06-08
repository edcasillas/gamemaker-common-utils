# Drawing

`Drawing` captures and restores GameMaker draw state so reusable UI code does
not leak font, color, alignment, or alpha changes into later drawing.

## Usage

Create a snapshot before temporary draw changes and call `apply()` afterward:

```gml
var _draw_state = new gmcu_DrawingParameters();
draw_set_color(c_red);
draw_text(32, 32, "Warning");
_draw_state.apply();
```

## Resources

- `scripts/gmcu_drawing_parameters`: Declares the draw-state snapshot
  constructor and its restore method.

## Dependencies

- [`Core`](core.md): Must be registered first as the Common Utils foundation.

## API

- `new gmcu_DrawingParameters()`: Captures the current font, color, horizontal
  alignment, vertical alignment, and alpha.
- `gmcu_DrawingParameters.apply()`: Restores the captured draw state.

## Contributing

Keep `scripts/gmcu_drawing_parameters/gmcu_drawing_parameters.yy` as the local
consumer path and symlink its folder to Common Utils.
