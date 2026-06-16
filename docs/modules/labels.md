# Labels

`Labels` provides reusable game-space and GUI-space text objects with optional
localization and outlined text drawing.

## Quickstart

Create a child of the game-space or GUI-space label, set `text`, and enable
`translate` when the value is a [`Localization`](localization.md) key.

```gml
// Child Create
event_inherited();

// Use a localization key instead of literal text.
text = "PLAY";
translate = true;
```

## Resources

- `scripts/gmcu_draw_text_outlined`
- `objects/gmcu_o_base_label`
- `objects/gmcu_o_label_game`
- `objects/gmcu_o_label_gui`

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`Localization`](localization.md) | Resolves translated label text. |
| [`LayeredGUI`](layered-gui.md) | Orders GUI-space label drawing. |
| [`Drawing`](drawing.md) | Protects draw state. |
| [`Core`](core.md) | Base dependency used by the shared resources above. |

## Dependency Diagram

```mermaid
flowchart LR
    Core[Core] --> Localization[Localization]
    Core --> Drawing[Drawing]
    Core --> Logging[Logging]
    Drawing --> LayeredGUI[LayeredGUI]
    Logging --> LayeredGUI
    Localization --> Labels[Labels]
    Drawing --> Labels
    LayeredGUI --> Labels
```

## API

| Item | Kind | Description |
| --- | --- | --- |
| `gmcu_draw_text_outlined(_x, _y, _text, _outline_thickness = 0, _outline_color = c_white, _scale = 1)` | Function | Draws text with an optional outline. |
| `gmcu_o_base_label` | Object | Shared label behavior and drawing state. |
| `gmcu_o_label_game` | Object | Game-space label variant. |
| `gmcu_o_label_gui` | Object | GUI-space label variant. |

Set `translate` to use `gmcu_localization_t(text)`. The resolved string is
stored in `actual_text` and used for drawing.

Fonts, colors, text keys, positions, and GUI priorities remain consumer-owned.
