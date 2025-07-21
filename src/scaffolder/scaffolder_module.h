#ifndef SCAFFOLDER_MODULE_H
#define SCAFFOLDER_MODULE_H

#include "scaffolder/scaffolder_settings.h"
#include "snore_core/snore_core_module.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class Scaffolder : public SnoreCoreModule<ScaffolderSettings> {
	GDCLASS(Scaffolder, SnoreCoreModule)

public:
	static const constexpr char *name = "Scaffolder";

	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static Scaffolder *get();
	static Scaffolder *get_maybe();

	virtual const StringName &get_name() const override {
		static const StringName string_name = StringName(name);
		return string_name;
	}

	virtual const StringName &get_settings_class_name() const override {
		return ScaffolderSettings::get_class_static();
	}

	virtual ScaffolderSettings *cast_to_settings(
			Object *p_object) const override {
		return Object::cast_to<ScaffolderSettings>(p_object);
	}

	virtual void set_settings(ScaffolderSettings *p_settings) {
		settings = Ref<ScaffolderSettings>(p_settings);
	}

	virtual void set_up() override;
	virtual void reset() override;

	// TODO: This probably shouldn't be needed, but the Binding logic complains
	//       about duplicates when binding to the generic parent version.
	Ref<ScaffolderSettings> get_scaffolder_settings() const { return settings; }

protected:
	static void _bind_methods();

private:
	static bool are_types_registered;
};

} //namespace godot

#endif // SCAFFOLDER_MODULE_H
