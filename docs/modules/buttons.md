# Buttons

`Buttons` provides reusable sprite-based base objects for game-space and
GUI-space buttons with localization, hover/press state, optional click audio,
and EventBus dispatch.

## Resources

- `scripts/gmcu_button_events`
- `objects/gmcu_o_base_button`
- `objects/gmcu_o_base_button_game`
- `objects/gmcu_o_base_button_gui`

## Dependencies

Import after:

1. `Core`
2. `Drawing`
3. `Logging`
4. `EventBus`
5. `Localization`
6. `LayeredGUI`
7. `UniversalCursor`

## API

Event:

- `GMCU_EVENT_BUTTON_PRESSED`

The event argument is the button's `button_id`.

Objects:

- `gmcu_o_base_button`
- `gmcu_o_base_button_game`
- `gmcu_o_base_button_gui`

Important inherited properties include:

- `button_id`
- `text`
- `action_delay`
- `font`
- `text_color`
- `click_sound`
- `click_sound_priority`
- `localize_text`
- `is_interactable`
- `debug_events`

## Consumer Notes

Create consumer-owned child objects for project sprites and behavior. Subscribe
controllers to `GMCU_EVENT_BUTTON_PRESSED` through EventBus.

Button sprites should provide frames `0`, `1`, and `2` for idle, hover, and
pressed states. Fonts, sounds, sprites, and button IDs remain consumer-owned.
