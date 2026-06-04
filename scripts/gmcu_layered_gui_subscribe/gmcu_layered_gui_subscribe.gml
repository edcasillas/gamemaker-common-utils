/**
Subscribe an object to be drawn by the Layered GUI Manager.
@param {real} _priority Priority/layer to which the subscribed instance will be drawn.
*/
function gmcu_layered_gui_subscribe(_priority) {
	if(!instance_exists(gmcu_o_layered_gui_manager)) {
		instance_create_depth(0, 0, 0, gmcu_o_layered_gui_manager);
	}
	gmcu_o_layered_gui_manager.subscribe(self, _priority);
}
