#ifndef SURFACER_MODULE_H
#define SURFACER_MODULE_H

#include "snore_core/snore_core_module.h"
#include "surfacer/surfacer_settings.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class Surfacer : public SnoreCoreModule<SurfacerSettings> {
	GDCLASS(Surfacer, SnoreCoreModule)

public:
	static const constexpr char *name = "Surfacer";

	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static Surfacer *get();

	virtual const StringName &get_name() const override {
		static const StringName string_name = StringName(name);
		return string_name;
	}

	virtual const StringName &get_settings_class_name() const override {
		return SurfacerSettings::get_class_static();
	}

	virtual SurfacerSettings *cast_to_settings(
			Object *p_object) const override {
		return Object::cast_to<SurfacerSettings>(p_object);
	}

	virtual void set_settings(SurfacerSettings *p_settings) {
		settings = Ref<SurfacerSettings>(p_settings);
	}

	virtual void set_up() override;
	virtual void reset() override;

	// TODO: This probably shouldn't be needed, but the Binding logic complains
	//       about duplicates when binding to the generic parent version.
	Ref<SurfacerSettings> get_surfacer_settings() const { return settings; }

protected:
	static void _bind_methods();

private:
	static bool are_types_registered;
};

} //namespace godot

#endif // SURFACER_MODULE_H
