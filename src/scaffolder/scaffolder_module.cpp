#include "scaffolder/scaffolder_module.h"

#include "annotations/annotation.h"
#include "annotations/annotations_manager.h"
#include "gdexample.h"
#include "scaffolder/canvas_layer_config.h"
#include "scaffolder/geometry.h"
#include "scaffolder/rotated_shape.h"
#include "scaffolder/scaffolder_manifest.h"
#include "scaffolder/test_canvas_layer_config.h"
#include "scaffolder/test_geometry.h"
#include "scaffolder/test_rotated_shape.h"
#include "scaffolder/test_scaffolder_manifest.h"
#include "scaffolder/test_scaffolder_module.h"
#include "snore_core/snore_core_module_utils.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Scaffolder::register_gdextension_types(ModuleInitializationLevel p_level) {
	GDREGISTER_VIRTUAL_CLASS(Annotation);

	REGISTER_SCAFFOLDER_CLASS(CanvasLayerConfig);
	REGISTER_SCAFFOLDER_CLASS(Geometry);
	REGISTER_SCAFFOLDER_CLASS(RotatedShape);
	REGISTER_SCAFFOLDER_CLASS(ScaffolderManifest);
	REGISTER_SCAFFOLDER_CLASS(Scaffolder);

	// FIXME: Use REGISTER_SCAFFOLDER_CLASS for everything.
	GDREGISTER_CLASS(AnnotationsManager);
	GDREGISTER_CLASS(GDExample);

	REGISTER_SNORE_CORE_MODULE(Scaffolder);
}

void Scaffolder::unregister_gdextension_types(
		ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	UNREGISTER_SNORE_CORE_MODULE(Scaffolder);
}

void Scaffolder::_bind_methods() { BIND_SNORE_CORE_MODULE_METHODS(Scaffolder); }

Scaffolder *Scaffolder::get() {
	return static_cast<Scaffolder *>(
			Engine::get_singleton()->get_singleton("Scaffolder"));
}

void Scaffolder::set_up() {
	// TODO: Do any initialization that depends on runtime manifest settings.
	on_set_up_finished();
}

void Scaffolder::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}
