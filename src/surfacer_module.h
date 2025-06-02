#ifndef SURFACER_MODULE_H
#define SURFACER_MODULE_H

#include "snore_core/snore_core_module.h"
#include "surfacer_manifest.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class Surfacer : public SnoreCoreModule<SurfacerManifest> {
	GDCLASS(Surfacer, SnoreCoreModule)

public:
	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static Surfacer *get();

	virtual void set_up() override;
	virtual void reset() override;

	virtual void set_up_from_binding(
			const TypedArray<SnoreCoreManifest> &p_manifests) override {
		SnoreCoreModule::set_up_from_binding(p_manifests);
	}

protected:
	static void _bind_methods();
};

} //namespace godot

#endif // SURFACER_MODULE_H
