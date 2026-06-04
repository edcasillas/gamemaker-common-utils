function gmcu_layered_gui_unsubscribe() {
	if(instance_exists(gmcu_o_layered_gui_manager)) {
		gmcu_o_layered_gui_manager.unsubscribe(self);
	}
}
