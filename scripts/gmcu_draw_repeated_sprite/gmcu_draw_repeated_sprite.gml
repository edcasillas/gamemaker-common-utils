/// @description Draws one sprite repeatedly in a horizontal row.

/**
 * Draws one sprite repeatedly from left to right using the requested repeat count.
 * @param {Real} _x Left-most draw position.
 * @param {Real} _y Shared draw position for every sprite draw.
 * @param {Asset.GMSprite} _sprite_index Sprite to repeat.
 * @param {Real} _count Amount of times to draw the sprite.
 */
function gmcu_draw_repeated_sprite(_x, _y, _sprite_index, _count) {
	var _width = sprite_get_width(_sprite_index);
	for(var _i = 0; _i < _count; ++_i) {
		draw_sprite(_sprite_index, 0, _x + (_i * _width), _y);
	}
}
