// Resolve the independently placed status label after all room instances exist.
if (status_label_id != "" && !instance_exists(status_label)) {
    var matches = 0; // Labels using this field's configured binding ID.
    var found_label = noone; // The sole matching GUI label, when configured correctly.
    var available_ids = ""; // Binding IDs available to diagnose room wiring.

    for (var label_index = 0; label_index < instance_number(gmcu_o_label_gui); label_index++) {
        var candidate = instance_find(gmcu_o_label_gui, label_index); // Placed label being inspected.
        available_ids += "[" + string(candidate.binding_id) + "]";
        if (candidate.binding_id == status_label_id) {
            matches++;
            found_label = candidate;
        }
    }

    if (matches != 1) {
        gmcu_log_error(diagnostic_id + ": status_label_id=" + status_label_id + " must match exactly one gmcu_o_label_gui; found " + string(matches) + " among " + string(instance_number(gmcu_o_label_gui)) + " labels " + available_ids);
        instance_destroy();
        exit;
    }

    status_label = found_label;
    status_label_color = found_label.color;
}

if (instance_exists(status_label)) {
    var invalid = touched && !editing && !state.valid(); // Closed field has empty required positions.
    status_label.actual_text = invalid ? string(text_length) + " characters required" : feedback;
    status_label.color = invalid ? c_red : status_label_color;
}
