#include "register_gdextension_types.h"

#include "snore_core/snore_core_main_module.h"
#include "surfacer/surfacer_module.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_surfacer_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	// NOTE: Godot currently doesn't support dependencies between separate
	//       GDExtensions. If support is added later, each SnoreCore should
	//       register its own types, rather than Surfacer doing it here.
	//       See https://github.com/godot-rust/gdext/issues/615.
	SnoreCore::register_gdextension_types(p_level);
	Surfacer::register_gdextension_types(p_level);
}

void uninitialize_surfacer_gdextension_types(
		ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	// NOTE: Godot currently doesn't support dependencies between separate
	//       GDExtensions. If support is added later, each SnoreCore should
	//       unregister its own types, rather than Surfacer doing it here.
	//       See https://github.com/godot-rust/gdext/issues/615.
	SnoreCore::unregister_gdextension_types(p_level);
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
	init_obj.register_initializer(initialize_surfacer_gdextension_types);
	init_obj.register_terminator(uninitialize_surfacer_gdextension_types);
	init_obj.set_minimum_library_initialization_level(
			MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}