#ifndef SURFACER_MODULE_H
#define SURFACER_MODULE_H

#include "snore_core/snore_core_root_module.h"
#include "surfacer/surfacer_settings.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class Surfacer : public SnoreCoreRootModule<SurfacerSettings> {
	GDCLASS(Surfacer, SnoreCoreRootModule)
	SC_ROOT_MODULE_CLASS(Surfacer, SurfacerSettings)

public:
	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

protected:
	static void _bind_methods();

private:
	static bool are_types_registered;
};

} //namespace godot

#endif // SURFACER_MODULE_H
