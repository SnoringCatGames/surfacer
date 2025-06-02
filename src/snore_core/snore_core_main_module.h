#ifndef SNORE_CORE_MAIN_MODULE_H
#define SNORE_CORE_MAIN_MODULE_H

#include "snore_core/internal_utils.h"
#include "snore_core/snore_core_main_settings.h"
#include "snore_core/snore_core_module.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class SnoreCore : public SnoreCoreModule<SnoreCoreMainSettings> {
	GDCLASS(SnoreCore, SnoreCoreModule)

public:
	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static void run_tests();

	static SnoreCore *get();

	SnoreCore() = default;
	~SnoreCore() = default;

	virtual void set_up() override;
	virtual void reset() override;

	virtual void set_up_from_binding(
			const TypedArray<SnoreCoreSettings> &p_settings) override {
		SnoreCoreModule::set_up_from_binding(p_settings);
	}

	void on_module_set_up_finished();

	void register_all_settings(
			const TypedArray<SnoreCoreSettings> &p_settings) {
		settings = p_settings;
	}

	void register_module(Object *p_module);
	void unregister_module(Object *p_module);

	bool is_modules_empty() const { return modules.empty(); }

protected:
	static void _bind_methods();

private:
	std::vector<SnoreCoreModule *> modules;
	TypedArray<SnoreCoreSettings> settings;

	uint64_t last_set_up_time_msec = 0;
};

} //namespace godot

#endif // SNORE_CORE_MAIN_MODULE_H
