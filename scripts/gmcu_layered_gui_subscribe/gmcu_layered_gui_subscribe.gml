/**
 * @description Subscribes the calling instance to the Layered GUI Manager.
 * @param {Real} _priority Priority at which the instance will be drawn.
 * @param {String|Undefined} _diagnostic_name Optional instance label for diagnostics.
 */
function gmcu_layered_gui_subscribe(_priority, _diagnostic_name = undefined) { // TODO Maybe priority should be optional with default = GMCU_GUI_PRIORITY_DEFAULT
	if(!instance_exists(gmcu_o_layered_gui_manager)) {
		instance_create_depth(0, 0, 0, gmcu_o_layered_gui_manager);
	}
	gmcu_o_layered_gui_manager.subscribe(self, _priority, _diagnostic_name);
}
