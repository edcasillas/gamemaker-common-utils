// Publish field validity and feedback without choosing a presentation.
var valid = state.valid(); // Whether every required position contains an accepted character.
var invalid = touched && !editing && !valid; // Incomplete field after editing closes.
var message = invalid ? string(text_length) + " characters required" : feedback; // Status for optional host presentation.
var severity = invalid ? "error" : (message == "" ? "none" : "info"); // Host-facing status category.
var status = json_stringify([valid, invalid, editing, message, severity]); // Comparable snapshot of published state.

if (status != last_status) {
    last_status = status;
    gmcu_eventbus_dispatch(GMCU_EVENT_TEXT_STATUS_CHANGED, {
        textbox_id: textbox_id,
        valid: valid,
        invalid: invalid,
        editing: editing,
        message: message,
        severity: severity
    });
}
