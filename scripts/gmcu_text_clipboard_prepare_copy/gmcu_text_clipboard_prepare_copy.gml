/** Prepare a GUI target so HTML5 can copy during its trusted pointer or virtual-controller gesture.
 * @param {string} _text Text copied when the prepared control is activated.
 * @param {real} _x GUI-space center X of the copy target.
 * @param {real} _y GUI-space center Y of the copy target.
 * @param {real} _width GUI-space target width.
 * @param {real} _height GUI-space target height.
 * @param {bool} [_allow_virtual_controller_a=false] Whether virtual-controller A may activate the target.
 * @param {bool} [_allow_keyboard_enter=false] Whether physical Enter may activate the target.
 * @returns {boolean} Whether the target was prepared, or true when no browser bridge is required.
 */
function gmcu_text_clipboard_prepare_copy(
    _text,
    _x,
    _y,
    _width,
    _height,
    _allow_virtual_controller_a = false,
    _allow_keyboard_enter = false
) {
    if (os_browser == browser_not_a_browser) {
        return true;
    }

    var copy_options = {
        bounds: [
            _x,
            _y,
            _width,
            _height,
            display_get_gui_width(),
            display_get_gui_height()
        ],
        allowVirtualControllerA: _allow_virtual_controller_a,
        allowKeyboardEnter: _allow_keyboard_enter
    };

    return gmcu_text_clipboard("prepare_copy", _text, json_stringify(copy_options), 0) == 1;
}
