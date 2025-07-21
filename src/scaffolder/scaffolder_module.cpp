#include "scaffolder/scaffolder_module.h"

#include "scaffolder/scaffolder_settings.h"
#include "snore_core/internal/registration_utils.h"
#include "snore_core/snore_core_module_utils.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

#ifdef SC_TESTS_ENABLED
#include "scaffolder/test_scaffolder_module.h"
#include "scaffolder/test_scaffolder_settings.h"
#endif // SC_TESTS_ENABLED

using namespace godot;

bool Scaffolder::are_types_registered = false;

void Scaffolder::register_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	// This method is idempotent, so we check here whether it has been called
	// already.
	if (are_types_registered) {
		return;
	}
	are_types_registered = true;

	GDREGISTER_CLASS(Scaffolder);
	GDREGISTER_CLASS(ScaffolderSettings);

	REGISTER_SNORE_CORE_MODULE(Scaffolder);
}

void Scaffolder::unregister_gdextension_types(
		ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	UNREGISTER_SNORE_CORE_MODULE(Scaffolder);
}

void Scaffolder::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_settings"), &Scaffolder::get_scaffolder_settings);
}

Scaffolder *Scaffolder::get() {
	Scaffolder *scaffolder = get_maybe();
	if (!ENSURE(scaffolder, "Scaffolder is not initialized.")) {
		return nullptr;
	}
	return scaffolder;
}

Scaffolder *Scaffolder::get_maybe() {
	Engine *engine = Engine::get_singleton();
	return engine->has_singleton(Scaffolder::name)
			? static_cast<Scaffolder *>(engine->get_singleton(name))
			: nullptr;
}

void Scaffolder::set_up() {
	// TODO: Do any initialization that depends on runtime settings settings.
	on_set_up_finished();
}

void Scaffolder::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}
