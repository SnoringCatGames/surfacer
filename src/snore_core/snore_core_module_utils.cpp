#include "snore_core/snore_core_module_utils.h"

#include "snore_core/snore_core_main_module.h"

using namespace godot;

void snore_core_module_utils_internal::
		register_snore_core_main_module_if_not_present() {
	if (!Engine::get_singleton()->has_singleton(SnoreCore::name)) {
		REGISTER_ENGINE_SINGLETON(SnoreCore);
		snore_core_module_utils_internal::
				register_snore_core_module_to_snore_core_main_module(
						SnoreCore::name);
	}
}

void snore_core_module_utils_internal::
		register_snore_core_module_to_snore_core_main_module(
				const StringName &p_module_name) {
	Engine *engine = Engine::get_singleton();
	if (!ENSURE(engine->has_singleton(SnoreCore::name),
				"SnoreCore is not initialized.")) {
		return;
	}
	if (!ENSURE(engine->has_singleton(p_module_name),
				godot::vformat("%s is not initialized.", p_module_name))) {
		return;
	}

	SnoreCore *main = SnoreCore::get();
	Object *module = engine->get_singleton(p_module_name);
	main->register_module(module);
}

void snore_core_module_utils_internal::
		unregister_snore_core_module_from_snore_core_main_module(
				const StringName &p_module_name) {
	Engine *engine = Engine::get_singleton();
	if (!engine->has_singleton(SnoreCore::name)) {
		// SnoreCore is already unregistered.
		return;
	}
	if (!engine->has_singleton(p_module_name)) {
		// Module is already unregistered.
		return;
	}

	SnoreCore *main = SnoreCore::get();
	Object *module = engine->get_singleton(p_module_name);
	main->unregister_module(module);
}

void godot::unregister_engine_singleton(const StringName &p_class_name) {
	Engine *engine = Engine::get_singleton();
	if (!engine->has_singleton(p_class_name)) {
		// Module is already unregistered.
		return;
	}
	Object *singleton = engine->get_singleton(p_class_name);
	if (singleton) {
		engine->unregister_singleton(p_class_name);
		memdelete(singleton);
	}
}
