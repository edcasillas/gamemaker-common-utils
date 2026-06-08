if (async_load[? "event_type"] == "gamepad discovered") {
    var _pad = async_load[? "pad_index"];
    gamepad_set_axis_deadzone(_pad, 0.2);
    array_push(gamepads, _pad);
	
	if(GMCU_IS_DEV_BUILD) {
		var _notif = new gmcu_InGameNotificationSettings("Gamepad discovered: " + string(_pad));
		_notif.back_color = c_gray;
		gmcu_show_notification(_notif);
	}
}
else if (async_load[? "event_type"] == "gamepad lost") {
    var _pad = async_load[? "pad_index"];
    var _index = array_get_index(gamepads, _pad);
    array_delete(gamepads, _index, 1);
	
	if(GMCU_IS_DEV_BUILD) {
		var _notif = new gmcu_InGameNotificationSettings("Gamepad lost: " + string(_pad));
		_notif.back_color = c_gray;
		gmcu_show_notification(_notif);
	}
}