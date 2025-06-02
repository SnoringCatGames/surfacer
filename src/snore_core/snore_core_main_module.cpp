#include "snore_core/snore_core_main_module.h"

#include "gdexample.h"
#include "snore_core/annotation.h"
#include "snore_core/annotations_manager.h"
#include "snore_core/canvas_layer_config.h"
#include "snore_core/geometry.h"
#include "snore_core/internal_utils.h"
#include "snore_core/rotated_shape.h"
#include "snore_core/snore_core_main_manifest.h"
#include "snore_core/snore_core_manifest.h"
#include "snore_core/snore_core_module.h"
#include "snore_core/snore_core_module_utils.h"
#include "snore_core/test_annotation.h"
#include "snore_core/test_annotations_manager.h"
#include "snore_core/test_canvas_layer_config.h"
#include "snore_core/test_geometry.h"
#include "snore_core/test_rotated_shape.h"
#include "snore_core/test_runner.h"
#include "snore_core/test_snore_core_main_manifest.h"
#include "snore_core/test_snore_core_main_module.h"
#include "snore_core/test_snore_core_manifest.h"
#include "snore_core/test_snore_core_module.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/time.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SnoreCore::register_gdextension_types(ModuleInitializationLevel p_level) {
	REGISTER_SNORE_CORE_ABSTRACT_CLASS(SnoreCoreManifest);
	REGISTER_SNORE_CORE_ABSTRACT_CLASS(SnoreCoreModule);
	REGISTER_SNORE_CORE_VIRTUAL_CLASS(Annotation);

	REGISTER_SNORE_CORE_CLASS(AnnotationsManager);
	REGISTER_SNORE_CORE_CLASS(CanvasLayerConfig);
	REGISTER_SNORE_CORE_CLASS(Geometry);
	REGISTER_SNORE_CORE_CLASS(RotatedShape);
	REGISTER_SNORE_CORE_CLASS(SnoreCore);
	REGISTER_SNORE_CORE_CLASS(SnoreCoreMainManifest);

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
	BIND_SNORE_CORE_MODULE_METHODS(SnoreCore);
	ClassDB::bind_static_method(
			"SnoreCore", D_METHOD("run_tests"), &SnoreCore::run_tests);
}

SnoreCore *SnoreCore::get() {
	return static_cast<SnoreCore *>(
			Engine::get_singleton()->get_singleton("SnoreCore"));
}

// FIXME: LEFT OFF HERE: ---------------------------------------------------
//
// - Finish porting SurfaceStore.
//
// --- COMMIT AND STABILIZE CURRENT STATE. ---
//
// - Implement and pass-in manifests from GDScript.
// - Also implement and pass-in MovementProfile as a Resource.
//
// - Expand on SnoreCore.
//   - Only allow Surfacer to depend on SnoreCore.
//   - Create a second demo/ app.
//     - Have one demo use Surfacer and Scaffolder together.
//     - Have the other use Surfacer without Scaffolder.
//     - Have SnoreCore expose a super-manifest, and move all of its
//     properties into a sub-manifest.
//     - The super-manifest will then wrap each framework's sub-manifest.
//     - Have both demo apps include their own sub-manifest.
//
// - Make sure these are exposed as singletons to GDScript.
// - Make these not actually rely on static logic.
// - Possibly have SnoreCore expose a single static access point.
//
// - Make sure _bind_methods is always at the top of the cpp file.
//
// - Ask copilot to strip unused includes.
//
// - Go through and remove some includes from headers, in favor of
//   forward-declaring the relevant types?
//
// - Survey bound properties, and remove any that shouldn't be exposed to either
//   the properties panel or GDScript.
//
// - Move Scaffolder logic from GDScript to C++.

void SnoreCore::set_up() {
	// Check that we're only set_upping once at the start of the app.
	const Time *time = Time::get_singleton();
	const uint64_t current_time_msec = time->get_ticks_msec();
	ENSURE(current_time_msec > last_set_up_time_msec + 500,
		   "Set_up should only be called once at the start of the app.");
	last_set_up_time_msec = current_time_msec;

	for (SnoreCoreModule *module : modules) {
		module->set_up_base(manifests);
	}
}

void SnoreCore::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}

void SnoreCore::on_module_set_up_finished() {
	if (!ENSURE(set_up_phase == SET_UP_PHASE::IN_PROGRESS,
				"Cannot finish set_up when it is not in progress.")) {
		return;
	}
	for (SnoreCoreModule *module : modules) {
		if (module->get_is_set_up_finished()) {
			return;
		}
	}
	on_set_up_finished();
}

void SnoreCore::register_module(Object *p_module) {
	SnoreCoreModule *module = static_cast<SnoreCoreModule *>(p_module);
	CHECK(module, "Cannot register a null module.");
	modules.push_back(module);
}

void SnoreCore::unregister_module(Object *p_module) {
	SnoreCoreModule *module = static_cast<SnoreCoreModule *>(p_module);
	ENSURE(module, "Cannot unregister a null module.");
	// Use std::remove to shift other modules to the beginning, then erase
	// the remaining elements at the end.
	modules.erase(
			std::remove(modules.begin(), modules.end(), module), modules.end());
}

void SnoreCore::run_tests() {
	// TODO: Swap these.
	// run_tests();
	run_tests_verbose();
}
