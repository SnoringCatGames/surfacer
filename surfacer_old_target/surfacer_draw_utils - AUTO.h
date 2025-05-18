#ifndef SURFACER_DRAW_UTILS_H
#define SURFACER_DRAW_UTILS_H

#include "scaffolder_draw_utils.h // Assuming this is the C++ equivalent base class
#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/font.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/core/math.hpp> // For Math_SQRT2, Math::fmod
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

// Forward declarations for custom types (ensure these are defined and included
// where necessary)
namespace godot {
class Surface;
class PositionAlongSurface;
class PlatformGraphPath;
class Edge;
// Assuming Trajectory, Instruction, Beat are also defined C++ types
// class Trajectory;
// class Instruction;
// class Beat;
} //namespace godot

// Placeholder for global parameters and utilities (implement these in your
// project)
namespace SurfacerDrawUtilsPlaceholders {
struct AnnotatorParams {
	float surface_depth = 10.0f;
	int surface_depth_divisions_count = 5;
	float surface_alpha_end_ratio = 0.1f;
	float edge_start_radius = 5.0f;
	float edge_end_cone_length = 10.0f;
	float edge_end_radius = 3.0f;
	float edge_waypoint_stroke_width = 1.0f;
	float in_air_destination_indicator_size_ratio = 0.7f;
	int in_air_destination_indicator_cone_count = 4;
	float edge_instruction_indicator_length = 10.0f;
	float instruction_indicator_head_length_ratio = 0.3f;
	float instruction_indicator_head_width_ratio = 0.5f;
	float instruction_indicator_strike_trough_length_ratio = 0.8f;
	float instruction_indicator_stroke_width = 2.0f;
	float edge_trajectory_width = 2.0f;
	float path_downbeat_hash_length = 10.0f;
	float path_offbeat_hash_length = 5.0f;
	float edge_waypoint_radius = 3.0f;
	double adjacent_vertex_too_close_distance_squared_threshold = 1.0;
};
const AnnotatorParams &get_annotator_params();

namespace Geometry {
godot::Vector2 get_segment_normal(
		const godot::Vector2 &p_start,
		const godot::Vector2 &p_end);
godot::Vector2 get_intersection_of_segments(
		const godot::Vector2 &p_s1_start,
		const godot::Vector2 &p_s1_end,
		const godot::Vector2 &p_s2_start,
		const godot::Vector2 &p_s2_end);
godot::Vector2 project_point_onto_surface(
		const godot::Vector2 &p_point,
		godot::Surface *p_surface);
int get_tilemap_index_from_grid_coord(
		const godot::Vector2 &p_grid_coord,
		godot::TileMap *p_tile_map);
godot::Vector2 get_intersection_of_segment_and_circle(
		const godot::Vector2 &p_seg_a,
		const godot::Vector2 &p_seg_b,
		const godot::Vector2 &p_circle_center,
		double p_circle_radius);
} //namespace Geometry
namespace Utils {
double ease_by_name(double p_value, const godot::String &p_ease_name);
godot::PackedVector2Array sub_pool_vector2_array(
		const godot::PackedVector2Array &p_array,
		int p_from,
		int p_count = -1);
} //namespace Utils
namespace Palette {
godot::Color get_color(const godot::String &p_color_name);
}
namespace GUI {
godot::Ref<godot::Font> get_main_xxs_font();
}
namespace ScaffolderTime { // Placeholder for ScaffolderTime
const double PHYSICS_TIME_STEP = 1.0 / 60.0;
}
} //namespace SurfacerDrawUtilsPlaceholders

class SurfacerDrawUtils : public ScaffolderDrawUtils {
	GDCLASS(SurfacerDrawUtils, ScaffolderDrawUtils);

public:
	static constexpr double SQRT_TWO =
			Math_SQRT2; // From godot_cpp/core/math.hpp

protected:
	static void _bind_methods() {
	} // Static class, or bind if it's an instantiable utility object

public:
	SurfacerDrawUtils(); // Add constructor if needed
	~SurfacerDrawUtils(); // Add destructor if needed

	static void draw_surface(
			godot::CanvasItem *p_canvas,
			godot::Surface *p_surface,
			godot::Color p_color,
			float p_depth = -1.0f); // Sentinel for default

	static void draw_surface_segment(
			godot::CanvasItem *p_canvas,
			const godot::Vector2 &p_segment_start,
			const godot::Vector2 &p_segment_end,
			const godot::Vector2 &p_preceding_point,
			const godot::Vector2 &p_following_point,
			godot::Surface *p_surface, // Unused in GDScript, but kept for
									   // signature consistency
			godot::Color p_color,
			float p_depth);

	static void draw_single_vertex_surface(
			godot::CanvasItem *p_canvas,
			godot::Surface *p_surface,
			godot::Color p_color,
			float p_depth = -1.0f); // Sentinel for default

	static void draw_position_along_surface(
			godot::CanvasItem *p_canvas,
			godot::PositionAlongSurface *p_position,
			godot::Color p_target_point_color,
			godot::Color p_t_color,
			float p_target_point_radius = 4.0f,
			float p_t_length_in_surface = 8.0f,
			float p_t_length_out_of_surface = 8.0f,
			float p_t_width = 4.0f,
			bool p_t_value_drawn = true,
			bool p_target_point_drawn = false,
			bool p_surface_drawn = false);

	static void draw_origin_marker(
			godot::CanvasItem *p_canvas,
			const godot::Vector2 &p_target,
			godot::Color p_color,
			float p_radius = -1.0f, // Sentinel
			float p_border_width = 1.0f,
			float p_sector_arc_length = 3.0f);

	static void draw_destination_marker(
			godot::CanvasItem *p_canvas,
			godot::PositionAlongSurface *p_destination,
			bool p_is_based_on_target_point,
			godot::Color p_color,
			float p_cone_length = -1.0f, // Sentinel
			float p_circle_radius = -1.0f, // Sentinel
			bool p_is_filled = false,
			float p_border_width = -1.0f, // Sentinel
			float p_sector_arc_length = 4.0f);

	static void draw_instruction_indicator(
			godot::CanvasItem *p_canvas,
			const godot::String &p_input_key,
			bool p_is_pressed,
			const godot::Vector2 &p_position,
			float p_length,
			godot::Color p_color);

	static void draw_path(
			godot::CanvasItem *p_canvas,
			godot::PlatformGraphPath *p_path,
			float p_stroke_width = -1.0f, // Sentinel
			godot::Color p_color = godot::Color(
					1,
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
			godot::CanvasItem *p_canvas,
			godot::PlatformGraphPath *p_path,
			float p_segment_time_start,
			float p_segment_time_end,
			float p_stroke_width = -1.0f, // Sentinel
			godot::Color p_color = godot::Color(
					1,
					1,
					1,
					0), // Sentinel for default Color.white
			float p_trim_front_end_radius = 0.0f,
			float p_trim_back_end_radius = 0.0f);

	static void draw_beat_hashes(
			godot::CanvasItem *p_canvas,
			const godot::Array &p_beats, // Assuming Beat is a Ref<Beat> or
										 // similar stored in Array
			float p_downbeat_hash_length = -1.0f, // Sentinel
			float p_offbeat_hash_length = -1.0f, // Sentinel
			float p_downbeat_stroke_width = -1.0f, // Sentinel
			float p_offbeat_stroke_width = -1.0f, // Sentinel
			godot::Color p_downbeat_color =
					godot::Color(1, 1, 1, 0), // Sentinel
			godot::Color p_offbeat_color =
					godot::Color(1, 1, 1, 0)); // Sentinel

	static void draw_edge(
			godot::CanvasItem *p_canvas,
			godot::Edge *p_edge,
			float p_stroke_width = -1.0f, // Sentinel
			godot::Color p_discrete_trajectory_color =
					godot::Color(1, 1, 1, 0), // Sentinel
			bool p_includes_waypoints = false,
			bool p_includes_instruction_indicators = false,
			bool p_includes_continuous_positions = true,
			bool p_includes_discrete_positions = false);

	static void draw_tilemap_indices(
			godot::CanvasItem *p_canvas,
			godot::TileMap *p_tile_map,
			godot::Color p_color,
			bool p_only_renders_used_indices = false);

	static void draw_tile_grid_positions(
			godot::CanvasItem *p_canvas,
			godot::TileMap *p_tile_map,
			godot::Color p_color,
			bool p_only_renders_used_indices = false);

private:
	static godot::PackedVector2Array _trim_front_end(
			godot::PackedVector2Array p_vertices, // Pass by value to modify
			float p_trim_radius);

	static godot::PackedVector2Array _trim_back_end(
			godot::PackedVector2Array p_vertices, // Pass by value to modify
			float p_trim_radius);

	static godot::PackedVector2Array _get_edge_trajectory_vertices(
			godot::Edge *p_edge,
			bool p_includes_end_points = true,
			bool p_is_continuous = true,
			bool p_removes_too_close_vertices = false);

	static godot::PackedVector2Array _remove_too_close_neighbors(
			const godot::PackedVector2Array &p_vertices);
};

#endif // SURFACER_DRAW_UTILS_H