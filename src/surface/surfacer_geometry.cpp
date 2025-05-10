#include "surfacer_geometry.h"

#include "internal_utils.h"

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

using namespace godot;

// FIXME: REVIEW THIS.

Vector2 SurfacerGeometry::project_point_onto_surface(
		const Vector2 &p_point,
		const Ref<Surface> &p_surface,
		Surface::Side p_side_override) {
	Surface::Side surface_side =
			(p_side_override == Surface::Side::UNKNOWN_SIDE)
			? p_surface->get_side()
			: p_side_override;
	Vector2 start_vertex = p_surface->get_first_point();
	Vector2 end_vertex = p_surface->get_last_point();

	switch (surface_side) {
		case Surface::Side::FLOOR: {
			if (p_point.x <= start_vertex.x)
				return start_vertex;
			if (p_point.x >= end_vertex.x)
				return end_vertex;
			break;
		}
		case Surface::Side::CEILING: {
			if (p_point.x >= start_vertex.x)
				return start_vertex;
			if (p_point.x <= end_vertex.x)
				return end_vertex;
			break;
		}
		case Surface::Side::LEFT_WALL: {
			if (p_point.y <= start_vertex.y)
				return start_vertex;
			if (p_point.y >= end_vertex.y)
				return end_vertex;
			break;
		}
		case Surface::Side::RIGHT_WALL: {
			if (p_point.y >= start_vertex.y)
				return start_vertex;
			if (p_point.y <= end_vertex.y)
				return end_vertex;
			break;
		}
		default: {
			ENSURE(false,
				   "SurfacerGeometry::project_point_onto_surface: Invalid "
				   "surface side");
			break;
		}
	}

	Vector2 segment_a, segment_b;
	if (surface_side == Surface::Side::FLOOR ||
		surface_side == Surface::Side::CEILING) {
		segment_a =
				Vector2(p_point.x, p_surface->get_bounding_box().position.y);
		segment_b =
				Vector2(p_point.x, p_surface->get_bounding_box().get_end().y);
	} else {
		segment_a =
				Vector2(p_surface->get_bounding_box().position.x, p_point.y);
		segment_b =
				Vector2(p_surface->get_bounding_box().get_end().x, p_point.y);
	}

	Vector2 intersection = Geometry::get_intersection_of_segment_and_polyline(
			segment_a, segment_b, p_surface->get_vertices());
	ENSURE_SIMPLE(intersection == vector2_invalid, vector2_invalid);
	return intersection;
}

Vector2 SurfacerGeometry::get_surface_normal_at_point(
		const Ref<Surface> &p_surface,
		const Vector2 &p_point) {
	if (!p_surface.is_valid()) {
		return vector2_invalid;
	}
	if (p_surface->get_vertices().size() <= 1) {
		return p_surface->get_normal();
	}

	Array segment_points_result;
	get_surface_segment_at_point(
			segment_points_result, p_surface, p_point, true);
	Vector2 segment_start = segment_points_result[0];
	Vector2 segment_end = segment_points_result[1];
	return get_segment_normal(segment_start, segment_end);
}

Vector2 SurfacerGeometry::get_segment_normal(
		const Vector2 &p_segment_start,
		const Vector2 &p_segment_end) {
	Vector2 displacement = p_segment_end - p_segment_start;
	Vector2 perpendicular(displacement.y, -displacement.x);
	return perpendicular.normalized();
}

Vector2 SurfacerGeometry::project_shape_onto_surface(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Ref<Surface> &p_surface,
		bool p_uses_end_segment_if_outside_bounds,
		Surface::Side p_side_override) {
	// Ported from GDScript: see surfacer_geometry.gd for full logic

	Surface::Side surface_side =
			(p_side_override == Surface::Side::UNKNOWN_SIDE)
			? p_surface->get_side()
			: p_side_override;

	bool is_horizontal_surface = surface_side == Surface::Side::FLOOR ||
			surface_side == Surface::Side::CEILING;

	if (!p_surface.is_valid())
		return vector2_invalid;

	if ((is_horizontal_surface && p_shape_position.x == Math_INF) ||
		(!is_horizontal_surface && p_shape_position.y == Math_INF))
		return vector2_invalid;

	if (!p_shape.is_valid())
		return project_point_onto_surface(
				p_shape_position, p_surface, surface_side);

	// Allow infinite coordinate for the axis we're projecting along
	Vector2 shape_position = p_shape_position;
	if (is_horizontal_surface && shape_position.y == Math_INF)
		shape_position.y = 0.0;
	if (!is_horizontal_surface && shape_position.x == Math_INF)
		shape_position.x = 0.0;

	Vector2 half_width_height = p_shape->get_half_width_height();
	double shape_min_x = shape_position.x - half_width_height.x;
	double shape_max_x = shape_position.x + half_width_height.x;
	double shape_min_y = shape_position.y - half_width_height.y;
	double shape_max_y = shape_position.y + half_width_height.y;

	Vector2 shape_min_side_point = vector2_invalid;
	Vector2 shape_max_side_point = vector2_invalid;
	if (is_horizontal_surface) {
		shape_min_side_point = Vector2(shape_min_x, 0.0);
		shape_max_side_point = Vector2(shape_max_x, 0.0);
	} else {
		shape_min_side_point = Vector2(0.0, shape_min_y);
		shape_max_side_point = Vector2(0.0, shape_max_y);
	}

	if (p_uses_end_segment_if_outside_bounds) {
		Vector2 nudged_shape_position = shape_position;
		if (is_horizontal_surface) {
			if (shape_max_x <
				p_surface->get_bounding_box().position.x + 0.0001) {
				nudged_shape_position.x +=
						p_surface->get_bounding_box().position.x + 0.001 -
						shape_max_x;
			} else if (
					shape_min_x >
					p_surface->get_bounding_box().get_end().x - 0.0001) {
				nudged_shape_position.x +=
						p_surface->get_bounding_box().get_end().x - 0.001 -
						shape_min_x;
			}
		} else {
			if (shape_max_y <
				p_surface->get_bounding_box().position.y + 0.0001) {
				nudged_shape_position.y +=
						p_surface->get_bounding_box().position.y + 0.001 -
						shape_max_y;
			} else if (
					shape_min_y >
					p_surface->get_bounding_box().get_end().y - 0.0001) {
				nudged_shape_position.y +=
						p_surface->get_bounding_box().get_end().y - 0.001 -
						shape_min_y;
			}
		}
		if (nudged_shape_position != shape_position) {
			Vector2 nudged_projection = project_shape_onto_surface(
					nudged_shape_position, p_shape, p_surface,
					p_uses_end_segment_if_outside_bounds, p_side_override);
			if (is_horizontal_surface)
				nudged_projection.x = shape_position.x;
			else
				nudged_projection.y = shape_position.y;
			return nudged_projection;
		}
	}

	// If the surface is a single vertex, project onto that point
	if (p_surface->get_vertices().size() <= 1) {
		return project_shape_onto_segment(
				shape_position, p_shape, surface_side,
				p_surface->get_vertices()[0], p_surface->get_vertices()[0]);
	}

	// Get relevant vertices for the shape's bounding box
	Array vertices_to_check = get_vertices_around_range(
			p_surface, shape_min_x, shape_max_x, shape_min_y, shape_max_y);

	Vector2 furthest_projection = vector2_invalid;
	switch (surface_side) {
		case Surface::Side::FLOOR: {
			furthest_projection = vector2_invalid;
			for (int i = 0; i < vertices_to_check.size() - 1; ++i) {
				Vector2 projection = project_shape_onto_segment(
						shape_position, p_shape, surface_side,
						(Vector2)vertices_to_check[i],
						(Vector2)vertices_to_check[i + 1]);
				if (projection.y < furthest_projection.y)
					furthest_projection = projection;
			}
			break;
		}
		case Surface::Side::LEFT_WALL: {
			furthest_projection = -vector2_invalid;
			for (int i = 0; i < vertices_to_check.size() - 1; ++i) {
				Vector2 projection = project_shape_onto_segment(
						shape_position, p_shape, surface_side,
						(Vector2)vertices_to_check[i],
						(Vector2)vertices_to_check[i + 1]);
				if (projection.x > furthest_projection.x)
					furthest_projection = projection;
			}
			break;
		}
		case Surface::Side::RIGHT_WALL: {
			furthest_projection = vector2_invalid;
			for (int i = 0; i < vertices_to_check.size() - 1; ++i) {
				Vector2 projection = project_shape_onto_segment(
						shape_position, p_shape, surface_side,
						(Vector2)vertices_to_check[i],
						(Vector2)vertices_to_check[i + 1]);
				if (projection.x < furthest_projection.x)
					furthest_projection = projection;
			}
			break;
		}
		case Surface::Side::CEILING: {
			furthest_projection = -vector2_invalid;
			for (int i = 0; i < vertices_to_check.size() - 1; ++i) {
				Vector2 projection = project_shape_onto_segment(
						shape_position, p_shape, surface_side,
						(Vector2)vertices_to_check[i],
						(Vector2)vertices_to_check[i + 1]);
				if (projection.y > furthest_projection.y)
					furthest_projection = projection;
			}
			break;
		}
		default:
			ENSURE(false,
				   "SurfacerGeometry::project_shape_onto_surface: Invalid "
				   "surface side");
			break;
	}

	return furthest_projection;
}
Vector2 SurfacerGeometry::project_shape_onto_segment(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		Surface::Side p_surface_side,
		const Vector2 &p_segment_start,
		const Vector2 &p_segment_end) {
	// This is a simplified version. For full support, you must implement logic
	// for each shape type.
	Vector2 surface_normal = Surface::get_normal_from_side(p_surface_side);

	if (p_shape.is_valid() || p_shape->get_shape().is_valid()) {
		// No shape: project the center along the normal onto the segment.
		return Geometry::get_intersection_of_segments(
				p_shape_position - surface_normal * 100000.0,
				p_shape_position + surface_normal * 100000.0, p_segment_start,
				p_segment_end);
	}

	// For now, just project the center as above (expand for full shape
	// support).
	return Geometry::get_intersection_of_segments(
			p_shape_position - surface_normal * 100000.0,
			p_shape_position + surface_normal * 100000.0, p_segment_start,
			p_segment_end);
}

Vector2 SurfacerGeometry::
		project_shape_onto_segment_and_away_from_concave_neighbors(
				const Vector2 &p_shape_position,
				const Ref<RotatedShape> &p_shape,
				const Ref<Surface> &p_surface,
				bool p_uses_end_segment_if_outside_bounds,
				bool p_rejects_non_overlapping_results,
				Surface::Side p_side_override) {
	Vector2 projection = project_shape_onto_surface(
			p_shape_position, p_shape, p_surface,
			p_uses_end_segment_if_outside_bounds, p_side_override);
	if (projection == vector2_invalid) {
		return vector2_invalid;
	}

	Ref<Surface> cw_neighbor = p_surface->get_clockwise_neighbor();
	bool is_cw_neighbor_concave =
			cw_neighbor == p_surface->get_clockwise_concave_neighbor();
	if (is_cw_neighbor_concave) {
		Surface::Side cw_neighbor_normal_side_override =
				get_concave_neighbor_projection_side_override(p_surface, true);
		Vector2 neighbor_projection = project_away_from_concave_neighbor(
				projection, cw_neighbor, cw_neighbor_normal_side_override,
				p_shape);
		if (neighbor_projection != vector2_invalid) {
			projection = neighbor_projection;
			if (p_rejects_non_overlapping_results &&
				!check_for_shape_to_surface_overlap(
						projection, p_shape, p_surface)) {
				return vector2_invalid;
			}
		}
	}

	Ref<Surface> ccw_neighbor = p_surface->get_counter_clockwise_neighbor();
	bool is_ccw_neighbor_concave =
			ccw_neighbor == p_surface->get_counter_clockwise_concave_neighbor();
	if (is_ccw_neighbor_concave) {
		Surface::Side ccw_neighbor_normal_side_override =
				get_concave_neighbor_projection_side_override(p_surface, false);
		Vector2 neighbor_projection = project_away_from_concave_neighbor(
				projection, ccw_neighbor, ccw_neighbor_normal_side_override,
				p_shape);
		if (neighbor_projection != vector2_invalid) {
			projection = neighbor_projection;
			if (p_rejects_non_overlapping_results &&
				!check_for_shape_to_surface_overlap(
						projection, p_shape, p_surface)) {
				return vector2_invalid;
			}
		}
	}

	return projection;
}

Surface::Side SurfacerGeometry::get_concave_neighbor_projection_side_override(
		const Ref<Surface> &p_surface,
		bool p_is_clockwise) {
	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR:
			return p_is_clockwise ? Surface::Side::RIGHT_WALL
								  : Surface::Side::LEFT_WALL;
		case Surface::Side::LEFT_WALL:
			return p_is_clockwise ? Surface::Side::FLOOR
								  : Surface::Side::CEILING;
		case Surface::Side::RIGHT_WALL:
			return p_is_clockwise ? Surface::Side::CEILING
								  : Surface::Side::FLOOR;
		case Surface::Side::CEILING:
			return p_is_clockwise ? Surface::Side::LEFT_WALL
								  : Surface::Side::RIGHT_WALL;
		default:
			ENSURE(false,
				   "SurfacerGeometry::get_concave_neighbor_projection_side_"
				   "override: Invalid surface side");
			return Surface::Side::UNKNOWN_SIDE;
	}
}
Vector2 SurfacerGeometry::project_away_from_concave_neighbor(
		const Vector2 &p_position,
		const Ref<Surface> &p_neighbor,
		Surface::Side p_neighbor_normal_side_override,
		const Ref<RotatedShape> &p_shape) {
	// Broad-phase check: Can these be intersecting?
	if (!check_for_shape_to_rect_intersection(
				p_position, p_shape, p_neighbor->get_bounding_box())) {
		return vector2_invalid;
	}

	Vector2 concave_neighbor_projection = project_shape_onto_surface(
			p_position, p_shape, p_neighbor, true,
			p_neighbor_normal_side_override);

	if (concave_neighbor_projection == vector2_invalid) {
		return vector2_invalid;
	}

	switch (p_neighbor_normal_side_override) {
		case Surface::Side::FLOOR:
			if (concave_neighbor_projection.y < p_position.y) {
				Vector2 result = p_position;
				result.y = concave_neighbor_projection.y;
				return result;
			}
			break;
		case Surface::Side::LEFT_WALL:
			if (concave_neighbor_projection.x > p_position.x) {
				Vector2 result = p_position;
				result.x = concave_neighbor_projection.x;
				return result;
			}
			break;
		case Surface::Side::RIGHT_WALL:
			if (concave_neighbor_projection.x < p_position.x) {
				Vector2 result = p_position;
				result.x = concave_neighbor_projection.x;
				return result;
			}
			break;
		case Surface::Side::CEILING:
			if (concave_neighbor_projection.y > p_position.y) {
				Vector2 result = p_position;
				result.y = concave_neighbor_projection.y;
				return result;
			}
			break;
		default:
			ENSURE(false,
				   "SurfacerGeometry::project_away_from_concave_neighbor: "
				   "Invalid neighbor_normal_side_override");
			break;
	}

	return vector2_invalid;
}

Vector2 SurfacerGeometry::get_closest_point_on_surface_to_shape(
		const Ref<Surface> &p_surface,
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape) {
	if (p_surface->get_is_single_vertex()) {
		return p_surface->get_first_point();
	}

	double closest_distance_squared = Math_INF;
	Vector2 closest_point_on_surface = vector2_invalid;

	const Array &vertices = p_surface->get_vertices();
	for (int i = 0; i < vertices.size() - 1; ++i) {
		Vector2 segment_start = vertices[i];
		Vector2 segment_end = vertices[i + 1];
		Vector2 segment_normal = get_segment_normal(segment_start, segment_end);
		Vector2 closest_point_on_shape_to_segment =
				get_furthest_shape_boundary_point_in_direction(
						p_shape_position, p_shape, -segment_normal);
		Vector2 closest_point_on_segment_to_point =
				Geometry::get_closest_point_on_segment_to_point(
						closest_point_on_shape_to_segment, segment_start,
						segment_end);
		double current_distance_squared =
				closest_point_on_shape_to_segment.distance_squared_to(
						closest_point_on_segment_to_point);
		if (current_distance_squared < closest_distance_squared) {
			closest_distance_squared = current_distance_squared;
			closest_point_on_surface = closest_point_on_segment_to_point;
		}
	}

	return closest_point_on_surface;
}

Vector2 SurfacerGeometry::get_furthest_shape_boundary_point_in_direction(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Vector2 &p_direction) {
	// CircleShape2D
	if (Object::cast_to<CircleShape2D>(p_shape->get_shape().ptr())) {
		const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_shape->get_shape().ptr());
		return p_shape_position +
				circle->get_radius() * p_direction.normalized();
	}
	// RectangleShape2D
	else if (Object::cast_to<RectangleShape2D>(p_shape->get_shape().ptr())) {
		const RectangleShape2D *rect =
				Object::cast_to<RectangleShape2D>(p_shape->get_shape().ptr());
		Vector2 extents = rect->get_size() / 2.0f;
		if (p_direction.x == 0.0) {
			return p_shape_position +
					Vector2(0.0, extents.y * SIGN(p_direction.y));
		} else if (p_direction.y == 0.0) {
			return p_shape_position +
					Vector2(extents.x * SIGN(p_direction.x), 0.0);
		} else if (p_direction.x < 0.0 && p_direction.y < 0.0) {
			return p_shape_position + Vector2(-extents.x, -extents.y);
		} else if (p_direction.x < 0.0 && p_direction.y > 0.0) {
			return p_shape_position + Vector2(-extents.x, extents.y);
		} else if (p_direction.x > 0.0 && p_direction.y < 0.0) {
			return p_shape_position + Vector2(extents.x, -extents.y);
		} else { // p_direction.x > 0.0 && p_direction.y > 0.0
			return p_shape_position + Vector2(extents.x, extents.y);
		}
	}
	// CapsuleShape2D
	else if (Object::cast_to<CapsuleShape2D>(p_shape->get_shape().ptr())) {
		const CapsuleShape2D *capsule =
				Object::cast_to<CapsuleShape2D>(p_shape->get_shape().ptr());
		double radius = capsule->get_radius();
		double height = capsule->get_height();
		if (p_shape->get_is_rotated_90_degrees()) {
			if (p_direction.x == 0.0) {
				return p_shape_position +
						Vector2(0.0, radius * SIGN(p_direction.y));
			} else if (p_direction.x < 0.0) {
				Vector2 capsule_end_center =
						p_shape_position + Vector2(-height * 0.5, 0.0);
				return capsule_end_center + radius * p_direction.normalized();
			} else { // p_direction.x > 0.0
				Vector2 capsule_end_center =
						p_shape_position + Vector2(height * 0.5, 0.0);
				return capsule_end_center + radius * p_direction.normalized();
			}
		} else {
			if (p_direction.y == 0.0) {
				return p_shape_position +
						Vector2(radius * SIGN(p_direction.x), 0.0);
			} else if (p_direction.y < 0.0) {
				Vector2 capsule_end_center =
						p_shape_position + Vector2(0.0, -height * 0.5);
				return capsule_end_center + radius * p_direction.normalized();
			} else { // p_direction.y > 0.0
				Vector2 capsule_end_center =
						p_shape_position + Vector2(0.0, height * 0.5);
				return capsule_end_center + radius * p_direction.normalized();
			}
		}
	}
	// Fallback
	ENSURE(false,
		   "SurfacerGeometry::get_furthest_shape_boundary_point_in_direction: "
		   "Unsupported shape type");
	return vector2_invalid;
}
Vector2 SurfacerGeometry::
		nudge_point_along_axially_aligned_segment_toward_shape_center(
				const Vector2 &p_point,
				const Ref<Surface> &p_surface,
				const Vector2 &p_shape_position) {
	if (p_surface->get_is_single_vertex()) {
		// No room to nudge.
		return p_point;
	}

	bool is_horizontal = p_surface->get_side() == Surface::Side::FLOOR ||
			p_surface->get_side() == Surface::Side::CEILING;
	if ((is_horizontal &&
		 Geometry::are_floats_equal_with_epsilon(
				 p_point.x, p_shape_position.x, 0.001)) ||
		(!is_horizontal &&
		 Geometry::are_floats_equal_with_epsilon(
				 p_point.y, p_shape_position.y, 0.001))) {
		// Already centered.
		return p_point;
	}

	Array segment_points;
	get_surface_segment_at_point(segment_points, p_surface, p_point, true);
	Vector2 segment_start = segment_points[0];
	Vector2 segment_end = segment_points[1];
	Vector2 displacement = segment_end - segment_start;
	bool is_segment_axially_aligned = segment_start.x == segment_end.x ||
			segment_start.y == segment_end.y;
	if (!is_segment_axially_aligned) {
		// If the segment isn't axially aligned, then there should only be the
		// one point of intersection.
		return p_point;
	}

	Vector2 nudged_point = p_point;
	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR:
			nudged_point.x =
					CLAMP(p_shape_position.x, segment_start.x, segment_end.x);
			break;
		case Surface::Side::LEFT_WALL:
			nudged_point.y =
					CLAMP(p_shape_position.y, segment_start.y, segment_end.y);
			break;
		case Surface::Side::RIGHT_WALL:
			nudged_point.y =
					CLAMP(p_shape_position.y, segment_end.y, segment_start.y);
			break;
		case Surface::Side::CEILING:
			nudged_point.x =
					CLAMP(p_shape_position.x, segment_end.x, segment_start.x);
			break;
		default:
			ENSURE(false,
				   "SurfacerGeometry::nudge_point_along_axially_aligned_"
				   "segment_toward_shape_center: Invalid surface side");
			break;
	}

	return nudged_point;
}

bool SurfacerGeometry::do_surface_and_rectangle_intersect(
		const Ref<Surface> &p_surface,
		const Vector2 &p_rectangle_min,
		const Vector2 &p_rectangle_max) {
	// Broad-phase pass: Check whether the surface bounding box intersects.
	Rect2 bb = p_surface->get_bounding_box();
	if (bb.position.x > p_rectangle_max.x ||
		bb.position.y > p_rectangle_max.y ||
		bb.get_end().x < p_rectangle_min.x ||
		bb.get_end().y < p_rectangle_min.y) {
		return false;
	}

	return Geometry::do_polyline_and_rectangle_intersect(
			p_surface->get_vertices(), p_rectangle_min, p_rectangle_max);
}

bool SurfacerGeometry::check_for_shape_to_rect_intersection(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Rect2 &p_rect,
		double p_epsilon) {
	Vector2 half_width_height = p_shape->get_half_width_height();
	return p_rect.position.x <
			p_shape_position.x + half_width_height.x + p_epsilon &&
			p_rect.get_end().x >
			p_shape_position.x - half_width_height.x - p_epsilon &&
			p_rect.position.y <
			p_shape_position.y + half_width_height.y + p_epsilon &&
			p_rect.get_end().y >
			p_shape_position.y - half_width_height.y - p_epsilon;
}
bool SurfacerGeometry::check_for_shape_to_surface_overlap(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Ref<Surface> &p_surface,
		double p_epsilon) {
	double shape_min_x =
			p_shape_position.x - p_shape->get_half_width_height().x;
	double shape_max_x =
			p_shape_position.x + p_shape->get_half_width_height().x;
	double shape_min_y =
			p_shape_position.y - p_shape->get_half_width_height().y;
	double shape_max_y =
			p_shape_position.y + p_shape->get_half_width_height().y;

	Vector2 surface_bb_pos = p_surface->get_bounding_box().position;
	Vector2 surface_bb_end = p_surface->get_bounding_box().get_end();

	bool is_surface_horizontal =
			p_surface->get_side() == Surface::Side::FLOOR ||
			p_surface->get_side() == Surface::Side::CEILING;

	if (is_surface_horizontal &&
		(shape_min_x > surface_bb_end.x - p_epsilon ||
		 shape_max_x < surface_bb_pos.x + p_epsilon)) {
		return false;
	} else if (
			!is_surface_horizontal &&
			(shape_min_y > surface_bb_end.y - p_epsilon ||
			 shape_max_y < surface_bb_pos.y + p_epsilon)) {
		return false;
	} else {
		return true;
	}
}

void SurfacerGeometry::get_surface_segment_at_point(
		Array &r_segment_points_result,
		const Ref<Surface> &p_surface,
		const Vector2 &p_point,
		bool p_uses_end_segment_if_outside_bounds) {
	if (!p_surface.is_valid()) {
		r_segment_points_result.resize(0);
		return;
	}

	double epsilon = 0.01;
	Array vertices = p_surface->get_vertices();
	int count = vertices.size();

	if (count <= 1) {
		r_segment_points_result.resize(0);
		return;
	}

	bool inside_bounds = false;
	Vector2 segment_start = vector2_invalid;
	Vector2 segment_end = vector2_invalid;

	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR:
			if (p_point.x < ((Vector2)vertices[0]).x + epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.x > ((Vector2)vertices[count - 1]).x - epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.x < ((Vector2)vertices[i]).x) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		case Surface::Side::LEFT_WALL:
			if (p_point.y < ((Vector2)vertices[0]).y + epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.y > ((Vector2)vertices[count - 1]).y - epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.y < ((Vector2)vertices[i]).y) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		case Surface::Side::RIGHT_WALL:
			if (p_point.y > ((Vector2)vertices[0]).y - epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.y < ((Vector2)vertices[count - 1]).y + epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.y > ((Vector2)vertices[i]).y) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		case Surface::Side::CEILING:
			if (p_point.x > ((Vector2)vertices[0]).x - epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.x < ((Vector2)vertices[count - 1]).x + epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.x > ((Vector2)vertices[i]).x) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		default:
			ENSURE(false,
				   "SurfacerGeometry::get_surface_segment_at_point: Invalid "
				   "surface side");
			break;
	}

	if (inside_bounds || p_uses_end_segment_if_outside_bounds) {
		r_segment_points_result.resize(2);
		r_segment_points_result[0] = segment_start;
		r_segment_points_result[1] = segment_end;
	} else {
		r_segment_points_result.resize(0);
	}
}

Array SurfacerGeometry::get_vertices_around_range(
		const Ref<Surface> &p_surface,
		double p_range_min_x,
		double p_range_max_x,
		double p_range_min_y,
		double p_range_max_y) {
	if (!p_surface.is_valid()) {
		return Array();
	}

	double epsilon = 0.01;
	Array vertices = p_surface->get_vertices();
	int count = vertices.size();

	if (count <= 1) {
		Array arr;
		arr.push_back(vertices[0]);
		return arr;
	}

	int start_index = 0;
	int end_index = 0;

	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR:
			for (int i = 0; i < count; ++i) {
				if (((Vector2)vertices[i]).x > p_range_min_x) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (((Vector2)vertices[i]).x > p_range_max_x) {
					break;
				}
			}
			break;
		case Surface::Side::LEFT_WALL:
			for (int i = 0; i < count; ++i) {
				if (((Vector2)vertices[i]).y > p_range_min_y) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (((Vector2)vertices[i]).y > p_range_max_y) {
					break;
				}
			}
			break;
		case Surface::Side::RIGHT_WALL:
			for (int i = 0; i < count; ++i) {
				if (((Vector2)vertices[i]).y < p_range_max_y) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (((Vector2)vertices[i]).y < p_range_min_y) {
					break;
				}
			}
			break;
		case Surface::Side::CEILING:
			for (int i = 0; i < count; ++i) {
				if (((Vector2)vertices[i]).x < p_range_max_x) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (((Vector2)vertices[i]).x < p_range_min_x) {
					break;
				}
			}
			break;
		default:
			ENSURE(false,
				   "SurfacerGeometry::get_vertices_around_range: Invalid "
				   "surface side");
			break;
	}

	int result_size = end_index - start_index + 1;
	Array result;
	result.resize(result_size);
	for (int i = 0; i < result_size; ++i) {
		result[i] = vertices[start_index + i];
	}

	return result;
}
bool SurfacerGeometry::are_position_wrappers_equal_with_epsilon(
		const Ref<PositionAlongSurface> &p_a,
		const Ref<PositionAlongSurface> &p_b,
		double p_epsilon) {
	if (p_a.is_valid() && p_b.is_valid()) {
		return true;
	} else if (p_a.is_valid() || p_b.is_valid()) {
		return false;
	} else if (p_a->get_surface() != p_b->get_surface()) {
		return false;
	}
	double x_diff = p_b->get_target_position().x - p_a->get_target_position().x;
	double y_diff = p_b->get_target_position().y - p_a->get_target_position().y;
	return -p_epsilon < x_diff && x_diff < p_epsilon && -p_epsilon < y_diff &&
			y_diff < p_epsilon;
}

Surface::Side SurfacerGeometry::get_surface_side_for_normal(
		const Vector2 &p_normal) {
	if (ABS(p_normal.angle_to(vector2_up)) <=
		floor_max_angle + wall_angle_epsilon) {
		return Surface::Side::FLOOR;
	} else if (
			ABS(p_normal.angle_to(vector2_down)) <=
			floor_max_angle + wall_angle_epsilon) {
		return Surface::Side::CEILING;
	} else if (p_normal.x > 0) {
		return Surface::Side::LEFT_WALL;
	} else {
		return Surface::Side::RIGHT_WALL;
	}
}

Vector2 SurfacerGeometry::
		project_shape_onto_convex_corner_preserving_tangent_position(
				const Vector2 &p_shape_position,
				const Ref<RotatedShape> &p_shape,
				const Ref<Surface> &p_origin_surface,
				const Ref<Surface> &p_destination_surface) {
	Vector2 projection = vector2_invalid;

	// This logic assumes you have a flag for oddly shaped surfaces and the
	// relevant checks.
	bool oddly_shaped_surfaces_used = false; // Replace with your actual check.
	if (oddly_shaped_surfaces_used &&
		(p_origin_surface.is_valid() || p_destination_surface.is_valid())) {
		Vector2 destination_projection = vector2_invalid;
		if (p_destination_surface.is_valid()) {
			destination_projection = project_shape_onto_surface(
					p_shape_position, p_shape, p_destination_surface, true,
					p_origin_surface->get_side());
		}

		Vector2 origin_projection = vector2_invalid;
		if (p_origin_surface.is_valid()) {
			origin_projection = project_shape_onto_surface(
					p_shape_position, p_shape, p_origin_surface, true,
					p_origin_surface->get_side());
		}

		bool is_destination_projection_valid =
				!destination_projection.x == Math_INF &&
				!destination_projection.y == Math_INF;

		switch (p_origin_surface->get_side()) {
			case Surface::Side::FLOOR:
				if (is_destination_projection_valid &&
					destination_projection.y < origin_projection.y)
					return destination_projection;
				else
					return origin_projection;
			case Surface::Side::LEFT_WALL:
				if (is_destination_projection_valid &&
					destination_projection.x > origin_projection.x)
					return destination_projection;
				else
					return origin_projection;
			case Surface::Side::RIGHT_WALL:
				if (is_destination_projection_valid &&
					destination_projection.x < origin_projection.x)
					return destination_projection;
				else
					return origin_projection;
			case Surface::Side::CEILING:
				if (is_destination_projection_valid &&
					destination_projection.y > origin_projection.y)
					return destination_projection;
				else
					return origin_projection;
			default:
				ENSURE(false,
					   "SurfacerGeometry::project_shape_onto_convex_corner_"
					   "preserving_tangent_position: Invalid surface side");
				break;
		}
	} else {
		ENSURE(false, "Not implemented yet.");
	}

	return projection;
}
double SurfacerGeometry::
		calculate_displacement_x_for_vertical_distance_past_edge(
				double p_distance_past_edge,
				bool p_is_left_wall,
				const Ref<RotatedShape> &p_collider) {
	if (Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr())) {
		const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr());
		if (p_distance_past_edge >= circle->get_radius()) {
			return 0.0;
		} else {
			return calculate_circular_displacement_x_for_vertical_distance_past_edge(
					p_distance_past_edge, circle->get_radius(), p_is_left_wall);
		}
	} else if (Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr())) {
		const CapsuleShape2D *capsule =
				Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			double half_height_offset = p_is_left_wall
					? capsule->get_height() / 2.0
					: -capsule->get_height() / 2.0;
			return calculate_circular_displacement_x_for_vertical_distance_past_edge(
						   p_distance_past_edge, capsule->get_radius(),
						   p_is_left_wall) +
					half_height_offset;
		} else {
			double adjusted_distance =
					p_distance_past_edge - capsule->get_height() / 2.0;
			if (adjusted_distance <= 0) {
				return p_is_left_wall ? capsule->get_radius()
									  : -capsule->get_radius();
			} else {
				return calculate_circular_displacement_x_for_vertical_distance_past_edge(
						adjusted_distance, capsule->get_radius(),
						p_is_left_wall);
			}
		}
	} else if (Object::cast_to<RectangleShape2D>(
					   p_collider->get_shape().ptr())) {
		const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
				p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			return p_is_left_wall ? rect->get_size().y / 2.0f
								  : -rect->get_size().y / 2.0f;
		} else {
			return p_is_left_wall ? rect->get_size().x / 2.0f
								  : -rect->get_size().x / 2.0f;
		}
	} else {
		ENSURE(false,
			   "Invalid Shape2D provided for "
			   "calculate_displacement_x_for_vertical_distance_past_edge. "
			   "Supported: CircleShape2D, CapsuleShape2D, RectangleShape2D.");
		return Math_INF;
	}
}

double SurfacerGeometry::
		calculate_circular_displacement_x_for_vertical_distance_past_edge(
				double p_distance_past_edge,
				double p_radius,
				bool p_is_left_wall) {
	double distance_x = (p_distance_past_edge >= p_radius)
			? 0.0
			: sqrt(p_radius * p_radius -
				   p_distance_past_edge * p_distance_past_edge);
	return p_is_left_wall ? distance_x : -distance_x;
}

double SurfacerGeometry::
		calculate_displacement_y_for_horizontal_distance_past_edge(
				double p_distance_past_edge,
				bool p_is_floor,
				const Ref<RotatedShape> &p_collider) {
	if (Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr())) {
		const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr());
		if (p_distance_past_edge >= circle->get_radius()) {
			return 0.0;
		} else {
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
					p_distance_past_edge, circle->get_radius(), p_is_floor);
		}
	} else if (Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr())) {
		const CapsuleShape2D *capsule =
				Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			double adjusted_distance =
					p_distance_past_edge - capsule->get_height() * 0.5;
			if (adjusted_distance <= 0) {
				return p_is_floor ? -capsule->get_radius()
								  : capsule->get_radius();
			} else {
				return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						adjusted_distance, capsule->get_radius(), p_is_floor);
			}
		} else {
			double half_height_offset = p_is_floor
					? capsule->get_height() / 2.0
					: -capsule->get_height() / 2.0;
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						   p_distance_past_edge, capsule->get_radius(),
						   p_is_floor) +
					half_height_offset;
		}
	} else if (Object::cast_to<RectangleShape2D>(
					   p_collider->get_shape().ptr())) {
		const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
				p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			return p_is_floor ? -rect->get_size().x / 2.0f
							  : rect->get_size().x / 2.0f;
		} else {
			return p_is_floor ? -rect->get_size().y / 2.0f
							  : rect->get_size().y / 2.0f;
		}
	} else {
		ENSURE(false,
			   "Invalid Shape2D provided for "
			   "calculate_displacement_y_for_horizontal_distance_past_edge. "
			   "Supported: CircleShape2D, CapsuleShape2D, RectangleShape2D.");
		return Math_INF;
	}
}
double SurfacerGeometry::
		calculate_displacement_y_for_horizontal_distance_past_edge(
				double p_distance_past_edge,
				bool p_is_floor,
				const Ref<RotatedShape> &p_collider) {
	if (Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr())) {
		const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr());
		if (p_distance_past_edge >= circle->get_radius()) {
			return 0.0;
		} else {
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
					p_distance_past_edge, circle->get_radius(), p_is_floor);
		}
	} else if (Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr())) {
		const CapsuleShape2D *capsule =
				Object::cast_to<CapsuleShape2D>(p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			double adjusted_distance =
					p_distance_past_edge - capsule->get_height() * 0.5;
			if (adjusted_distance <= 0) {
				return p_is_floor ? -capsule->get_radius()
								  : capsule->get_radius();
			} else {
				return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						adjusted_distance, capsule->get_radius(), p_is_floor);
			}
		} else {
			double half_height_offset = p_is_floor
					? capsule->get_height() / 2.0
					: -capsule->get_height() / 2.0;
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						   p_distance_past_edge, capsule->get_radius(),
						   p_is_floor) +
					half_height_offset;
		}
	} else if (Object::cast_to<RectangleShape2D>(
					   p_collider->get_shape().ptr())) {
		const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
				p_collider->get_shape().ptr());
		if (p_collider->get_is_rotated_90_degrees()) {
			return p_is_floor ? -rect->get_size().x / 2.0f
							  : rect->get_size().x / 2.0f;
		} else {
			return p_is_floor ? -rect->get_size().y / 2.0f
							  : rect->get_size().y / 2.0f;
		}
	} else {
		ENSURE(false,
			   "Invalid Shape2D provided for "
			   "calculate_displacement_y_for_horizontal_distance_past_edge. "
			   "Supported: CircleShape2D, CapsuleShape2D, RectangleShape2D.");
		return Math_INF;
	}
}

double SurfacerGeometry::
		calculate_circular_displacement_y_for_horizontal_distance_past_edge(
				double p_distance_past_edge,
				double p_radius,
				bool p_is_floor) {
	double distance_y = (p_distance_past_edge >= p_radius)
			? 0.0
			: sqrt(p_radius * p_radius -
				   p_distance_past_edge * p_distance_past_edge);
	return p_is_floor ? -distance_y : distance_y;
}
void SurfacerGeometry::_bind_methods() {
	// Static methods
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_point_onto_surface", "p_point", "p_surface",
					"p_side_override"),
			&SurfacerGeometry::project_point_onto_surface,
			DEFVAL(Surface::Side::UNKNOWN_SIDE));
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD("get_surface_normal_at_point", "p_surface", "p_point"),
			&SurfacerGeometry::get_surface_normal_at_point);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD("get_segment_normal", "p_segment_start", "p_segment_end"),
			&SurfacerGeometry::get_segment_normal);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_shape_onto_surface", "p_shape_position", "p_shape",
					"p_surface", "p_uses_end_segment_if_outside_bounds",
					"p_side_override"),
			&SurfacerGeometry::project_shape_onto_surface, DEFVAL(true),
			DEFVAL(Surface::Side::UNKNOWN_SIDE));
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_shape_onto_segment", "p_shape_position", "p_shape",
					"p_surface_side", "p_segment_start", "p_segment_end"),
			&SurfacerGeometry::project_shape_onto_segment);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_shape_onto_segment_and_away_from_concave_"
					"neighbors",
					"p_shape_position", "p_shape", "p_surface",
					"p_uses_end_segment_if_outside_bounds",
					"p_rejects_non_overlapping_results", "p_side_override"),
			&SurfacerGeometry::
					project_shape_onto_segment_and_away_from_concave_neighbors,
			DEFVAL(true), DEFVAL(true), DEFVAL(Surface::Side::UNKNOWN_SIDE));
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_concave_neighbor_projection_side_override",
					"p_surface", "p_is_clockwise"),
			&SurfacerGeometry::get_concave_neighbor_projection_side_override);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_away_from_concave_neighbor", "p_position",
					"p_neighbor", "p_neighbor_normal_side_override", "p_shape"),
			&SurfacerGeometry::project_away_from_concave_neighbor);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_closest_point_on_surface_to_shape", "p_surface",
					"p_shape_position", "p_shape"),
			&SurfacerGeometry::get_closest_point_on_surface_to_shape);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_furthest_shape_boundary_point_in_direction",
					"p_shape_position", "p_shape", "p_direction"),
			&SurfacerGeometry::get_furthest_shape_boundary_point_in_direction);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"nudge_point_along_axially_aligned_segment_toward_shape_"
					"center",
					"p_point", "p_surface", "p_shape_position"),
			&SurfacerGeometry::
					nudge_point_along_axially_aligned_segment_toward_shape_center);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"do_surface_and_rectangle_intersect", "p_surface",
					"p_rectangle_min", "p_rectangle_max"),
			&SurfacerGeometry::do_surface_and_rectangle_intersect);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"check_for_shape_to_rect_intersection", "p_shape_position",
					"p_shape", "p_rect", "p_epsilon"),
			&SurfacerGeometry::check_for_shape_to_rect_intersection,
			DEFVAL(0.0));
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"check_for_shape_to_surface_overlap", "p_shape_position",
					"p_shape", "p_surface", "p_epsilon"),
			&SurfacerGeometry::check_for_shape_to_surface_overlap,
			DEFVAL(shape_overlap_with_concave_surface_epsilon));

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_surface_segment_at_point", "r_segment_points_result",
					"p_surface", "p_point",
					"p_uses_end_segment_if_outside_bounds"),
			&SurfacerGeometry::get_surface_segment_at_point);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_vertices_around_range", "p_surface", "p_range_min_x",
					"p_range_max_x", "p_range_min_y", "p_range_max_y"),
			&SurfacerGeometry::get_vertices_around_range);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"are_position_wrappers_equal_with_epsilon", "p_a", "p_b",
					"p_epsilon"),
			&SurfacerGeometry::are_position_wrappers_equal_with_epsilon,
			DEFVAL(1e-6));
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD("get_surface_side_for_normal", "p_normal"),
			&SurfacerGeometry::get_surface_side_for_normal);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"project_shape_onto_convex_corner_preserving_tangent_"
					"position",
					"p_shape_position", "p_shape", "p_origin_surface",
					"p_destination_surface"),
			&SurfacerGeometry::
					project_shape_onto_convex_corner_preserving_tangent_position);

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"calculate_displacement_x_for_vertical_distance_past_edge",
					"p_distance_past_edge", "p_is_left_wall", "p_collider"),
			&SurfacerGeometry::
					calculate_displacement_x_for_vertical_distance_past_edge);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"calculate_circular_displacement_x_for_vertical_distance_"
					"past_edge",
					"p_distance_past_edge", "p_radius", "p_is_left_wall"),
			&SurfacerGeometry::
					calculate_circular_displacement_x_for_vertical_distance_past_edge);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"calculate_displacement_y_for_horizontal_distance_past_"
					"edge",
					"p_distance_past_edge", "p_is_floor", "p_collider"),
			&SurfacerGeometry::
					calculate_displacement_y_for_horizontal_distance_past_edge);
	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"calculate_circular_displacement_y_for_horizontal_distance_"
					"past_edge",
					"p_distance_past_edge", "p_radius", "p_is_floor"),
			&SurfacerGeometry::
					calculate_circular_displacement_y_for_horizontal_distance_past_edge);
}
