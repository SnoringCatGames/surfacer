#include "surfacer_module.h"

#include "annotations/jump_annotation.h"
#include "annotations/path_annotation.h"
#include "annotations/position_along_surface_annotation.h"
#include "annotations/surface_annotation.h"
#include "annotations/surfacer_agent_annotation.h"
#include "movement_manifest.h"
#include "snore_core/snore_core_module_utils.h"
#include "surface/agent_surface_state.h"
#include "surface/collision_surface_result.h"
#include "surface/position_along_surface.h"
#include "surface/surface.h"
#include "surface/surface_chunk.h"
#include "surface/surface_properties.h"
#include "surface/surface_store.h"
#include "surface/surfacer_geometry.h"
#include "surface/test_agent_surface_state.h"
#include "surface/test_collision_surface_result.h"
#include "surface/test_position_along_surface.h"
#include "surface/test_surface.h"
#include "surface/test_surface_chunk.h"
#include "surface/test_surface_properties.h"
#include "surface/test_surface_store.h"
#include "surface/test_surfacer_geometry.h"
#include "surface/tile_shape_data.h"
#include "surface_graph.h"
#include "surfacer_agent.h"
#include "surfacer_manifest.h"
#include "test_movement_manifest.h"
#include "test_movement_profile.h"
#include "test_surface_graph.h"
#include "test_surfacer_agent.h"
#include "test_surfacer_manifest.h"
#include "test_surfacer_module.h"
#include "test_tile_map_surface_parser.h"
#include "tile_map_surface_parser.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Surfacer::register_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	REGISTER_SCAFFOLDER_CLASS(AgentSurfaceState);
	REGISTER_SCAFFOLDER_CLASS(CollisionSurfaceResult);
	REGISTER_SCAFFOLDER_CLASS(MovementProfile);
	REGISTER_SCAFFOLDER_CLASS(PositionAlongSurface);
	REGISTER_SCAFFOLDER_CLASS(Surface);
	REGISTER_SCAFFOLDER_CLASS(SurfaceChunk);
	REGISTER_SCAFFOLDER_CLASS(SurfaceGraph);
	REGISTER_SCAFFOLDER_CLASS(SurfaceProperties);
	REGISTER_SCAFFOLDER_CLASS(SurfacerAgent);
	REGISTER_SCAFFOLDER_CLASS(SurfacerGeometry);
	REGISTER_SCAFFOLDER_CLASS(SurfacerManifest);
	REGISTER_SCAFFOLDER_CLASS(Surfacer);
	REGISTER_SCAFFOLDER_CLASS(MovementManifest);
	REGISTER_SCAFFOLDER_CLASS(SurfaceStore);
	REGISTER_SCAFFOLDER_CLASS(TileMapSurfaceParser);

	// FIXME: Use REGISTER_SCAFFOLDER_CLASS for everything.

	GDREGISTER_CLASS(JumpAnnotation);
	GDREGISTER_CLASS(PathAnnotation);
	GDREGISTER_CLASS(PositionAlongSurfaceAnnotation);
	GDREGISTER_CLASS(SurfaceAnnotation);
	GDREGISTER_CLASS(SurfacerAgentAnnotation);

	REGISTER_SNORE_CORE_MODULE(Surfacer);
}

void Surfacer::unregister_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	UNREGISTER_SNORE_CORE_MODULE(Surfacer);
}

void Surfacer::_bind_methods() { BIND_SNORE_CORE_MODULE_METHODS(Surfacer); }

Surfacer *Surfacer::get() {
	return static_cast<Surfacer *>(
			Engine::get_singleton()->get_singleton("Surfacer"));
}

void Surfacer::set_up() {
	// TODO: Do any initialization that depends on runtime manifest settings.
	on_set_up_finished();
}

void Surfacer::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}
