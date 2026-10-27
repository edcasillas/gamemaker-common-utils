hovered = false; // Whether Universal Cursor points at this key.
flash_until = 0; // Time until keyboard feedback ends.
pressed = false; // Whether an activation press is held.
held_due = 0; // Time when a held action repeats.
is_interactable = true; // Allows Universal Cursor to activate this key.
gmcu_universal_cursor_subscribe(action);
gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEFAULT, action);
/** Mark this key as focused. */
function on_hover_enter() { hovered=true; }

/** Stop repeating when the key loses focus. */
function on_hover_leave() {
    hovered = false;
    pressed = false;
}

/** Activate on press; only movement and deletion may repeat. */
function on_pressed() {
    pressed = true;
    held_due = current_time + 400;
    if (instance_exists(keyboard_area.target)) keyboard_area.target.edit_action(action);
}

/** End the held action. */
function on_released() { pressed=false; }

/** Render the same rectangle used by Universal Cursor hit testing. */
function on_draw_gui() {
    if (!instance_exists(keyboard_area)) return;
    if (keyboard_area.custom_draw != noone) {
        method_call(keyboard_area.custom_draw, [id]);
        return;
    }

    // Drawing parameters restored after rendering.
    var saved = new gmcu_DrawingParameters();
    if (font != noone && font_exists(font)) draw_set_font(font);
    draw_set_alpha(1); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    // Whether the key is hovered or flashing.
    var highlighted = hovered || current_time < flash_until;
    // Visible label for this key.
    var caption = action == "LEFT" ? "<" : (action == "RIGHT" ? ">" : action);
    if (action == "SPACE") caption = "|_______|";
    if (keyboard_area.skin == "retro") {
        draw_set_color(highlighted ? c_white : (action == "DONE" || action == "CANCEL" || action == "DEL" || action == "PASTE" || action == "LEFT" || action == "RIGHT" ? make_color_rgb(40,112,238) : make_color_rgb(44,255,92)));
        draw_text_transformed(x,y,caption,0.6,0.6,0);
    } else {
        draw_set_color(highlighted ? make_color_rgb(185,225,192) : make_color_rgb(37,53,73));
        draw_roundrect(x-hit_width/2,y-hit_height/2,x+hit_width/2,y+hit_height/2,false);
        draw_set_color(highlighted ? make_color_rgb(15,32,25) : c_white);
        draw_text(x,y,caption);
    }

    saved.apply();
}
