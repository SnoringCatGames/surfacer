#include "register_gdextension_types.h"

#include "scaffolder/scaffolder_module.h"
#include "snore_core/snore_core_main_module.h"
#include "surfacer/surfacer_module.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	SnoreCore::register_gdextension_types(p_level);
	Scaffolder::register_gdextension_types(p_level);
	Surfacer::register_gdextension_types(p_level);

	// FIXME: Remove?
	SnoreCore::run_tests();
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	SnoreCore::unregister_gdextension_types(p_level);
	Scaffolder::unregister_gdextension_types(p_level);
	Surfacer::unregister_gdextension_types(p_level);
}

extern "C" {
/**
 * This is the entry point of the GDExtension and will be called on
 * initialization. This function's name must be specified as the 'entry_symbol'
 * in the .gdextension file.
 */
GDExtensionBool GDE_EXPORT surfacer_extension_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(
			p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_gdextension_types);
	init_obj.register_terminator(uninitialize_gdextension_types);
	init_obj.set_minimum_library_initialization_level(
			MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}