/// @description self-draw IF LayeredGUI does not exist.

// TODO Do we really want this? Or should we just force LayeredGUI as a dependency?

if(instance_exists(gmcu_o_layered_gui_manager)) return;
on_draw_gui();
