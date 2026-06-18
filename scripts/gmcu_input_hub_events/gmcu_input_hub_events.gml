/// @description Declares Input Hub EventBus event names and direction angles.
#macro GMCU_EVENT_KEYBOARD_KEY_PRESSED "GMCU_EVENT_KEYBOARD_KEY_PRESSED" // event args is the key being pressed (vk_*)
#macro GMCU_EVENT_KEYBOARD_KEY_RELEASED "GMCU_EVENT_KEYBOARD_KEY_RELEASED" // event args is the key being released (vk_*)
#macro GMCU_EVENT_GAMEPAD_BUTTON_PRESSED "GMCU_EVENT_GAMEPAD_BUTTON_PRESSED" // event args is the button being pressed (gp_*)
#macro GMCU_EVENT_GAMEPAD_BUTTON_RELEASED "GMCU_EVENT_GAMEPAD_BUTTON_RELEASED" // event args is the button being released (gp_*)

#macro GMCU_INPUT_OWNER_GAMEPLAY "gameplay"
#macro GMCU_INPUT_OWNER_DEV_MENU "dev_menu"

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
