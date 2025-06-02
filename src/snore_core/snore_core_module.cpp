#include "snore_core/snore_core_module.h"

#include "snore_core/snore_core_main_module.h"

using namespace godot;

void SnoreCoreModuleInternal::set_up_main_module(
		const TypedArray<SnoreCoreManifest> &p_manifests) {
	SnoreCore *Main = SnoreCore::get();
	CHECK_SIMPLE(Main);
	Main->register_all_manifests(p_manifests);
	Main->set_up_base(p_manifests);
}

void SnoreCoreModuleInternal::notify_main_module_of_module_set_up_finished(
		Object *p_module) {
	SnoreCore *Main = SnoreCore::get();
	CHECK_SIMPLE(Main);
	if (Main != p_module) {
		Main->on_module_set_up_finished();
	}
}