/** Find the sole keyboard area with a given Room Editor ID.
 * @param {String} _area_id ID configured on the textbox and keyboard area.
 * @returns {Instance} The matching area, or noone if absent or duplicated.
 */
function gmcu_text_resolve_keyboard_area(_area_id) {
    var matching_area = noone; // First area with the requested ID.
    var keyboard_area_total = instance_number(gmcu_o_text_keyboard); // Areas placed in the room.

    for (var keyboard_index = 0; keyboard_index < keyboard_area_total; keyboard_index++) {
        var candidate_area = instance_find(gmcu_o_text_keyboard, keyboard_index); // Area at this index.
        if (candidate_area.area_id == _area_id) {
            if (matching_area != noone) {
                gmcu_log_error("gmcu_text_resolve_keyboard_area: duplicate keyboard area_id=" + string(_area_id));
                return noone;
            }

            matching_area = candidate_area;
        }
    }

    if (matching_area == noone) {
        gmcu_log_error("gmcu_text_resolve_keyboard_area: no keyboard area with area_id=" + string(_area_id));
    }

    return matching_area;
}
