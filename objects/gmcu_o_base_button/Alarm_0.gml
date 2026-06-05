/// @description Trigger the button pressed event after the specified delay
if(!is_interactable) return;
eventbus_dispatch(GMCU_EVENT_BUTTON_PRESSED, button_id);
