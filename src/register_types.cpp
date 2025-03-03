#include "register_types.h"

#include "gdexample.h"
#include "movement_profile.h"
#include "surface_graph.h"
#include "surfacer_agent.h"
#include "tile_map_surface_parser.h"
#include "annotations/annotation.h"
#include "annotations/annotations_manager.h"
#include "annotations/jump_annotation.h"
#include "annotations/path_annotation.h"
#include "annotations/position_along_surface_annotation.h"
#include "annotations/surface_annotation.h"
#include "annotations/surfacer_agent_annotation.h"
#include "surface/agent_surface_state.h"
#include "surface/position_along_surface.h"
#include "surface/surface_store.h"
#include "surface/surface.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_gdextension_types(ModuleInitializationLevel p_level)
{
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_CLASS(GDExample);
	GDREGISTER_CLASS(MovementProfile);
	GDREGISTER_CLASS(SurfaceGraph);
	GDREGISTER_CLASS(SurfacerAgent);
	GDREGISTER_CLASS(TileMapSurfaceParser);
	GDREGISTER_VIRTUAL_CLASS(Annotation);
	GDREGISTER_CLASS(AnnotationsManager);
	GDREGISTER_CLASS(JumpAnnotation);
	GDREGISTER_CLASS(PathAnnotation);
	GDREGISTER_CLASS(PositionAlongSurfaceAnnotation);
	GDREGISTER_CLASS(SurfaceAnnotation);
	GDREGISTER_CLASS(SurfacerAgentAnnotation);
	GDREGISTER_CLASS(AgentSurfaceState);
	GDREGISTER_CLASS(PositionAlongSurface);
	GDREGISTER_CLASS(SurfaceStore);
	GDREGISTER_CLASS(Surface);
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C"
{
	/**
	 * This is the entry point of the GDExtension and will be called on initialization.
	 * This function's name must be specified as the 'entry_symbol' in the .gdextension file.
	 */
	GDExtensionBool GDE_EXPORT surfacer_extension_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}
}