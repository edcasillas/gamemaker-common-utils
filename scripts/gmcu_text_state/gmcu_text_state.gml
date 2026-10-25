/** Fixed-position editable text. Empty slots remain distinct from display placeholders.
 * @param {String} _alphabet Accepted characters.
 * @param {Real} _length Required number of occupied slots.
 * @param {Bool} _case_sensitive Whether case variants are distinct.
 * @param {Bool} _wrap Whether caret movement wraps.
 * @param {String} _initial Initial text.
 */
function gmcu_TextState(_alphabet, _length, _case_sensitive, _wrap, _initial) constructor {
    alphabet = is_string(_alphabet) ? _alphabet : ""; // Accepted character set.
    capacity = 1; // Safe slot count, replaced by a valid requested length.
    if (is_real(_length)) {
        if (_length >= 1 && _length == floor(_length)) capacity = _length;
    }
    case_sensitive = _case_sensitive; // Whether letter case must match the alphabet.
    wrap = _wrap; // Whether caret movement wraps around field boundaries.
    caret = 0; // Active editable position.
    slots = array_create(capacity, ""); // Character or empty value at each position.
    config_error = ""; // Invalid configuration reason; empty when usable.
    // Initial text normalized into the fixed slots.
    var initial = is_string(_initial) ? _initial : "";
    if (alphabet == "" || !is_real(_length) || _length != capacity) config_error = "Invalid textbox alphabet/length";
    if (!is_string(_initial)) config_error = "Invalid textbox initial value";
    // Index for this sequence.
    for (var i = 1; i <= string_length(alphabet); i++) {
        // Character or key at the current position.
        var c = string_char_at(alphabet, i);
        // Second index for the alphabet comparison.
        for (var j = i + 1; j <= string_length(alphabet); j++) {
            // Second alphabet character in the uniqueness check.
            var d = string_char_at(alphabet, j);
            if (c == d || (!case_sensitive && string_upper(c) == string_upper(d))) config_error = "Ambiguous textbox alphabet";
        }
    }
    /** Normalize one character to its alphabet representation; return empty if rejected. */
    static normalize = function(_char) {
        if (string_length(_char) != 1) return "";
        if (string_pos(_char, alphabet) > 0 && _char != "") return _char;
        // Current key, slot, or character index.
        if (!case_sensitive) for (var k = 1; k <= string_length(alphabet); k++) {
            // Alphabet character being compared to typed input.
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
        // Character or key at the current position.
        var c = normalize(_char);
        if (c == "") return;
        slots[caret] = c;
        move(1);
    };
    /** Clear the current position without shifting its suffix, then move backward. */
    static erase = function() {
        slots[caret] = "";
        caret = max(0, caret - 1);
    };
    /** Return whether every editable position is occupied. */
    static valid = function() {
        // Current key, slot, or character index.
        for (var k = 0; k < capacity; k++) if (slots[k] == "") return false;
        return true;
    };
    /** Return compact text; consumers must use slots for a lossless incomplete draft. */
    static text = function() {
        var result = ""; // Occupied characters in slot order.
        // Current key, slot, or character index.
        for (var k = 0; k < capacity; k++) result += slots[k];
        return result;
    };
    /** Filter and paste text using replace_all or from_caret; return whether anything changed. */
    static paste = function(_text, _mode) {
        // Accepted characters filtered from pasted text.
        var clean = "";
        // Current key, slot, or character index.
        for (var k = 1; k <= string_length(_text); k++) clean += normalize(string_char_at(_text, k));
        if (clean == "" || _mode == "none") return false;
        // First editable position affected by paste.
        var start = _mode == "replace_all" ? 0 : caret;
        if (_mode == "replace_all") slots = array_create(capacity, "");
        // Number of characters or positions being processed.
        var count = min(string_length(clean), capacity - start);
        // Current key, slot, or character index.
        for (var k = 0; k < count; k++) slots[start + k] = string_char_at(clean, k + 1);
        caret = min(capacity - 1, start + count);
        return true;
    };
    if (string_length(initial) > capacity) config_error = "Textbox initial value exceeds capacity";
    // Index for this sequence.
    for (var i = 1; i <= string_length(initial); i++) {
        // Character or key at the current position.
        var c = normalize(string_char_at(initial, i));
        if (c == "") config_error = "Textbox initial value outside alphabet";
        if (i <= capacity) slots[i - 1] = c;
    }
    if (config_error != "") gmcu_log_error(config_error);
}
