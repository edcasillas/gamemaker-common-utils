/// @description Converts a number to a zero-padded string with a minimum width.

/**
 * Converts a number to a string with a minimum amount of digits, prepending zeroes on the left.
 * @param {Real} _number Number to format.
 * @param {Real} _min_digits Minimum amount of digits to preserve.
 * @returns {String}
 */
function gmcu_number_to_string_prepend_zeroes(_number, _min_digits) {
	return string_replace_all(string_format(_number, _min_digits, 0), " ", "0");
}
