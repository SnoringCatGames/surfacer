#include "snore_core/snore_core_main_module.h"

#include "gdexample.h"
#include "snore_core/annotation.h"
#include "snore_core/annotations_manager.h"
#include "snore_core/canvas_layer_config.h"
#include "snore_core/geometry.h"
#include "snore_core/internal_utils.h"
#include "snore_core/rotated_shape.h"
#include "snore_core/snore_core_main_settings.h"
#include "snore_core/snore_core_module.h"
#include "snore_core/snore_core_module_utils.h"
#include "snore_core/snore_core_settings.h"
#include "snore_core/test_annotation.h"
#include "snore_core/test_annotations_manager.h"
#include "snore_core/test_canvas_layer_config.h"
#include "snore_core/test_geometry.h"
#include "snore_core/test_rotated_shape.h"
#include "snore_core/test_runner.h"
#include "snore_core/test_snore_core_main_module.h"
#include "snore_core/test_snore_core_main_settings.h"
#include "snore_core/test_snore_core_module.h"
#include "snore_core/test_snore_core_settings.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

bool SnoreCore::are_types_registered = false;

void SnoreCore::register_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	// This method is idempotent, so we check here whether it has been called
	// already.
	if (are_types_registered) {
		return;
	}
	are_types_registered = true;

	REGISTER_SNORE_CORE_ABSTRACT_CLASS(SnoreCoreSettings);
	REGISTER_SNORE_CORE_ABSTRACT_CLASS(SnoreCoreModule);
	REGISTER_SNORE_CORE_VIRTUAL_CLASS(Annotation);

	REGISTER_SNORE_CORE_CLASS(AnnotationsManager);
	REGISTER_SNORE_CORE_CLASS(CanvasLayerConfig);
	REGISTER_SNORE_CORE_CLASS(Geometry);
	REGISTER_SNORE_CORE_CLASS(RotatedShape);
	REGISTER_SNORE_CORE_CLASS(SnoreCore);
	REGISTER_SNORE_CORE_CLASS(SnoreCoreMainSettings);

	GDREGISTER_CLASS(GDExample);

	SnoreCoreModuleUtils_Internal::RegisterSnoreCoreMainModuleIfNotPresent();
}

void SnoreCore::unregister_gdextension_types(
		ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	SnoreCoreModuleUtils_Internal::
			UnregisterSnoreCoreMainModuleIfNoModulesRemain();
}

void SnoreCore::_bind_methods() {
	ClassDB::bind_static_method(
			name, D_METHOD("set_up", "p_settings"),
			&SnoreCore::set_up_from_binding);
	ClassDB::bind_static_method(
			name, D_METHOD("run_tests"), &SnoreCore::run_tests);
	ClassDB::bind_static_method(
			name, D_METHOD("get_module", "p_name"), &SnoreCore::get_module);
	ClassDB::bind_static_method(
			name, D_METHOD("get_modules"), &SnoreCore::get_modules);

	ADD_SIGNAL(MethodInfo(
			"module_set_up_finished",
			PropertyInfo(Variant::STRING_NAME, "name")));
	ADD_SIGNAL(MethodInfo("all_modules_set_up_finished"));
}

SnoreCore *SnoreCore::get() {
	return static_cast<SnoreCore *>(
			Engine::get_singleton()->get_singleton(name));
}

void SnoreCore::set_up_from_binding(
		const TypedArray<SnoreCoreSettings> &p_all_settings) {
	SnoreCore *Main = SnoreCore::get();
	CHECK_SIMPLE(Main);
	Main->set_up_main(p_all_settings);
}

void SnoreCore::set_up_main(
		const TypedArray<SnoreCoreSettings> &p_all_settings) {
	// Check that we're only setting up once at the start of the app.
	const Time *time = Time::get_singleton();
	const uint64_t current_time_msec = time->get_ticks_msec();
	ENSURE(current_time_msec > last_set_up_time_msec + 500,
		   "Set_up should only be called once at the start of the app.");
	last_set_up_time_msec = current_time_msec;

	for (const std::pair<const StringName, SnoreCoreModule *> &pair : modules) {
		SnoreCoreSettings *settings_ptr =
				pair.second->get_settings_from_list(p_all_settings);
		Ref<SnoreCoreSettings> settings = Ref<SnoreCoreSettings>(settings_ptr);
		pair.second->set_up_base(settings);
	}
}

void SnoreCore::set_up() {}

void SnoreCore::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}

void SnoreCore::on_module_set_up_finished(const StringName &p_name) {
	SnoreCoreModule *module = get_module(p_name);
	if (!ENSURE_SIMPLE(module)) {
		return;
	}

	if (!ENSURE(module->get_set_up_phase() == SET_UP_PHASE::IN_PROGRESS,
				"Cannot finish set_up when it is not in progress.")) {
		return;
	}

	if (p_name != StringName(SnoreCore::name)) {
		// For non-SnoreCore modules, emit the signal now, before a possible
		// early-out.
		emit_signal("module_set_up_finished", p_name);
	}

	for (const std::pair<const StringName, SnoreCoreModule *> &pair : modules) {
		if (!pair.second->get_is_set_up_finished() &&
			pair.first != StringName(SnoreCore::name)) {
			return;
		}
	}

	on_set_up_finished();

	// For the SnoreCore module, emit the signal now, after confirming that all
	// other modules are finished.
	emit_signal("module_set_up_finished", SnoreCore::name);

	emit_signal("all_modules_set_up_finished");
}

void SnoreCore::register_module(Object *p_module) {
	SnoreCoreModule *module = static_cast<SnoreCoreModule *>(p_module);
	CHECK(module, "Cannot register a null module.");
	modules[module->get_name()] = module;
}

void SnoreCore::unregister_module(Object *p_module) {
	SnoreCoreModule *module = static_cast<SnoreCoreModule *>(p_module);
	ENSURE(module, "Cannot unregister a null module.");
	modules.erase(module->get_name());
}

void SnoreCore::run_tests() {
	// TODO: Swap these.
	// run_tests();
	run_tests_verbose();
}
