#ifndef GEOMETRY_H
#define GEOMETRY_H

#include "snore_core/geometry_constants.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/tile_map_layer.hpp>
#include <godot_cpp/core/object.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class RotatedShape;
class Shape2D;

class Geometry : public Object {
	GDCLASS(Geometry, Object)

public:
	static float get_distance_squared_from_point_to_segment(
			const Vector2 &p_point,
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b);
	static float get_distance_squared_from_point_to_polyline(
			const Vector2 &p_point,
			const PackedVector2Array &p_polyline);
	static float get_distance_squared_between_non_intersecting_segments(
			const Vector2 &p_segment_1_a,
			const Vector2 &p_segment_1_b,
			const Vector2 &p_segment_2_a,
			const Vector2 &p_segment_2_b);
	static float get_distance_squared_from_rect_to_rect(
			const Rect2 &p_a,
			const Rect2 &p_b);

	static Vector2 get_closest_point_on_segment_to_point(
			const Vector2 &p_point,
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b);
	static Vector2 get_closest_point_on_polyline_to_point(
			const Vector2 &p_point,
			const PackedVector2Array &p_polyline);
	static Vector2 get_closest_point_on_polyline_to_polyline(
			const PackedVector2Array &p_a,
			const PackedVector2Array &p_b);

	static Vector2 get_intersection_of_segments(
			const Vector2 &p_segment_1_a,
			const Vector2 &p_segment_1_b,
			const Vector2 &p_segment_2_a,
			const Vector2 &p_segment_2_b);
	// If the two don't intersect, this returns a vector with INF values.
	static Vector2 get_intersection_of_segment_and_polyline(
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			const PackedVector2Array &p_vertices);
	// - If the two don't intersect, this returns a vector with INF values.
	// - If there are two intersections, this returns the closest point to
	//   segment_a.
	static Vector2 get_intersection_of_segment_and_circle(
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			const Vector2 &p_center,
			float p_radius,
			bool p_uses_first_possible_intersection = true);

	static bool is_point_in_triangle(
			const Vector2 &p_point,
			const Vector2 &p_a,
			const Vector2 &p_b,
			const Vector2 &p_c);
	static bool is_point_in_rectangle(
			const Vector2 &p_point,
			const Vector2 &p_rectangle_min,
			const Vector2 &p_rectangle_max);

	static bool do_rectangles_intersect(
			const Vector2 &p_a_min,
			const Vector2 &p_a_max,
			const Vector2 &p_b_min,
			const Vector2 &p_b_max);
	static bool does_rectangle_and_circle_intersect(
			const Vector2 &p_rectangle_min,
			const Vector2 &p_rectangle_max,
			const Vector2 &p_circle_center,
			float p_circle_radius);
	static bool do_segment_and_rectangle_intersect(
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			const Vector2 &p_rectangle_min,
			const Vector2 &p_rectangle_max);
	static bool do_segment_and_triangle_intersect(
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			const Vector2 &p_triangle_a,
			const Vector2 &p_triangle_b,
			const Vector2 &p_triangle_c);
	// - Assumes that the polygon's closing segment is implied;
	//   i.e., polygon.last != polygon.first.
	// - Assumes that polygon.size() > 1.
	// - Assumes that segment_a != segment_b.
	static bool do_segment_and_polygon_intersect(
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			const PackedVector2Array &p_polygon);
	static bool do_polyline_and_rectangle_intersect(
			const PackedVector2Array &p_vertices,
			const Vector2 &p_rectangle_min,
			const Vector2 &p_rectangle_max);
	static bool do_polyline_and_triangle_intersect(
			const PackedVector2Array &p_vertices,
			const Vector2 &p_triangle_a,
			const Vector2 &p_triangle_b,
			const Vector2 &p_triangle_c);
	static bool do_polyline_and_polygon_intersect(
			const PackedVector2Array &p_vertices,
			const PackedVector2Array &p_polygon);

	static bool is_polygon_clockwise(const PackedVector2Array &p_vertices);
	static bool are_three_points_clockwise(
			const Vector2 &p_a,
			const Vector2 &p_b,
			const Vector2 &p_c);

	static bool is_polygon_convex(
			const PackedVector2Array &p_vertices,
			float p_epsilon = 0.001f);

	static bool are_points_collinear(
			const Vector2 &p_p1,
			const Vector2 &p_p2,
			const Vector2 &p_p3,
			float p_epsilon = float_epsilon);
	static bool do_point_and_segment_intersect(
			const Vector2 &p_point,
			const Vector2 &p_segment_a,
			const Vector2 &p_segment_b,
			float p_epsilon = float_epsilon);

	static Rect2 get_bounding_box_for_points(
			const PackedVector2Array &p_points);

	static float distance_squared_from_point_to_rect(
			const Vector2 &p_point,
			const Rect2 &p_rect);

	static float calculate_manhattan_distance(
			const Vector2 &p_a,
			const Vector2 &p_b);

	static bool is_point_inf(const Vector2 &p_point);
	static bool is_point_partial_inf(const Vector2 &p_point);

	static bool are_floats_equal_with_epsilon(
			float p_a,
			float p_b,
			float p_epsilon = float_epsilon);
	static bool are_points_equal_with_epsilon(
			const Vector2 &p_a,
			const Vector2 &p_b,
			float p_epsilon = float_epsilon);
	static bool are_rects_equal_with_epsilon(
			const Rect2 &p_a,
			const Rect2 &p_b,
			float p_epsilon = float_epsilon);
	static bool are_colors_equal_with_epsilon(
			const Color &p_a,
			const Color &p_b,
			float p_epsilon = float_epsilon);
	static bool is_float_integer_aligned_with_epsilon(
			float p_number,
			float p_epsilon = float_epsilon);
	static bool is_float_gte_with_epsilon(
			float p_a,
			float p_b,
			float p_epsilon = float_epsilon);
	static bool is_float_lte_with_epsilon(
			float p_a,
			float p_b,
			float p_epsilon = float_epsilon);

	static Vector2 clamp_vector_length(
			const Vector2 &p_vector,
			float p_min_length,
			float p_max_length);
	static float snap_float_to_integer(
			float p_number,
			float p_epsilon = float_epsilon);
	static Vector2 snap_vector2_to_integers(
			const Vector2 &p_point,
			float p_epsilon = float_epsilon);

	static bool do_shapes_match(
			const Ref<Shape2D> &p_shape_a,
			const Ref<Shape2D> &p_shape_b);
	static Vector2 calculate_half_width_height(
			const Ref<Shape2D> &p_shape,
			bool p_is_rotated_90_degrees);

	// The built-in TileMapLayer.world_to_map generates incorrect results
	// around cell boundaries, so we use a custom utility.
	static Vector2 world_to_tile_map_layer(
			const Vector2 &p_position,
			const TileMapLayer *p_tile_map_layer);
	static Vector2 tile_map_layer_to_world(
			const Vector2 &p_position,
			const TileMapLayer *p_tile_map_layer);
	// Calculates the TileMapLayer(grid-based) coordinates of the given
	// position, relative to the origin of the TileMapLayer's bounding box.
	static int get_tile_map_layer_index_from_world_coord(
			const Vector2 &p_position,
			const TileMapLayer *p_tile_map_layer);
	// Calculates the TileMapLayer(grid-based) coordinates of the given
	// position, relative to the origin of the TileMapLayer's bounding box.
	static int get_tile_map_layer_index_from_grid_coord(
			const Vector2 &p_position,
			const TileMapLayer *p_tile_map_layer);
	static Vector2 get_grid_coord_from_tile_map_layer_index(
			int p_index,
			const TileMapLayer *p_tile_map_layer);
	static Rect2 get_tile_map_layer_bounds_in_world_coordinates(
			const TileMapLayer *p_tile_map_layer);

	static Vector2 get_vector2_array_front(
			const PackedVector2Array &p_vertices);
	static Vector2 get_vector2_array_back(const PackedVector2Array &p_vertices);

	static String get_vector_string(
			const Vector2 &p_vector,
			int p_decimal_place_count = 2);

	// Returns a perpendicular vector rotated 90 degrees counter-clockwise
	// compared to the original, with the same length.
	static Vector2 get_perpendicular_vector(const Vector2 &p_vector);

	static bool is_valid(const Vector2 &p_vector);

	static float get_radius(const Ref<Shape2D> &p_shape);

	static Vector2 get_furthest_shape_boundary_point_in_direction(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Vector2 &p_direction);

	static bool check_for_shape_to_rect_intersection(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Rect2 &p_rect,
			float p_epsilon = 0.0f);

protected:
	static void _bind_methods();
};

} //namespace godot

#endif // GEOMETRY_H
