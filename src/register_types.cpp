#include "register_types.h"

#include "annotations/annotation.h"
#include "annotations/annotations_manager.h"
#include "annotations/jump_annotation.h"
#include "annotations/path_annotation.h"
#include "annotations/position_along_surface_annotation.h"
#include "annotations/surface_annotation.h"
#include "annotations/surfacer_agent_annotation.h"
#include "gdexample.h"
#include "movement_profile.h"
#include "scaffolder/geometry.h"
#include "scaffolder/rotated_shape.h"
#include "scaffolder/test_geometry.h"
#include "scaffolder/test_rotated_shape.h"
#include "scaffolder/test_runner.h"
#include "surface/agent_surface_state.h"
#include "surface/position_along_surface.h"
#include "surface/surface.h"
#include "surface/surface_chunk.h"
#include "surface/surface_properties.h"
#include "surface/surface_store.h"
#include "surface/surfacer_geometry.h"
#include "surface/test_agent_surface_state.h"
#include "surface/test_position_along_surface.h"
#include "surface/test_surface.h"
#include "surface/test_surface_store.h"
#include "surface/test_surfacer_geometry.h"
#include "surface_graph.h"
#include "surfacer.h"
#include "surfacer_agent.h"
#include "test_movement_profile.h"
#include "test_surface_graph.h"
#include "test_surfacer_agent.h"
#include "test_tile_map_surface_parser.h"
#include "tile_map_surface_parser.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	// FIXME: LEFT OFF HERE: Use REGISTER_SCAFFOLDER_CLASS for everything.

	REGISTER_SCAFFOLDER_CLASS(AgentSurfaceState);
	REGISTER_SCAFFOLDER_CLASS(Geometry);
	REGISTER_SCAFFOLDER_CLASS(MovementProfile);
	REGISTER_SCAFFOLDER_CLASS(PositionAlongSurface);
	REGISTER_SCAFFOLDER_CLASS(RotatedShape);
	REGISTER_SCAFFOLDER_CLASS(Surface);
	REGISTER_SCAFFOLDER_CLASS(SurfaceGraph);
	REGISTER_SCAFFOLDER_CLASS(SurfacerAgent);
	REGISTER_SCAFFOLDER_CLASS(SurfacerGeometry);
	REGISTER_SCAFFOLDER_CLASS(SurfaceStore);
	REGISTER_SCAFFOLDER_CLASS(TileMapSurfaceParser);

	GDREGISTER_CLASS(AgentSurfaceState);
	GDREGISTER_VIRTUAL_CLASS(Annotation);
	GDREGISTER_CLASS(AnnotationsManager);
	GDREGISTER_CLASS(GDExample);
	GDREGISTER_CLASS(Geometry);
	GDREGISTER_CLASS(JumpAnnotation);
	GDREGISTER_CLASS(MovementProfile);
	GDREGISTER_CLASS(PathAnnotation);
	GDREGISTER_CLASS(PositionAlongSurface);
	GDREGISTER_CLASS(PositionAlongSurfaceAnnotation);
	GDREGISTER_CLASS(Surface);
	GDREGISTER_CLASS(SurfaceAnnotation);
	GDREGISTER_CLASS(SurfaceChunk);
	GDREGISTER_CLASS(SurfaceGraph);
	GDREGISTER_CLASS(SurfaceProperties);
	GDREGISTER_CLASS(Surfacer);
	GDREGISTER_CLASS(SurfacerAgent);
	GDREGISTER_CLASS(SurfacerAgentAnnotation);
	GDREGISTER_CLASS(SurfaceStore);
	GDREGISTER_CLASS(TileMapSurfaceParser);
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
/**
 * This is the entry point of the GDExtension and will be called on
 * initialization. This function's name must be specified as the 'entry_symbol'
 * in the .gdextension file.
 */
GDExtensionBool GDE_EXPORT surfacer_extension_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(
			p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_gdextension_types);
	init_obj.register_terminator(uninitialize_gdextension_types);
	init_obj.set_minimum_library_initialization_level(
			MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}