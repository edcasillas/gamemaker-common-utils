hovered=false; pressed=false; held_due=0; is_interactable=true;
gmcu_universal_cursor_subscribe(action);
gmcu_layered_gui_subscribe(GMCU_GUI_PRIORITY_DEFAULT, action);
/** Mark this key as focused. */
function on_hover_enter() { hovered=true; }
/** Stop repeating when the key loses focus. */
function on_hover_leave() { hovered=false; pressed=false; }
/** Activate on press; only movement and deletion may repeat. */
function on_pressed() {
    pressed=true; held_due=current_time+400;
    if (instance_exists(keyboard_area.target)) keyboard_area.target.edit_action(action);
}
/** End the held action. */
function on_released() { pressed=false; }
/** Render the same rectangle used by Universal Cursor hit testing. */
function on_draw_gui() {
    var saved=new gmcu_DrawingParameters();
    if (font != noone && font_exists(font)) draw_set_font(font);
    draw_set_alpha(1); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(hovered ? make_color_rgb(185,225,192) : make_color_rgb(37,53,73));
    draw_rectangle(x-hit_width/2,y-hit_height/2,x+hit_width/2,y+hit_height/2,false);
    draw_set_color(hovered ? make_color_rgb(15,32,25) : c_white);
    var caption=action == "LEFT" ? "<" : (action == "RIGHT" ? ">" : action);
    if (action == "SPACE") caption="|_______|";
    draw_text(x,y,caption); saved.apply();
}
