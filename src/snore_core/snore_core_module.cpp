#include "snore_core/snore_core_module.h"

#include "snore_core/snore_core_main_module.h"

using namespace godot;

void SnoreCoreModuleInternal::notify_main_module_of_module_set_up_finished(
		const StringName &p_name) {
	// Skip this redirect on SnoreCore itself, so we don't infinitly recurse.
	if (p_name != StringName(SnoreCore::name)) {
		SnoreCore *Main = SnoreCore::get();
		CHECK_SIMPLE(Main);
		Main->on_module_set_up_finished(p_name);
	}
}