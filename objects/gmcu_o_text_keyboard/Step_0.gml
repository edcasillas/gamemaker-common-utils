if (!instance_exists(target) || gmcu_o_input_hub.current_input_owner() != "text_input") { nav_button=-1; exit; }
var buttons = [gp_padl,gp_padr,gp_padu,gp_padd];
var directions = [GMCU_DIRECTION_ANGLE.LEFT,GMCU_DIRECTION_ANGLE.RIGHT,GMCU_DIRECTION_ANGLE.UP,GMCU_DIRECTION_ANGLE.DOWN];
var held = -1;
for (var i=0;i<4;i++) if (gmcu_o_input_hub.input_state_down(gmcu_gamepad_input_state(buttons[i]),"text_input")) { held=i; break; }
if (held == -1) nav_button=-1;
else if (held != nav_button) { nav_button=held; nav_due=current_time+400; navigate(directions[held]); }
else if (current_time >= nav_due) { nav_due=current_time+80; navigate(directions[held]); }
