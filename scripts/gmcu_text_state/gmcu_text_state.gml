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

    // Require a nonempty alphabet and a positive whole-number slot count.
    if (alphabet == "" || !is_real(_length) || _length != capacity) config_error = "Invalid textbox alphabet/length";

    // Initial text must be a string before character-level checks can run.
    if (!is_string(_initial)) config_error = "Invalid textbox initial value";

    // Duplicate alphabet entries make keyboard normalization ambiguous.
    for (var first_index = 1; first_index <= string_length(alphabet); first_index++) {
        var first_character = string_char_at(alphabet, first_index); // Alphabet entry being checked.
        for (var second_index = first_index + 1; second_index <= string_length(alphabet); second_index++) {
            var second_character = string_char_at(alphabet, second_index); // Later alphabet entry.
            // Reject duplicate characters, including case-equivalent entries when case-insensitive.
            if (first_character == second_character || (!case_sensitive && string_upper(first_character) == string_upper(second_character))) {
                config_error = "Ambiguous textbox alphabet";
            }
        }
    }

    /** Normalize a character to its alphabet representation.
     * @param {String} _char Character to check.
     * @returns {String} Accepted character, or empty when rejected.
     */
    static normalize = function(_char) {
        if (string_length(_char) != 1) {
            return "";
        }

        if (string_pos(_char, alphabet) > 0 && _char != "") {
            return _char;
        }

        if (!case_sensitive) {
            for (var alphabet_index = 1; alphabet_index <= string_length(alphabet); alphabet_index++) {
                var candidate = string_char_at(alphabet, alphabet_index); // Accepted equivalent of the typed character.
                if (string_upper(candidate) == string_upper(_char)) {
                    return candidate;
                }
            }
        }

        return "";
    };

    /** Move the caret by the signed offset, wrapping or clamping to field boundaries. */
    static move = function(_offset) {
        caret = wrap ? (caret + _offset + capacity) mod capacity : clamp(caret + _offset, 0, capacity - 1);
    };

    /** Replace the current position with an accepted character and advance.
     * @param {String} _char Character to enter.
     */
    static type = function(_char) {
        var normalized_character = normalize(_char); // Accepted character, or empty when rejected.
        if (normalized_character == "") {
            return;
        }

        slots[caret] = normalized_character;
        move(1);
    };

    /** Clear the current position without shifting its suffix, then move backward. */
    static erase = function() {
        slots[caret] = "";
        caret = max(0, caret - 1);
    };

    /** Check whether every editable position is occupied.
     * @returns {Boolean} Whether the field contains a complete value.
     */
    static valid = function() {
        for (var slot_index = 0; slot_index < capacity; slot_index++) {
            if (slots[slot_index] == "") {
                return false;
            }
        }

        return true;
    };

    /** Return compact text; use slots for a lossless incomplete draft.
     * @returns {String} Occupied characters in slot order.
     */
    static text = function() {
        var result = ""; // Occupied characters in slot order.
        for (var slot_index = 0; slot_index < capacity; slot_index++) {
            result += slots[slot_index];
        }

        return result;
    };

    /** Filter and paste text using replace_all or from_caret.
     * @param {String} _text Source text.
     * @param {String} _mode Paste placement mode.
     * @returns {Boolean} Whether any accepted character was applied.
     */
    static paste = function(_text, _mode) {
        // Accepted characters filtered from pasted text.
        var clean = "";
        for (var text_index = 1; text_index <= string_length(_text); text_index++) {
            clean += normalize(string_char_at(_text, text_index));
        }

        if (clean == "" || _mode == "none") {
            return false;
        }

        // First editable position affected by paste.
        var start = _mode == "replace_all" ? 0 : caret;
        if (_mode == "replace_all") {
            slots = array_create(capacity, "");
        }

        var pasted_count = min(string_length(clean), capacity - start); // Characters that fit from the paste position.
        for (var pasted_index = 0; pasted_index < pasted_count; pasted_index++) {
            slots[start + pasted_index] = string_char_at(clean, pasted_index + 1);
        }

        caret = min(capacity - 1, start + pasted_count);
        return true;
    };

    // The initial value must fit in the available slots.
    if (string_length(initial) > capacity) {
        config_error = "Textbox initial value exceeds capacity";
    }

    for (var initial_index = 1; initial_index <= string_length(initial); initial_index++) {
        var normalized_character = normalize(string_char_at(initial, initial_index)); // Accepted initial character, or empty.
        // Every initial character must normalize into the alphabet.
        if (normalized_character == "") {
            config_error = "Textbox initial value outside alphabet";
        }

        // Skip writes beyond the safe slot array when the initial value is too long.
        if (initial_index <= capacity) {
            slots[initial_index - 1] = normalized_character;
        }
    }
}
