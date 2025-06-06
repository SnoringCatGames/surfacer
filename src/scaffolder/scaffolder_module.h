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

	virtual const StringName &get_name() const override {
		static const StringName string_name = StringName(name);
		return string_name;
	}

	virtual void set_up() override;
	virtual void reset() override;

protected:
	static void _bind_methods();

private:
	static bool are_types_registered;
};

} //namespace godot

#endif // SCAFFOLDER_MODULE_H
