# Buttons

`Buttons` provides reusable base objects for sprite-based controls operated
through mouse, keyboard, or gamepad input. The module owns common button
behavior:

- Idle, hovered, and pressed visual states.
- Optional centered and localized text.
- Optional click audio.
- Press-then-release validation.
- Delayed activation.
- Dispatch of a shared event containing a consumer-defined button id.

The module does not decide what `play`, `resume`, or another button should do.
A consumer controller listens for `GMCU_EVENT_BUTTON_PRESSED` and handles the
received `button_id`.

## Which Object To Use

The three objects form this inheritance hierarchy:

```text
gmcu_o_base_button
├── gmcu_o_base_button_game
└── gmcu_o_base_button_gui
```

Do not normally place `gmcu_o_base_button` directly. It contains shared state,
callbacks, validation, drawing logic, and event dispatch, but does not register
itself for interaction or choose a draw space.

Create a project-owned child of:

- `gmcu_o_base_button_gui` for menus, HUD controls, and other Draw GUI
  interfaces. It subscribes to [`UniversalCursor`](universal-cursor.md) and
  [`LayeredGUI`](layered-gui.md), draws at
  `GMCU_GUI_PRIORITY_DEFAULT`, and passes `button_id` to both diagnostic pages.
- `gmcu_o_base_button_game` for controls drawn in the normal Draw event. It
  subscribes to [`UniversalCursor`](universal-cursor.md) and draws normally,
  but does not use LayeredGUI.

Universal Cursor performs hit testing in GUI coordinates using the
subscriber's `x`, `y`, `sprite_width`, and `sprite_height`. A game-space button
therefore works without customization only when its coordinates align with GUI
space. See the [UniversalCursor limitations](universal-cursor.md#position-and-hit-testing)
before choosing the game-space variant for camera-based interfaces.

## Creating A Button

1. Create a child object of `gmcu_o_base_button_gui` or
   `gmcu_o_base_button_game`.
2. Assign a sprite with these frames:

```text
0 = idle
1 = hovered
2 = pressed
```

3. Configure at least a unique, non-empty `button_id`.
4. Optionally configure text, font, sound, localization, delay, and debugging.
5. Place instances in the room and override per-instance properties when
   several buttons share the same child object.
6. Show the Universal Cursor while the interface is active.
7. Handle `GMCU_EVENT_BUTTON_PRESSED` in a controller.

The base Create event destroys a button with an empty `button_id` or no sprite,
and logs the reason.

## Quickstart

```gml
// Child object Create
event_inherited();
if (!created) return;

// Give the shared module a stable id for diagnostics and events.
button_id = "play";

// Optional text shown on top of the button sprite.
text = "PLAY";
```

```gml
// Menu controller Create
gmcu_universal_cursor_show(spr_cursor);
gmcu_eventbus_subscribe(GMCU_EVENT_BUTTON_PRESSED);

on_event = function(_event_name, _event_args) {
	if (_event_name != GMCU_EVENT_BUTTON_PRESSED) return;

	// Handle button ids here instead of hardcoding behavior into the shared button.
	if (_event_args == "play") {
		start_game();
	}
};
```

## Handling Activation

Subscribe a controller through [`EventBus`](event-bus.md):

```gml
// Controller Create
gmcu_eventbus_subscribe(GMCU_EVENT_BUTTON_PRESSED);

on_event = function(_event_name, _event_args) {
	if (_event_name != GMCU_EVENT_BUTTON_PRESSED) return;

	switch (_event_args) {
		case "play":
			start_game();
			break;

		case "quit":
			game_end();
			break;
	}
};
```

Unsubscribe the controller in Clean Up:

```gml
gmcu_eventbus_unsubscribe(GMCU_EVENT_BUTTON_PRESSED);
```

The event argument is exactly the activated button's `button_id`. This keeps
shared buttons independent from project rooms, controllers, and actions.

## Interaction Sequence

[`UniversalCursor`](universal-cursor.md) calls the inherited button callbacks:

1. `on_hover_enter()` selects sprite frame `1`.
2. `on_pressed()` selects frame `2` and records a valid press.
3. `on_released()` returns to frame `1`, optionally plays audio, and schedules
   Alarm 0.
4. Alarm 0 dispatches `GMCU_EVENT_BUTTON_PRESSED` with `button_id`.
5. `on_hover_leave()` returns to frame `0` and cancels an incomplete press.

A release activates the button only after that button received a valid press.
When `action_delay` is `0`, activation is still deferred by one step rather
than dispatched inside the input callback.

When `is_interactable` is false, inherited callbacks ignore hover, press,
release, and Alarm 0 activation. The button remains subscribed to Universal
Cursor; callers that disable a currently hovered button may call
`on_hover_leave()` themselves to reset its visual state immediately.

## Properties

- `button_id`: Required string sent as the event argument and used as the
  diagnostic name.
- `text`: Optional centered label. When localization is enabled, this is the
  key passed to [`gmcu_localization_t`](localization.md).
- `action_delay`: Number of steps between a valid release and event dispatch.
  `0` becomes a one-step delay.
- `font`: Optional font used for the label. The current draw font is used when
  no font is assigned.
- `text_color`: Label color for every visual state.
- `click_sound`: Optional sound played after a valid release.
- `click_sound_priority`: Priority passed to `audio_play_sound`; defaults to
  `500`.
- `localize_text`: When true and `text` is non-empty, localizes it once during
  Create.
- `is_interactable`: Enables or suppresses inherited interaction behavior.
- `debug_events`: Logs hover, press, and release callbacks and forwards them to
  the optional visual notification handler.

Text color does not change automatically between idle, hover, and pressed
states. Use sprite frames for the standard visual state changes, or override
the inherited callbacks in a consumer child when different text styling is
required.

## Extending A Button

When a child adds a Create event, call the inherited event first and stop if
the base validation destroyed the instance:

```gml
event_inherited();
if (!created) return;

// Project-specific initialization.
```

When overriding `on_hover_enter`, `on_hover_leave`, `on_pressed`, or
`on_released`, preserve the inherited press-state and activation behavior
unless the child intentionally replaces the complete button contract.

The GUI and game variants own their Universal Cursor unsubscription in Clean
Up. The GUI variant also owns LayeredGUI unsubscription. If a child overrides
Clean Up, call `event_inherited()` so persistent managers do not retain a dead
instance.

The Mouse events on `gmcu_o_base_button_game` are intentionally empty
placeholders. Universal Cursor provides mouse, keyboard, and gamepad behavior;
do not uncomment those events unless intentionally replacing or duplicating
that input path.

## Resources

- `scripts/gmcu_button_events`: Defines `GMCU_EVENT_BUTTON_PRESSED`.
- `objects/gmcu_o_base_button`: Owns properties, validation, localization,
  drawing, visual callbacks, sound, delay, and EventBus dispatch.
- `objects/gmcu_o_base_button_game`: Normal Draw-event variant with Universal
  Cursor registration.
- `objects/gmcu_o_base_button_gui`: Draw GUI variant with Universal Cursor and
  LayeredGUI registration.

## Dependencies

| Module | Responsibility |
| --- | --- |
| [`EventBus`](event-bus.md) | Dispatches button activation to consumer controllers. |
| [`Localization`](localization.md) | Resolves optional localized text. |
| [`UniversalCursor`](universal-cursor.md) | Supplies mouse, keyboard, and gamepad hover and activation. |
| [`LayeredGUI`](layered-gui.md) | Draws GUI buttons in shared GUI order. |
| [`Drawing`](drawing.md) | Restores draw state after rendering button text. |
| [`Logging`](logging.md) | Reports invalid configuration and optional input diagnostics. |
| [`Core`](core.md) | Shared base dependency used by the modules above. |

## API

Event:

- `GMCU_EVENT_BUTTON_PRESSED`: Dispatched after a valid release and optional
  delay. Its argument is the button's `button_id`.

Objects:

- `gmcu_o_base_button`: Shared abstract behavior.
- `gmcu_o_base_button_game`: Consumer parent for normal Draw-space buttons.
- `gmcu_o_base_button_gui`: Consumer parent for Draw GUI-space buttons.

Inherited instance methods:

- `do_draw()`: Draws the sprite and optional centered text while restoring draw
  state.
- `on_hover_enter()`: Applies the hover frame when interactable.
- `on_hover_leave()`: Restores idle and cancels an incomplete press.
- `on_pressed()`: Applies the pressed frame and records a valid press.
- `on_released()`: Plays optional audio and schedules activation after a valid
  press.

## Improvement Opportunities

The current module is usable and intentionally preserves existing consumer
behavior. The following are design opportunities, not committed API changes:

- **Clarify or replace the game-space variant.** Universal Cursor performs
  GUI-space hit testing, so `gmcu_o_base_button_game` works reliably only when
  game and GUI coordinates align. A future design could accept explicit bounds
  or coordinate conversion callbacks, or rename the variant to communicate
  this limitation.
- **Support a direct action callback.** EventBus is useful when a controller
  should own all menu policy, but it adds subscription and string-switch
  overhead for simple local actions. An optional callback could execute
  directly while retaining EventBus as the default or fallback.
- **Make delay semantics explicit.** `action_delay = 0` currently becomes a
  one-step delay. A future API could make zero immediate or rename the property
  to `action_delay_steps` and document a minimum of one.
- **Decouple visual states from fixed sprite frames.** The current
  `0 = idle`, `1 = hovered`, `2 = pressed` convention is simple but rigid.
  Optional state callbacks or configurable frame properties could support
  animation and alternative presentation without replacing interaction logic.
- **Centralize disabled-state transitions.** Setting `is_interactable` to false
  does not automatically clear hover or pressed presentation. A setter such as
  `set_interactable()` could own state cleanup and prevent consumers from
  calling `on_hover_leave()` manually.
- **Protect callback invariants.** Consumer overrides must preserve internal
  state such as `is_pressed`. Separating state transitions from overridable
  visual hooks would make customization less error-prone.
- **Remove or formalize empty Mouse events.** The game-space variant contains
  intentionally inactive Mouse event placeholders. Removing them would reduce
  confusion, while enabling them would require a clear policy to avoid
  duplicate Universal Cursor input.
- **Refresh localized text at runtime.** Text is localized once during Create.
  Projects that change language while a button remains alive currently need
  their own refresh path.

Any implementation should remain backward compatible unless consumers
explicitly accept a migration. Prefer solving a demonstrated project need over
adding configuration for hypothetical variants.

## Consumer Ownership

Sprites, fonts, sounds, button ids, localized strings, child objects, menu
layout, cursor sprite, and controller actions remain in the consuming project.

For editable submodule use, keep the consumer `.yyp` paths local and symlink
the local resource folders to `vendor/gamemaker-common-utils`.
