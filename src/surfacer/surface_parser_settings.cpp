#include "surfacer/surface_parser_settings.h"

#include "snore_core/internal/debug_utils.h"
#include "surfacer/surfacer_settings.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

Ref<SurfaceParserSettings> SurfaceParserSettings::get() {
	Ref<SurfacerSettings> surfacer_settings = SurfacerSettings::get();
	if (!surfacer_settings.is_valid()) {
		return Ref<SurfaceParserSettings>();
	}
	Ref<SurfaceParserSettings> surface_parser_settings =
			surfacer_settings->get_surface_parser_settings();
	if (!ENSURE(surface_parser_settings.is_valid(),
				"SurfacerSettings has not been set-up with "
				"SurfaceParserSettings.")) {
		return Ref<SurfacerSettings>();
	}
	return surface_parser_settings;
}

void SurfaceParserSettings::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_surfaces_tile_maps_collision_layer"),
			&SurfaceParserSettings::get_surfaces_tile_maps_collision_layer);
	ClassDB::bind_method(
			D_METHOD("set_surfaces_tile_maps_collision_layer", "p_value"),
			&SurfaceParserSettings::set_surfaces_tile_maps_collision_layer);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "surfaces_tile_maps_collision_layer"),
			"set_surfaces_tile_maps_collision_layer",
			"get_surfaces_tile_maps_collision_layer");

	ClassDB::bind_method(
			D_METHOD("get_corner_target_less_preferred_surface_side_offset"),
			&SurfaceParserSettings::
					get_corner_target_less_preferred_surface_side_offset);
	ClassDB::bind_method(
			D_METHOD(
					"set_corner_target_less_preferred_surface_side_offset",
					"p_value"),
			&SurfaceParserSettings::
					set_corner_target_less_preferred_surface_side_offset);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"corner_target_less_preferred_surface_side_offset"),
			"set_corner_target_less_preferred_surface_side_offset",
			"get_corner_target_less_preferred_surface_side_offset");

	ClassDB::bind_method(
			D_METHOD("get_corner_target_more_preferred_surface_side_offset"),
			&SurfaceParserSettings::
					get_corner_target_more_preferred_surface_side_offset);
	ClassDB::bind_method(
			D_METHOD(
					"set_corner_target_more_preferred_surface_side_offset",
					"p_value"),
			&SurfaceParserSettings::
					set_corner_target_more_preferred_surface_side_offset);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"corner_target_more_preferred_surface_side_offset"),
			"set_corner_target_more_preferred_surface_side_offset",
			"get_corner_target_more_preferred_surface_side_offset");

	ClassDB::bind_method(
			D_METHOD("get_collision_between_cells_distance_threshold"),
			&SurfaceParserSettings::
					get_collision_between_cells_distance_threshold);
	ClassDB::bind_method(
			D_METHOD(
					"set_collision_between_cells_distance_threshold",
					"p_value"),
			&SurfaceParserSettings::
					set_collision_between_cells_distance_threshold);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::FLOAT,
					"collision_between_cells_distance_threshold"),
			"set_collision_between_cells_distance_threshold",
			"get_collision_between_cells_distance_threshold");
}