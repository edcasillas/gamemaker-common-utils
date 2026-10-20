/** Fixed-position editable text. Empty slots remain distinct from display placeholders.
 * @param {String} _alphabet Accepted characters.
 * @param {Real} _length Required number of occupied slots.
 * @param {Bool} _case_sensitive Whether case variants are distinct.
 * @param {Bool} _wrap Whether caret movement wraps.
 * @param {String} _initial Initial text.
 */
function gmcu_TextState(_alphabet, _length, _case_sensitive, _wrap, _initial) constructor {
    alphabet = _alphabet; capacity = _length; case_sensitive = _case_sensitive; wrap = _wrap;
    caret = 0; slots = array_create(capacity, "");
    if (capacity < 1 || capacity != floor(capacity) || alphabet == "") show_error("Invalid textbox alphabet/length", true);
    for (var i = 1; i <= string_length(alphabet); i++) {
        var c = string_char_at(alphabet, i);
        for (var j = i + 1; j <= string_length(alphabet); j++) {
            var d = string_char_at(alphabet, j);
            if (c == d || (!case_sensitive && string_upper(c) == string_upper(d))) show_error("Ambiguous textbox alphabet", true);
        }
    }
    /** Normalize one character to its alphabet representation; return empty if rejected. */
    static normalize = function(_char) {
        if (string_length(_char) != 1) return "";
        if (string_pos(_char, alphabet) > 0 && _char != "") return _char;
        if (!case_sensitive) for (var k = 1; k <= string_length(alphabet); k++) {
            var candidate = string_char_at(alphabet, k);
            if (string_upper(candidate) == string_upper(_char)) return candidate;
        }
        return "";
    };
    /** Move the caret by the signed offset, wrapping or clamping to field boundaries. */
    static move = function(_offset) {
        caret = wrap ? (caret + _offset + capacity) mod capacity : clamp(caret + _offset, 0, capacity - 1);
    };
    /** Replace the current position with an accepted character and advance. */
    static type = function(_char) {
        var c = normalize(_char);
        if (c == "") return;
        slots[caret] = c; move(1);
    };
    /** Clear the current position without shifting its suffix, then move backward. */
    static erase = function() { slots[caret] = ""; caret = max(0, caret - 1); };
    /** Return whether every editable position is occupied. */
    static valid = function() {
        for (var k = 0; k < capacity; k++) if (slots[k] == "") return false;
        return true;
    };
    /** Return compact text; consumers must use slots for a lossless incomplete draft. */
    static text = function() {
        var result = ""; for (var k = 0; k < capacity; k++) result += slots[k]; return result;
    };
    /** Filter and paste text using replace_all or from_caret; return whether anything changed. */
    static paste = function(_text, _mode) {
        var clean = "";
        for (var k = 1; k <= string_length(_text); k++) clean += normalize(string_char_at(_text, k));
        if (clean == "" || _mode == "none") return false;
        var start = _mode == "replace_all" ? 0 : caret;
        if (_mode == "replace_all") slots = array_create(capacity, "");
        var count = min(string_length(clean), capacity - start);
        for (var k = 0; k < count; k++) slots[start + k] = string_char_at(clean, k + 1);
        caret = min(capacity - 1, start + count); return true;
    };
    if (string_length(_initial) > capacity) show_error("Textbox initial value exceeds capacity", true);
    for (var i = 1; i <= string_length(_initial); i++) {
        var c = normalize(string_char_at(_initial, i));
        if (c == "") show_error("Textbox initial value outside alphabet", true);
        slots[i - 1] = c;
    }
}
