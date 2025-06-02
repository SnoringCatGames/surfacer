#include "surfacer/surfacer_module.h"

#include "snore_core/snore_core_module_utils.h"
#include "surfacer/annotations/jump_annotation.h"
#include "surfacer/annotations/path_annotation.h"
#include "surfacer/annotations/position_along_surface_annotation.h"
#include "surfacer/annotations/surface_annotation.h"
#include "surfacer/annotations/surfacer_agent_annotation.h"
#include "surfacer/annotations/test_jump_annotation.h"
#include "surfacer/annotations/test_path_annotation.h"
#include "surfacer/annotations/test_position_along_surface_annotation.h"
#include "surfacer/annotations/test_surface_annotation.h"
#include "surfacer/annotations/test_surfacer_agent_annotation.h"
#include "surfacer/movement_manifest.h"
#include "surfacer/surface/agent_surface_state.h"
#include "surfacer/surface/collision_surface_result.h"
#include "surfacer/surface/position_along_surface.h"
#include "surfacer/surface/surface.h"
#include "surfacer/surface/surface_chunk.h"
#include "surfacer/surface/surface_properties.h"
#include "surfacer/surface/surface_store.h"
#include "surfacer/surface/test_agent_surface_state.h"
#include "surfacer/surface/test_collision_surface_result.h"
#include "surfacer/surface/test_position_along_surface.h"
#include "surfacer/surface/test_surface.h"
#include "surfacer/surface/test_surface_chunk.h"
#include "surfacer/surface/test_surface_properties.h"
#include "surfacer/surface/test_surface_store.h"
#include "surfacer/surface/tile_shape_data.h"
#include "surfacer/surface_graph.h"
#include "surfacer/surfacer_agent.h"
#include "surfacer/surfacer_geometry.h"
#include "surfacer/surfacer_manifest.h"
#include "surfacer/test_movement_manifest.h"
#include "surfacer/test_movement_profile.h"
#include "surfacer/test_surface_graph.h"
#include "surfacer/test_surfacer_agent.h"
#include "surfacer/test_surfacer_geometry.h"
#include "surfacer/test_surfacer_manifest.h"
#include "surfacer/test_surfacer_module.h"
#include "surfacer/test_tile_map_surface_parser.h"
#include "surfacer/tile_map_surface_parser.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Surfacer::register_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	REGISTER_SCAFFOLDER_CLASS(MovementProfile);
	REGISTER_SCAFFOLDER_CLASS(SurfaceGraph);
	REGISTER_SCAFFOLDER_CLASS(Surfacer);
	REGISTER_SCAFFOLDER_CLASS(SurfacerAgent);
	REGISTER_SCAFFOLDER_CLASS(SurfacerGeometry);
	REGISTER_SCAFFOLDER_CLASS(SurfacerManifest);
	REGISTER_SCAFFOLDER_CLASS(MovementManifest);

	REGISTER_SCAFFOLDER_CLASS(JumpAnnotation);
	REGISTER_SCAFFOLDER_CLASS(PathAnnotation);
	REGISTER_SCAFFOLDER_CLASS(PositionAlongSurfaceAnnotation);
	REGISTER_SCAFFOLDER_CLASS(SurfaceAnnotation);
	REGISTER_SCAFFOLDER_CLASS(SurfacerAgentAnnotation);

	REGISTER_SCAFFOLDER_CLASS(AgentSurfaceState);
	REGISTER_SCAFFOLDER_CLASS(CollisionSurfaceResult);
	REGISTER_SCAFFOLDER_CLASS(PositionAlongSurface);
	REGISTER_SCAFFOLDER_CLASS(Surface);
	REGISTER_SCAFFOLDER_CLASS(SurfaceChunk);
	REGISTER_SCAFFOLDER_CLASS(SurfaceProperties);
	REGISTER_SCAFFOLDER_CLASS(SurfaceStore);
	REGISTER_SCAFFOLDER_CLASS(TileMapSurfaceParser);

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
