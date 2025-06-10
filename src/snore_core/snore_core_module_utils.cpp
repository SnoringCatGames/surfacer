#include "snore_core/snore_core_module_utils.h"

#include "snore_core/snore_core_main_module.h"

using namespace godot;

void SnoreCoreModuleUtils_Internal::RegisterSnoreCoreMainModuleIfNotPresent() {
	if (!Engine::get_singleton()->has_singleton(SnoreCore::name)) {
		REGISTER_ENGINE_SINGLETON(SnoreCore);
		SnoreCoreModuleUtils_Internal::
				RegisterSnoreCoreModuleToSnoreCoreMainModule(SnoreCore::name);
	}
}

// FIXME: This will never work, since SnoreCore is registered to itself.
void SnoreCoreModuleUtils_Internal::
		UnregisterSnoreCoreMainModuleIfNoModulesRemain() {
	SnoreCore *main = static_cast<SnoreCore *>(
			Engine::get_singleton()->get_singleton(SnoreCore::name));
	if (main && main->is_modules_empty()) {
		UNREGISTER_ENGINE_SINGLETON(SnoreCore);
	}
}

void SnoreCoreModuleUtils_Internal::
		RegisterSnoreCoreModuleToSnoreCoreMainModule(
				const StringName &p_module_name) {
	SnoreCore *main = static_cast<SnoreCore *>(
			Engine::get_singleton()->get_singleton(SnoreCore::name));
	Object *module = Engine::get_singleton()->get_singleton(p_module_name);
	if (ENSURE_SIMPLE(main && module)) {
		main->register_module(module);
	}
}

void SnoreCoreModuleUtils_Internal::
		UnregisterSnoreCoreModuleFromSnoreCoreMainModule(
				const StringName &p_module_name) {
	SnoreCore *main = static_cast<SnoreCore *>(
			Engine::get_singleton()->get_singleton(SnoreCore::name));
	Object *module = Engine::get_singleton()->get_singleton(p_module_name);
	if (main && module) {
		main->unregister_module(module);
	}
}
