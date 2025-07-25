#include "surfacer/surfacer_module.h"

#include "snore_core/internal/registration_utils.h"
#include "snore_core/snore_core_module_utils.h"
#include "surfacer/annotations/jump_annotation.h"
#include "surfacer/annotations/path_annotation.h"
#include "surfacer/annotations/position_along_surface_annotation.h"
#include "surfacer/annotations/surface_annotation.h"
#include "surfacer/annotations/surfacer_agent_annotation.h"
#include "surfacer/movement_settings.h"
#include "surfacer/surface/agent_surface_state.h"
#include "surfacer/surface/collision_surface_result.h"
#include "surfacer/surface/position_along_surface.h"
#include "surfacer/surface/surface.h"
#include "surfacer/surface/surface_chunk.h"
#include "surfacer/surface/surface_properties.h"
#include "surfacer/surface/surface_store.h"
#include "surfacer/surface/tile_shape_data.h"
#include "surfacer/surface_graph.h"
#include "surfacer/surface_parser_settings.h"
#include "surfacer/surfacer_agent.h"
#include "surfacer/surfacer_geometry.h"
#include "surfacer/surfacer_settings.h"
#include "surfacer/tile_map_surface_parser.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

#ifdef SC_TESTS_ENABLED
#include "surfacer/annotations/test_jump_annotation.h"
#include "surfacer/annotations/test_path_annotation.h"
#include "surfacer/annotations/test_position_along_surface_annotation.h"
#include "surfacer/annotations/test_surface_annotation.h"
#include "surfacer/annotations/test_surfacer_agent_annotation.h"
#include "surfacer/surface/test_agent_surface_state.h"
#include "surfacer/surface/test_collision_surface_result.h"
#include "surfacer/surface/test_position_along_surface.h"
#include "surfacer/surface/test_surface.h"
#include "surfacer/surface/test_surface_chunk.h"
#include "surfacer/surface/test_surface_properties.h"
#include "surfacer/surface/test_surface_store.h"
#include "surfacer/test_movement_profile.h"
#include "surfacer/test_movement_settings.h"
#include "surfacer/test_surface_graph.h"
#include "surfacer/test_surface_parser_settings.h"
#include "surfacer/test_surfacer_agent.h"
#include "surfacer/test_surfacer_geometry.h"
#include "surfacer/test_surfacer_module.h"
#include "surfacer/test_surfacer_settings.h"
#include "surfacer/test_tile_map_surface_parser.h"
#endif // SC_TESTS_ENABLED

using namespace godot;

bool Surfacer::are_types_registered = false;

void Surfacer::register_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	// This method is idempotent, so we check here whether it has been called
	// already.
	if (are_types_registered) {
		return;
	}
	are_types_registered = true;

	GDREGISTER_CLASS(MovementProfile);
	GDREGISTER_CLASS(SurfaceGraph);
	GDREGISTER_CLASS(Surfacer);
	GDREGISTER_CLASS(SurfacerAgent);
	GDREGISTER_CLASS(SurfacerGeometry);
	GDREGISTER_CLASS(SurfacerSettings);
	GDREGISTER_CLASS(MovementSettings);
	GDREGISTER_CLASS(SurfaceParserSettings);

	GDREGISTER_CLASS(JumpAnnotation);
	GDREGISTER_CLASS(PathAnnotation);
	GDREGISTER_CLASS(PositionAlongSurfaceAnnotation);
	GDREGISTER_CLASS(SurfaceAnnotation);
	GDREGISTER_CLASS(SurfacerAgentAnnotation);

	GDREGISTER_CLASS(AgentSurfaceState);
	GDREGISTER_CLASS(CollisionSurfaceResult);
	GDREGISTER_CLASS(PositionAlongSurface);
	GDREGISTER_CLASS(Surface);
	GDREGISTER_CLASS(SurfaceChunk);
	GDREGISTER_CLASS(SurfaceProperties);
	GDREGISTER_CLASS(SurfaceStore);
	GDREGISTER_CLASS(TileMapSurfaceParser);

	REGISTER_SNORE_CORE_MODULE(Surfacer);
}

void Surfacer::unregister_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	UNREGISTER_SNORE_CORE_MODULE(Surfacer);
}

void Surfacer::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_settings"), &Surfacer::get_surfacer_settings);
}

Surfacer *Surfacer::get() {
	Surfacer *surfacer = get_maybe();
	if (!ENSURE(surfacer, "Surfacer is not initialized.")) {
		return nullptr;
	}
	return surfacer;
}

Surfacer *Surfacer::get_maybe() {
	Engine *engine = Engine::get_singleton();
	return engine->has_singleton(Surfacer::name)
			? static_cast<Surfacer *>(engine->get_singleton(name))
			: nullptr;
}

void Surfacer::set_up() {
	// TODO: Do any initialization that depends on runtime settings settings.
	on_set_up_finished();
}

void Surfacer::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}
