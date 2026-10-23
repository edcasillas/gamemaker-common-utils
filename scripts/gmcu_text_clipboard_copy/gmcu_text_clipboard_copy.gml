/** Copy arbitrary text through the active HTML5 host bridge.
 * @param {string} _text Text to copy.
 * @returns {boolean} Whether the browser accepted the copy operation.
 */
function gmcu_text_clipboard_copy(_text) {
    return gmcu_text_clipboard("copy", _text, "", 0) == 1;
}
