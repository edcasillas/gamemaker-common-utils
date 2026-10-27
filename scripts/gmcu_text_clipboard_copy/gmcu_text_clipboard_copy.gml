/** Copy arbitrary text through the browser bridge or native clipboard.
 * @param {string} _text Text to copy.
 * @returns {boolean} Whether the browser accepted the copy operation.
 */
function gmcu_text_clipboard_copy(_text) {
    if (os_browser != browser_not_a_browser) {
        return gmcu_text_clipboard("copy", _text, "", 0) == 1;
    }

    try {
        clipboard_set_text(_text);
        return true;
    } catch (_clipboard_error) {
        gmcu_log_error("gmcu_text_clipboard_copy: native clipboard write failed: " + string(_clipboard_error));
        return false;
    }
}
