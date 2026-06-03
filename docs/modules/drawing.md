# Drawing

Import `Drawing` after `Core` and before modules that draw temporary UI.

Resources:

- `scripts/DrawingParameters/DrawingParameters.yy`

`DrawingParameters` captures the current draw state and restores it through
`apply()`. This prevents helper UI code from leaking alpha, color, alignment,
or font changes into the rest of the Draw event.

