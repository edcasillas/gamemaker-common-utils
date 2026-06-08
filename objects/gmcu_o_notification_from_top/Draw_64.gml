var _draw_params = new gmcu_DrawingParameters();

draw_set_alpha(alpha);
draw_set_color(back_color);
draw_rectangle(box_x, offset_y + box_y, box_x + box_w, get_bottom_pos(), false);

draw_set_alpha(1);
draw_set_color(outline_color);
draw_rectangle(box_x, offset_y + box_y, box_x + box_w, get_bottom_pos(), true);

draw_set_color(font_color);
if (font != noone) draw_set_font(font);
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
draw_text(box_x + (box_w / 2), box_y + (box_h / 2) + offset_y, text);

_draw_params.apply();

