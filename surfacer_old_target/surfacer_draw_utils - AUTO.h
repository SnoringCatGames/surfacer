#ifndef SURFACER_DRAW_UTILS_H
#define SURFACER_DRAW_UTILS_H

#include "surface/position_along_surface.h"
#include "surface/surface.h"

#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/core/math.hpp> // For Math_SQRT2, Math::fmod
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class SurfacerDrawUtils : public RefCounted {
	GDCLASS(SurfacerDrawUtils, RefCounted);

public:
	static constexpr double SQRT_TWO =
			Math_SQRT2; // From godot_cpp/core/math.hpp

protected:
	static void _bind_methods() {
	} // Static class, or bind if it's an instantiable utility object

public:
	SurfacerDrawUtils() {}
	~SurfacerDrawUtils() {}

	static void draw_surface(
			CanvasItem *p_canvas,
			Surface *p_surface,
			Color p_color,
			float p_depth = -1.0f); // Sentinel for default

	static void draw_surface_segment(
			CanvasItem *p_canvas,
			const Vector2 &p_segment_start,
			const Vector2 &p_segment_end,
			const Vector2 &p_preceding_point,
			const Vector2 &p_following_point,
			Surface *p_surface, // Unused in GDScript, but kept for
								// signature consistency
			Color p_color,
			float p_depth);

	static void draw_single_vertex_surface(
			CanvasItem *p_canvas,
			Surface *p_surface,
			Color p_color,
			float p_depth = -1.0f); // Sentinel for default

	static void draw_position_along_surface(
			CanvasItem *p_canvas,
			PositionAlongSurface *p_position,
			Color p_target_point_color,
			Color p_t_color,
			float p_target_point_radius = 4.0f,
			float p_t_length_in_surface = 8.0f,
			float p_t_length_out_of_surface = 8.0f,
			float p_t_width = 4.0f,
			bool p_t_value_drawn = true,
			bool p_target_point_drawn = false,
			bool p_surface_drawn = false);

	static void draw_origin_marker(
			CanvasItem *p_canvas,
			const Vector2 &p_target,
			Color p_color,
			float p_radius = -1.0f, // Sentinel
			float p_border_width = 1.0f,
			float p_sector_arc_length = 3.0f);

	static void draw_destination_marker(
			CanvasItem *p_canvas,
			PositionAlongSurface *p_destination,
			bool p_is_based_on_target_point,
			Color p_color,
			float p_cone_length = -1.0f, // Sentinel
			float p_circle_radius = -1.0f, // Sentinel
			bool p_is_filled = false,
			float p_border_width = -1.0f, // Sentinel
			float p_sector_arc_length = 4.0f);

	static void draw_instruction_indicator(
			CanvasItem *p_canvas,
			const String &p_input_key,
			bool p_is_pressed,
			const Vector2 &p_position,
			float p_length,
			Color p_color);

	static void draw_path(
			CanvasItem *p_canvas,
			PlatformGraphPath *p_path,
			float p_stroke_width = -1.0f, // Sentinel
			Color p_color =
					Color(1,
						  1,
						  1,
						  0), // Sentinel for default Color.white
			float p_trim_front_end_radius = 0.0f,
			float p_trim_back_end_radius = 0.0f,
			bool p_includes_waypoints = false,
			bool p_includes_instruction_indicators = false,
			bool p_includes_continuous_positions = false,
			bool p_includes_discrete_positions = false);

	static void draw_path_duration_segment(
			CanvasItem *p_canvas,
			PlatformGraphPath *p_path,
			float p_segment_time_start,
			float p_segment_time_end,
			float p_stroke_width = -1.0f, // Sentinel
			Color p_color =
					Color(1,
						  1,
						  1,
						  0), // Sentinel for default Color.white
			float p_trim_front_end_radius = 0.0f,
			float p_trim_back_end_radius = 0.0f);

	static void draw_beat_hashes(
			CanvasItem *p_canvas,
			const Array &p_beats, // Assuming Beat is a Ref<Beat> or
								  // similar stored in Array
			float p_downbeat_hash_length = -1.0f, // Sentinel
			float p_offbeat_hash_length = -1.0f, // Sentinel
			float p_downbeat_stroke_width = -1.0f, // Sentinel
			float p_offbeat_stroke_width = -1.0f, // Sentinel
			Color p_downbeat_color = Color(1, 1, 1, 0), // Sentinel
			Color p_offbeat_color = Color(1, 1, 1, 0)); // Sentinel

	static void draw_edge(
			CanvasItem *p_canvas,
			Edge *p_edge,
			float p_stroke_width = -1.0f, // Sentinel
			Color p_discrete_trajectory_color = Color(1, 1, 1, 0), // Sentinel
			bool p_includes_waypoints = false,
			bool p_includes_instruction_indicators = false,
			bool p_includes_continuous_positions = true,
			bool p_includes_discrete_positions = false);

	static void draw_tilemap_indices(
			CanvasItem *p_canvas,
			TileMap *p_tile_map,
			Color p_color,
			bool p_only_renders_used_indices = false);

	static void draw_tile_grid_positions(
			CanvasItem *p_canvas,
			TileMap *p_tile_map,
			Color p_color,
			bool p_only_renders_used_indices = false);

private:
	static PackedVector2Array _trim_front_end(
			PackedVector2Array p_vertices, // Pass by value to modify
			float p_trim_radius);

	static PackedVector2Array _trim_back_end(
			PackedVector2Array p_vertices, // Pass by value to modify
			float p_trim_radius);

	static PackedVector2Array _get_edge_trajectory_vertices(
			Edge *p_edge,
			bool p_includes_end_points = true,
			bool p_is_continuous = true,
			bool p_removes_too_close_vertices = false);

	static PackedVector2Array _remove_too_close_neighbors(
			const PackedVector2Array &p_vertices);
};

} // namespace godot

#endif // SURFACER_DRAW_UTILS_H
