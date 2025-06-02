#ifndef SCAFFOLDER_MODULE_H
#define SCAFFOLDER_MODULE_H

#include "scaffolder/scaffolder_settings.h"
#include "snore_core/snore_core_module.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class Scaffolder : public SnoreCoreModule<ScaffolderSettings> {
	GDCLASS(Scaffolder, SnoreCoreModule)

public:
	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static Scaffolder *get();

	virtual void set_up() override;
	virtual void reset() override;

	virtual void set_up_from_binding(
			const TypedArray<SnoreCoreSettings> &p_settings) override {
		SnoreCoreModule::set_up_from_binding(p_settings);
	}

protected:
	static void _bind_methods();
};

} //namespace godot

#endif // SCAFFOLDER_MODULE_H
