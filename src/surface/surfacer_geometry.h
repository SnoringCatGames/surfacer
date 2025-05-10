#ifndef SURFACER_GEOMETRY_H
#define SURFACER_GEOMETRY_H

#include "geometry.h"
#include "position_along_surface.h"
#include "rotated_shape.h"
#include "surface.h"

namespace godot {

// TODO: Sync this with the game's project settings.
static constexpr double floor_max_angle = Math_PI / 4.0f;
static constexpr double wall_angle_epsilon = 0.01f;

class SurfacerGeometry : public Object {
	GDCLASS(SurfacerGeometry, Object)

public:
	static Vector2 project_point_onto_surface(
			const Vector2 &p_point,
			const Ref<Surface> &p_surface,
			Surface::Side p_side_override = Surface::Side::UNKNOWN_SIDE);
	static Vector2 get_surface_normal_at_point(
			const Ref<Surface> &p_surface,
			const Vector2 &p_point);
	static Vector2 get_segment_normal(
			const Vector2 &p_segment_start,
			const Vector2 &p_segment_end);
	static Vector2 project_shape_onto_surface(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Ref<Surface> &p_surface,
			bool p_uses_end_segment_if_outside_bounds = true,
			Surface::Side p_side_override = Surface::Side::UNKNOWN_SIDE);
	static Vector2 project_shape_onto_segment(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			Surface::Side p_surface_side,
			const Vector2 &p_segment_start,
			const Vector2 &p_segment_end);
	static Vector2 project_shape_onto_segment_and_away_from_concave_neighbors(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Ref<Surface> &p_surface,
			bool p_uses_end_segment_if_outside_bounds = true,
			bool p_rejects_non_overlapping_results = true,
			Surface::Side p_side_override = Surface::Side::UNKNOWN_SIDE);
	static Surface::Side get_concave_neighbor_projection_side_override(
			const Ref<Surface> &p_surface,
			bool p_is_clockwise);
	static Vector2 project_away_from_concave_neighbor(
			const Vector2 &p_position,
			const Ref<Surface> &p_neighbor,
			Surface::Side p_neighbor_normal_side_override,
			const Ref<RotatedShape> &p_shape);
	static Vector2 get_closest_point_on_surface_to_shape(
			const Ref<Surface> &p_surface,
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape);
	static Vector2 get_furthest_shape_boundary_point_in_direction(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Vector2 &p_direction);
	static Vector2
	nudge_point_along_axially_aligned_segment_toward_shape_center(
			const Vector2 &p_point,
			const Ref<Surface> &p_surface,
			const Vector2 &p_shape_position);

	static bool do_surface_and_rectangle_intersect(
			const Ref<Surface> &p_surface,
			const Vector2 &p_rectangle_min,
			const Vector2 &p_rectangle_max);
	static bool check_for_shape_to_rect_intersection(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Rect2 &p_rect,
			double p_epsilon = 0.0);
	static bool check_for_shape_to_surface_overlap(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Ref<Surface> &p_surface,
			double p_epsilon = shape_overlap_with_concave_epsilon);

	static void get_surface_segment_at_point(
			Array &r_segment_points_result,
			const Ref<Surface> &p_surface,
			const Vector2 &p_point,
			bool p_uses_end_segment_if_outside_bounds);
	static Array get_vertices_around_range(
			const Ref<Surface> &p_surface,
			double p_range_min_x,
			double p_range_max_x,
			double p_range_min_y,
			double p_range_max_y);

	static bool are_position_wrappers_equal_with_epsilon(
			const Ref<PositionAlongSurface> &p_a,
			const Ref<PositionAlongSurface> &p_b,
			double p_epsilon = 1e-6);

	static Surface::Side get_surface_side_for_normal(const Vector2 &p_normal);

	static Vector2 project_shape_onto_convex_corner_preserving_tangent_position(
			const Vector2 &p_shape_position,
			const Ref<RotatedShape> &p_shape,
			const Ref<Surface> &p_origin_surface,
			const Ref<Surface> &p_destination_surface);

	static double calculate_displacement_x_for_vertical_distance_past_edge(
			double p_distance_past_edge,
			bool p_is_left_wall,
			const Ref<RotatedShape> &p_collider);
	static double
	calculate_circular_displacement_x_for_vertical_distance_past_edge(
			double p_distance_past_edge,
			double p_radius,
			bool p_is_left_wall);
	static double calculate_displacement_y_for_horizontal_distance_past_edge(
			double p_distance_past_edge,
			bool p_is_floor,
			const Ref<RotatedShape> &p_collider);
	static double
	calculate_circular_displacement_y_for_horizontal_distance_past_edge(
			double p_distance_past_edge,
			double p_radius,
			bool p_is_floor);

protected:
	static void _bind_methods();

private:
	static constexpr float shape_overlap_with_concave_surface_epsilon = 4.0f;
};

} //namespace godot

#endif
