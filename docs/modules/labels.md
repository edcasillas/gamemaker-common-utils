# Labels

`Labels` provides reusable game-space and GUI-space text objects with optional
localization and outlined text drawing.

## Resources

- `scripts/gmcu_draw_text_outlined`
- `objects/gmcu_o_base_label`
- `objects/gmcu_o_label_game`
- `objects/gmcu_o_label_gui`

## Dependencies

Import after:

1. `Core`
2. `Drawing`
3. `Localization`
4. `LayeredGUI`

## API

Function:

- `gmcu_draw_text_outlined(_x, _y, _text, _outline_thickness = 0, _outline_color = c_white, _scale = 1)`

Objects:

- `gmcu_o_base_label`
- `gmcu_o_label_game`
- `gmcu_o_label_gui`

Set `translate` to use `gmcu_localization_t(text)`. The resolved string is
stored in `actual_text` and used for drawing.

Fonts, colors, text keys, positions, and GUI priorities remain consumer-owned.
