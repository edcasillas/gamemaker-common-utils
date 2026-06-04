#macro GMCU_EVENT_GAMEPAD_BUTTON_PRESSED "GMCU_EVENT_GAMEPAD_BUTTON_PRESSED" // event args is the button being pressed (gp_*)
#macro GMCU_EVENT_GAMEPAD_BUTTON_RELEASED "GMCU_EVENT_GAMEPAD_BUTTON_RELEASED" // event args is the button being released (gp_*)

enum GMCU_DIRECTION_ANGLE {
	RIGHT = 0,
	UP_RIGHT = 45,
	UP = 90,
	UP_LEFT = 135,
	LEFT = 180,
	DOWN_LEFT = 225,
	DOWN = 270,
	DOWN_RIGHT = 315
}
