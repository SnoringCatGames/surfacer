#ifndef SNORE_CORE_MAIN_MODULE_H
#define SNORE_CORE_MAIN_MODULE_H

#include "snore_core/internal/debug_utils.h"
#include "snore_core/snore_core_main_settings.h"
#include "snore_core/snore_core_module.h"

#include <godot_cpp/godot.hpp>

namespace godot {

class SnoreCore : public SnoreCoreModule<SnoreCoreMainSettings> {
	GDCLASS(SnoreCore, SnoreCoreModule)

public:
	static const constexpr char *name = "SnoreCore";

	static void register_gdextension_types(ModuleInitializationLevel p_level);
	static void unregister_gdextension_types(ModuleInitializationLevel p_level);

	static bool run_tests();

	static void set_up_from_binding(
			const TypedArray<SnoreCoreSettings> &p_all_settings);

	static SnoreCore *get();
	static SnoreCore *get_maybe();

	static SnoreCoreModule *get_module(const StringName &p_name) {
		SnoreCore *main = SnoreCore::get();
		if (!ENSURE(main, "SnoreCore is not initialized.")) {
			return nullptr;
		}
		if (!ENSURE(main->modules.find(p_name) != main->modules.end(),
					"Module not found: " + p_name)) {
			return nullptr;
		}
		return main->modules[p_name];
	}

	static TypedArray<SnoreCoreModule> get_modules() {
		SnoreCore *main = SnoreCore::get();
		if (!ENSURE(main, "SnoreCore is not initialized.")) {
			return TypedArray<SnoreCoreModule>();
		}

		TypedArray<SnoreCoreModule> result;
		result.resize(main->modules.size());

		for (const std::pair<const StringName, SnoreCoreModule *> &pair :
			 main->modules) {
			result.push_back(pair.second);
		}

		return result;
	}

	SnoreCore() = default;
	~SnoreCore() {
		// Clear the modules map to ensure proper cleanup.
		modules.clear();
	}

	virtual const StringName &get_name() const override {
		static const StringName string_name = StringName(name);
		return string_name;
	}

	virtual const StringName &get_settings_class_name() const override {
		return SnoreCoreMainSettings::get_class_static();
	}

	virtual SnoreCoreMainSettings *cast_to_settings(
			Object *p_object) const override {
		return Object::cast_to<SnoreCoreMainSettings>(p_object);
	}

	virtual void set_settings(SnoreCoreMainSettings *p_settings) override {
		settings = Ref<SnoreCoreMainSettings>(p_settings);
	}

	virtual void set_up() override;
	virtual void reset() override;

	void set_up_main(const TypedArray<SnoreCoreSettings> &p_all_settings);

	void on_module_set_up_finished(const StringName &p_name);

	void register_module(Object *p_module);
	void unregister_module(Object *p_module);

	bool is_modules_empty() const { return modules.empty(); }

	uint64_t get_last_set_up_time_msec() const { return last_set_up_time_msec; }
	void set_last_set_up_time_msec(uint64_t p_value) {
		last_set_up_time_msec = p_value;
	}

	// TODO: This probably shouldn't be needed, but the Binding logic complains
	//       about duplicates when binding to the generic parent version.
	Ref<SnoreCoreMainSettings> get_snore_core_settings() const {
		return settings;
	}

protected:
	static void _bind_methods();

private:
	static bool are_types_registered;

	std::unordered_map<StringName, SnoreCoreModule *> modules;

	uint64_t last_set_up_time_msec = 0;
};

} //namespace godot

#endif // SNORE_CORE_MAIN_MODULE_H
