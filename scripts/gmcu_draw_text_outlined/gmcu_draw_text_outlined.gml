/**
@param {string} _text
*/
function gmcu_draw_text_outlined(_x, _y, _text, _outline_thickness = 0, _outline_color = c_white, _scale = 1) {
	if(_outline_thickness > 0) {
		var _prev_color = draw_get_color();
		
		draw_set_color(_outline_color);
		draw_text_transformed(_x - _outline_thickness, _y, _text, _scale, _scale, 0);
		draw_text_transformed(_x + _outline_thickness, _y, _text, _scale, _scale, 0);
		draw_text_transformed(_x, _y - _outline_thickness, _text, _scale, _scale, 0);
		draw_text_transformed(_x, _y + _outline_thickness, _text, _scale, _scale, 0);
		draw_text_transformed(_x - _outline_thickness, _y - _outline_thickness, _text, _scale, _scale, 0);
		draw_text_transformed(_x + _outline_thickness, _y - _outline_thickness, _text, _scale, _scale, 0);
		draw_text_transformed(_x - _outline_thickness, _y + _outline_thickness, _text, _scale, _scale, 0);
		draw_text_transformed(_x + _outline_thickness, _y + _outline_thickness, _text, _scale, _scale, 0);
		
		draw_set_color(_prev_color);
	}
	
	draw_text_transformed(_x, _y, _text, _scale, _scale, 0);
}
