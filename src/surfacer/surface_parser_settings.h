#ifndef SURFACE_PARSER_SETTINGS_H
#define SURFACE_PARSER_SETTINGS_H

#include "snore_core/snore_core_settings.h"

#include <godot_cpp/core/binder_common.hpp>

namespace godot {

class GDE_EXPORT SurfaceParserSettings : public SnoreCoreSettings {
	GDCLASS(SurfaceParserSettings, SnoreCoreSettings)

public:
	static Ref<SurfaceParserSettings> get();

	SurfaceParserSettings() = default;
	~SurfaceParserSettings() = default;

	float get_surfaces_tile_maps_collision_layer() const {
		return surfaces_tile_maps_collision_layer;
	}
	void set_surfaces_tile_maps_collision_layer(float p_value) {
		surfaces_tile_maps_collision_layer = p_value;
	}

	float get_corner_target_less_preferred_surface_side_offset() const {
		return corner_target_less_preferred_surface_side_offset;
	}
	void set_corner_target_less_preferred_surface_side_offset(float p_value) {
		corner_target_less_preferred_surface_side_offset = p_value;
	}

	float get_corner_target_more_preferred_surface_side_offset() const {
		return corner_target_more_preferred_surface_side_offset;
	}
	void set_corner_target_more_preferred_surface_side_offset(float p_value) {
		corner_target_more_preferred_surface_side_offset = p_value;
	}

	float get_collision_between_cells_distance_threshold() const {
		return collision_between_cells_distance_threshold;
	}
	void set_collision_between_cells_distance_threshold(float p_value) {
		collision_between_cells_distance_threshold = p_value;
	}

protected:
	static void _bind_methods();

private:
	int surfaces_tile_maps_collision_layer = 1;

	float corner_target_less_preferred_surface_side_offset = 0.02f;
	float corner_target_more_preferred_surface_side_offset = 0.01f;

	// TODO: We might want to instead replace this with a ratio (like 1.1) of
	//       the KinematicBody2D.get_safe_margin value (defaults to 0.08, but we
	//       set it higher during graph calculations).
	float collision_between_cells_distance_threshold = 0.5f;
};

} // namespace godot

#endif // SURFACE_PARSER_SETTINGS_H