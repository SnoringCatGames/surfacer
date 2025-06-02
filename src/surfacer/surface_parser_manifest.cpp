#include "surfacer/surface_parser_manifest.h"

#include "snore_core/internal_utils.h"
#include "surfacer/surfacer_manifest.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

Ref<SurfaceParserManifest> SurfaceParserManifest::get() {
	Ref<SurfacerManifest> surfacer_manifest = SurfacerManifest::get();
	return surfacer_manifest.is_valid()
			? surfacer_manifest->get_surface_parser_manifest()
			: Ref<SurfaceParserManifest>();
}

void SurfaceParserManifest::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_surfaces_tile_maps_collision_layer"),
			&SurfaceParserManifest::get_surfaces_tile_maps_collision_layer);
	ClassDB::bind_method(
			D_METHOD("set_surfaces_tile_maps_collision_layer", "p_value"),
			&SurfaceParserManifest::set_surfaces_tile_maps_collision_layer);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "surfaces_tile_maps_collision_layer"),
			"set_surfaces_tile_maps_collision_layer",
			"get_surfaces_tile_maps_collision_layer");

	ClassDB::bind_method(
			D_METHOD("get_corner_target_less_preferred_surface_side_offset"),
			&SurfaceParserManifest::
					get_corner_target_less_preferred_surface_side_offset);
	ClassDB::bind_method(
			D_METHOD(
					"set_corner_target_less_preferred_surface_side_offset",
					"p_value"),
			&SurfaceParserManifest::
					set_corner_target_less_preferred_surface_side_offset);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"corner_target_less_preferred_surface_side_offset"),
			"set_corner_target_less_preferred_surface_side_offset",
			"get_corner_target_less_preferred_surface_side_offset");

	ClassDB::bind_method(
			D_METHOD("get_corner_target_more_preferred_surface_side_offset"),
			&SurfaceParserManifest::
					get_corner_target_more_preferred_surface_side_offset);
	ClassDB::bind_method(
			D_METHOD(
					"set_corner_target_more_preferred_surface_side_offset",
					"p_value"),
			&SurfaceParserManifest::
					set_corner_target_more_preferred_surface_side_offset);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"corner_target_more_preferred_surface_side_offset"),
			"set_corner_target_more_preferred_surface_side_offset",
			"get_corner_target_more_preferred_surface_side_offset");

	ClassDB::bind_method(
			D_METHOD("get_collision_between_cells_distance_threshold"),
			&SurfaceParserManifest::
					get_collision_between_cells_distance_threshold);
	ClassDB::bind_method(
			D_METHOD(
					"set_collision_between_cells_distance_threshold",
					"p_value"),
			&SurfaceParserManifest::
					set_collision_between_cells_distance_threshold);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"collision_between_cells_distance_threshold"),
			"set_collision_between_cells_distance_threshold",
			"get_collision_between_cells_distance_threshold");
}
