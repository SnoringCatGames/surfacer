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
#include "surfacer/movement_settings.h"
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
#include "surfacer/surface_parser_settings.h"
#include "surfacer/surfacer_agent.h"
#include "surfacer/surfacer_geometry.h"
#include "surfacer/surfacer_settings.h"
#include "surfacer/test_movement_profile.h"
#include "surfacer/test_movement_settings.h"
#include "surfacer/test_surface_graph.h"
#include "surfacer/test_surface_parser_settings.h"
#include "surfacer/test_surfacer_agent.h"
#include "surfacer/test_surfacer_geometry.h"
#include "surfacer/test_surfacer_module.h"
#include "surfacer/test_surfacer_settings.h"
#include "surfacer/test_tile_map_surface_parser.h"
#include "surfacer/tile_map_surface_parser.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>

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

	REGISTER_SNORE_CORE_CLASS(MovementProfile);
	REGISTER_SNORE_CORE_CLASS(SurfaceGraph);
	REGISTER_SNORE_CORE_CLASS(Surfacer);
	REGISTER_SNORE_CORE_CLASS(SurfacerAgent);
	REGISTER_SNORE_CORE_CLASS(SurfacerGeometry);
	REGISTER_SNORE_CORE_CLASS(SurfacerSettings);
	REGISTER_SNORE_CORE_CLASS(MovementSettings);
	REGISTER_SNORE_CORE_CLASS(SurfaceParserSettings);

	REGISTER_SNORE_CORE_CLASS(JumpAnnotation);
	REGISTER_SNORE_CORE_CLASS(PathAnnotation);
	REGISTER_SNORE_CORE_CLASS(PositionAlongSurfaceAnnotation);
	REGISTER_SNORE_CORE_CLASS(SurfaceAnnotation);
	REGISTER_SNORE_CORE_CLASS(SurfacerAgentAnnotation);

	REGISTER_SNORE_CORE_CLASS(AgentSurfaceState);
	REGISTER_SNORE_CORE_CLASS(CollisionSurfaceResult);
	REGISTER_SNORE_CORE_CLASS(PositionAlongSurface);
	REGISTER_SNORE_CORE_CLASS(Surface);
	REGISTER_SNORE_CORE_CLASS(SurfaceChunk);
	REGISTER_SNORE_CORE_CLASS(SurfaceProperties);
	REGISTER_SNORE_CORE_CLASS(SurfaceStore);
	REGISTER_SNORE_CORE_CLASS(TileMapSurfaceParser);

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
	return static_cast<Surfacer *>(
			Engine::get_singleton()->get_singleton(name));
}

void Surfacer::set_up() {
	// TODO: Do any initialization that depends on runtime settings settings.
	on_set_up_finished();
}

void Surfacer::reset() {
	// TODO: Clear state.
	// TODO: Cancel any in-progress set_up operations.
}
