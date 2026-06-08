/**
 * @description Creates the presentation settings for an in-game notification.
 * @param {String} _text Notification text.
 * @constructor
 */
function gmcu_InGameNotificationSettings(_text) constructor {
	text = _text;
	back_color = c_green;
	outline_color = c_black;
	font_color = c_black;
	font = noone;
	enter_time = 0.3;
	exit_time = 0.3;
	view_time = 3;
	alpha = 0.8;
	offset_y = 0;
}
