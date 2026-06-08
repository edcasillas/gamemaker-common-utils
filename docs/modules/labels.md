# Labels

`Labels` provides reusable game-space and GUI-space text objects with optional
localization and outlined text drawing.

## Usage

Create a child of the game-space or GUI-space label, set `text`, and enable
`translate` when the value is a [`Localization`](localization.md) key.

## Resources

- `scripts/gmcu_draw_text_outlined`
- `objects/gmcu_o_base_label`
- `objects/gmcu_o_label_game`
- `objects/gmcu_o_label_gui`

## Dependencies

- [`Localization`](localization.md): Resolves translated label text.
- [`LayeredGUI`](layered-gui.md): Orders GUI-space label drawing.
- [`Drawing`](drawing.md): Protects draw state.
- [`Core`](core.md)

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

## Contributing

Keep the listed resource paths local in the consumer and symlink their folders
to Common Utils.
