#include "surfacer_geometry.h"

#include "scaffolder/internal_utils.h"
#include "surfacer.h"

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>

using namespace godot;

Vector2 SurfacerGeometry::project_point_onto_surface(
		const Vector2 &p_point,
		const Ref<Surface> &p_surface,
		Surface::Side p_side_override) {
	const Surface::Side surface_side =
			(p_side_override == Surface::Side::UNKNOWN_SIDE)
			? p_surface->get_side()
			: p_side_override;
	const Vector2 start_vertex = p_surface->get_first_point();
	const Vector2 end_vertex = p_surface->get_last_point();

	// Check whether the point lies outside the surface boundaries.
	switch (surface_side) {
		case Surface::Side::FLOOR: {
			if (p_point.x <= start_vertex.x) {
				return start_vertex;
			}
			if (p_point.x >= end_vertex.x) {
				return end_vertex;
			}
			break;
		}
		case Surface::Side::CEILING: {
			if (p_point.x >= start_vertex.x) {
				return start_vertex;
			}
			if (p_point.x <= end_vertex.x) {
				return end_vertex;
			}
			break;
		}
		case Surface::Side::LEFT_WALL: {
			if (p_point.y <= start_vertex.y) {
				return start_vertex;
			}
			if (p_point.y >= end_vertex.y) {
				return end_vertex;
			}
			break;
		}
		case Surface::Side::RIGHT_WALL: {
			if (p_point.y >= start_vertex.y) {
				return start_vertex;
			}
			if (p_point.y <= end_vertex.y) {
				return end_vertex;
			}
			break;
		}
		default: {
			ENSURE(false,
				   "SurfacerGeometry::project_point_onto_surface: Invalid "
				   "surface side");
			break;
		}
	}

	// Target lies within the surface boundaries.

	// Calculate a segment that represents the axially-aligned
	// surface-side-normal.
	Vector2 segment_a;
	Vector2 segment_b;
	if (surface_side == Surface::Side::FLOOR ||
		surface_side == Surface::Side::CEILING) {
		segment_a = Vector2(
				p_point.x, p_surface->get_bounding_box().position.y - 10.0f);
		segment_b = Vector2(
				p_point.x, p_surface->get_bounding_box().get_end().y + 10.0f);
	} else {
		segment_a = Vector2(
				p_surface->get_bounding_box().position.x, p_point.y - 10.0f);
		segment_b = Vector2(
				p_surface->get_bounding_box().get_end().x, p_point.y + 10.0f);
	}

	Vector2 intersection = Geometry::get_intersection_of_segment_and_polyline(
			segment_a, segment_b, p_surface->get_vertices());
	ENSURE_SIMPLE(Geometry::is_valid(intersection));
	return intersection;
}

Vector2 SurfacerGeometry::get_surface_normal_at_point(
		const Ref<Surface> &p_surface,
		const Vector2 &p_point) {
	if (!IS_VALID_REF(p_surface)) {
		return vector2_invalid;
	}
	if (p_surface->get_vertices().size() <= 1) {
		return p_surface->get_normal();
	}

	PackedVector2Array segment_points_result =
			get_surface_segment_at_point(p_surface, p_point, true);
	const Vector2 segment_start = segment_points_result[0];
	const Vector2 segment_end = segment_points_result[1];
	return get_segment_normal(segment_start, segment_end);
}

Vector2 SurfacerGeometry::get_segment_normal(
		const Vector2 &p_segment_start,
		const Vector2 &p_segment_end) {
	const Vector2 displacement = p_segment_end - p_segment_start;
	// Displacement is clockwise around convex surfaces, so the normal is the
	// counter-clockwise perpendicular direction from the displacement.
	const Vector2 perpendicular(displacement.y, -displacement.x);
	return perpendicular.normalized();
}

Vector2 SurfacerGeometry::project_shape_onto_surface(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Ref<Surface> &p_surface,
		bool p_uses_end_segment_if_outside_bounds,
		Surface::Side p_side_override) {
	// TODO: Should this also account for the next segment on a neighbor
	// surface?

	const Surface::Side surface_side =
			(p_side_override == Surface::Side::UNKNOWN_SIDE)
			? p_surface->get_side()
			: p_side_override;

	const bool is_horizontal_surface = surface_side == Surface::Side::FLOOR ||
			surface_side == Surface::Side::CEILING;

	if (!IS_VALID_REF(p_surface)) {
		return vector2_invalid;
	}

	if ((is_horizontal_surface && Math::is_inf(p_shape_position.x)) ||
		(!is_horizontal_surface && Math::is_inf(p_shape_position.y))) {
		return vector2_invalid;
	}

	if (!IS_VALID_REF(p_shape)) {
		return project_point_onto_surface(
				p_shape_position, p_surface, surface_side);
	}

	// Allow callers to provide an infinite coordinate for the axis that we're
	// projecting along.
	Vector2 shape_position = p_shape_position;
	if (is_horizontal_surface && Math::is_inf(shape_position.y)) {
		shape_position.y = 0.0;
	}
	if (!is_horizontal_surface && Math::is_inf(shape_position.x)) {
		shape_position.x = 0.0;
	}

	const Vector2 half_width_height = p_shape->get_half_width_height();
	const double shape_min_x = shape_position.x - half_width_height.x;
	const double shape_max_x = shape_position.x + half_width_height.x;
	const double shape_min_y = shape_position.y - half_width_height.y;
	const double shape_max_y = shape_position.y + half_width_height.y;

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

	if (p_surface->get_vertices().size() <= 1) {
		return project_shape_onto_segment(
				shape_position, p_shape, surface_side,
				p_surface->get_vertices()[0], p_surface->get_vertices()[0]);
	}

	const Array vertices_to_check = get_vertices_around_range(
			p_surface, shape_min_x, shape_max_x, shape_min_y, shape_max_y);

	// Use whichever segment-projection places the shape further away from the
	// surface.
	Vector2 furthest_projection = vector2_invalid;
	switch (surface_side) {
		case Surface::Side::FLOOR: {
			furthest_projection = vector2_invalid;
			for (int i = 0; i < vertices_to_check.size() - 1; ++i) {
				Vector2 projection = project_shape_onto_segment(
						shape_position, p_shape, surface_side,
						(Vector2)vertices_to_check[i],
						(Vector2)vertices_to_check[i + 1]);
				if (projection.y < furthest_projection.y) {
					furthest_projection = std::move(projection);
				}
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
				if (projection.x > furthest_projection.x) {
					furthest_projection = std::move(projection);
				}
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
				if (projection.x < furthest_projection.x) {
					furthest_projection = std::move(projection);
				}
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
				if (projection.y > furthest_projection.y) {
					furthest_projection = std::move(projection);
				}
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
	const Vector2 surface_normal =
			Surface::get_normal_from_side(p_surface_side);

	if (!IS_VALID_REF(p_shape)) {
		return Geometry::get_intersection_of_segments(
				p_shape_position - surface_normal * 100000.0,
				p_shape_position + surface_normal * 100000.0, p_segment_start,
				p_segment_end);
	}

	Vector2 shape_position = p_shape_position;
	Vector2 half_width_height = p_shape->get_half_width_height();

	const Vector2 segment_normal = (p_segment_end == p_segment_start)
			? surface_normal
			: get_segment_normal(p_segment_start, p_segment_end);

	Vector2 leftward_segment_point = vector2_invalid;
	Vector2 rightward_segment_point = vector2_invalid;
	Vector2 upper_segment_point = vector2_invalid;
	Vector2 lower_segment_point = vector2_invalid;

	switch (p_surface_side) {
		case Surface::Side::FLOOR: {
			leftward_segment_point = p_segment_start;
			rightward_segment_point = p_segment_end;
			break;
		}
		case Surface::Side::LEFT_WALL: {
			upper_segment_point = p_segment_start;
			lower_segment_point = p_segment_end;
			break;
		}
		case Surface::Side::RIGHT_WALL: {
			upper_segment_point = p_segment_end;
			lower_segment_point = p_segment_start;
			break;
		}
		case Surface::Side::CEILING: {
			leftward_segment_point = p_segment_end;
			rightward_segment_point = p_segment_start;
			break;
		}
		default: {
			ENSURE(false,
				   "SurfacerGeometry::project_shape_onto_segment: Invalid "
				   "surface side");
		}
	}

	const Vector2 segment_tangent =
			Geometry::get_perpendicular_vector(segment_normal);
	const double segment_slope = (segment_tangent.x != 0.0)
			? segment_tangent.y / segment_tangent.x
			: Math_INF;

	bool is_shape_effectively_circle = p_shape->is_class("CircleShape2D");
	const bool is_shape_capsule = p_shape->is_class("CapsuleShape2D");
	bool is_shape_effectively_rectangle = p_shape->is_class("RectangleShape2D");

	ENSURE_SIMPLE(
			is_shape_effectively_circle || is_shape_capsule ||
			is_shape_effectively_rectangle);

	double projection_displacement_x = Math_INF;
	double projection_displacement_y = Math_INF;

	if (is_shape_capsule) {
		// All of our capsule-projection cases involve modifying parameters and
		// redirecting to either the circle-handling branch or the
		// rectangle-handling branch.

		const CapsuleShape2D *capsule =
				Object::cast_to<CapsuleShape2D>(p_shape.ptr());
		const double radius = capsule->get_radius();
		const double height = capsule->get_height();
		const double half_height = height * 0.5;

		const bool is_horizontal_surface =
				(p_surface_side == Surface::Side::FLOOR ||
				 p_surface_side == Surface::Side::CEILING);
		const Vector2 capsule_center_original = shape_position;

		Vector2 leftward_capsule_end_center = vector2_invalid;
		Vector2 rightward_capsule_end_center = vector2_invalid;
		Vector2 upper_capsule_end_center = vector2_invalid;
		Vector2 lower_capsule_end_center = vector2_invalid;

		if (p_shape->get_is_rotated_90_degrees()) {
			leftward_capsule_end_center =
					capsule_center_original - Vector2(half_height, 0.0);
			rightward_capsule_end_center =
					capsule_center_original + Vector2(half_height, 0.0);
		} else {
			upper_capsule_end_center =
					capsule_center_original - Vector2(0.0, half_height);
			lower_capsule_end_center =
					capsule_center_original + Vector2(0.0, half_height);
		}

		const Vector2 circle_half_width_height = Vector2(radius, radius);
		const Vector2 rectangle_half_width_height =
				p_shape->get_is_rotated_90_degrees()
				? Vector2(half_height, radius)
				: Vector2(radius, half_height);

		if (p_shape->get_is_rotated_90_degrees() != is_horizontal_surface ||
			height == 0.0) {
			// If the round-end of the capsule is facing the surface, then we
			// can treat it the same as a circle.
			is_shape_effectively_circle = true;
			half_width_height = circle_half_width_height;
			switch (p_surface_side) {
				case Surface::Side::FLOOR: {
					shape_position = lower_capsule_end_center;
					break;
				}
				case Surface::Side::LEFT_WALL: {
					shape_position = leftward_capsule_end_center;
					break;
				}
				case Surface::Side::RIGHT_WALL: {
					shape_position = rightward_capsule_end_center;
					break;
				}
				case Surface::Side::CEILING: {
					shape_position = upper_capsule_end_center;
					break;
				}
				default: {
					ENSURE(false,
						   "SurfacerGeometry.project_shape_onto_segment: "
						   "Invalid surface side in capsule logic");
					break;
				}
			}
		} else {
			// The flat-side of the capsule is facing the surface.
			// - In this case, we can assume that the segment will only ever
			//   contact either round end, unless the segment ends between the
			//   capsule-end centers.
			// - We can handle the former case by modifying our parameters and
			//   redirecting to our circle-handling branch.
			// - We can handle the latter case by modifying our parameters and
			//   redirecting to our rectangle-handling branch.

			switch (p_surface_side) {
				case Surface::Side::FLOOR:
				case Surface::Side::CEILING: {
					if (segment_normal.x <= 0) {
						// - Either is floor, and is level or slopes up to the
						//   right.
						// - Or is ceiling, and is level or slopes up to the
						//   left.
						if (rightward_segment_point.x <=
							leftward_capsule_end_center.x) {
							// We can treat this as a circle-projection with the
							// left-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = leftward_capsule_end_center;
							half_width_height = circle_half_width_height;
						} else if (
								rightward_segment_point.x <
								rightward_capsule_end_center.x) {
							// We can treat this as a rectangle-projection with
							// the center of the capsule.
							is_shape_effectively_rectangle = true;
							shape_position = capsule_center_original;
							half_width_height = rectangle_half_width_height;
						} else {
							// We can treat this as a circle-projection with the
							// right-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = rightward_capsule_end_center;
							half_width_height = circle_half_width_height;
						}
					} else {
						// - Either is floor, and slopes up to the left.
						// - Or is ceiling, and slopes up to the right.
						if (leftward_segment_point.x >=
							rightward_capsule_end_center.x) {
							// We can treat this as a circle-projection with the
							// right-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = rightward_capsule_end_center;
							half_width_height = circle_half_width_height;
						} else if (
								leftward_segment_point.x >
								leftward_capsule_end_center.x) {
							// We can treat this as a rectangle-projection with
							// the center of the capsule.
							is_shape_effectively_rectangle = true;
							shape_position = capsule_center_original;
							half_width_height = rectangle_half_width_height;
						} else {
							// We can treat this as a circle-projection with the
							// left-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = leftward_capsule_end_center;
							half_width_height = circle_half_width_height;
						}
					}
					break;
				}

				case Surface::Side::LEFT_WALL:
				case Surface::Side::RIGHT_WALL: {
					if (segment_normal.y <= 0) {
						// - Either is left-wall, and is level or slopes up to
						// the left.
						// - Or is right-wall, and is level or slopes up to the
						// right.
						if (lower_segment_point.y <=
							upper_capsule_end_center.y) {
							// We can treat this as a circle-projection with the
							// upper-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = upper_capsule_end_center;
							half_width_height = circle_half_width_height;
						} else if (
								lower_segment_point.y <
								lower_capsule_end_center.y) {
							// We can treat this as a rectangle-projection with
							// the center of the capsule.
							is_shape_effectively_rectangle = true;
							shape_position = capsule_center_original;
							half_width_height = rectangle_half_width_height;
						} else {
							// We can treat this as a circle-projection with the
							// lower-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = lower_capsule_end_center;
							half_width_height = circle_half_width_height;
						}
					} else {
						// - Either is left-wall, and slopes up to the right.
						// - Or is right-wall, and slopes up to the left.
						if (upper_segment_point.y >=
							lower_capsule_end_center.y) {
							// We can treat this as a circle-projection with the
							// lower-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = lower_capsule_end_center;
							half_width_height = circle_half_width_height;
						} else if (
								upper_segment_point.y >
								upper_capsule_end_center.y) {
							// We can treat this as a rectangle-projection with
							// the center of the capsule.
							is_shape_effectively_rectangle = true;
							shape_position = capsule_center_original;
							half_width_height = rectangle_half_width_height;
						} else {
							// We can treat this as a circle-projection with the
							// upper-end of the capsule.
							is_shape_effectively_circle = true;
							shape_position = upper_capsule_end_center;
							half_width_height = circle_half_width_height;
						}
					}
					break;
				}

				default: {
					ENSURE(false,
						   "SurfacerGeometry.project_shape_onto_segment: "
						   "Invalid surface side in capsule logic 2");
					break;
				}
			}
		}
	}

	const double shape_min_x = shape_position.x - half_width_height.x;
	const double shape_max_x = shape_position.x + half_width_height.x;
	const double shape_min_y = shape_position.y - half_width_height.y;
	const double shape_max_y = shape_position.y + half_width_height.y;

	if (is_shape_effectively_circle) {
		// - There are three possible contact points to consider:
		//   - Either end of the segment, but only if the circle extends beyond
		//     that end.
		//   - The point along the circumference of the circle in the direction
		//     of the segment-normal from the circle center.
		// - We use the closest valid contact point.

		const float radius = Geometry::get_radius(p_shape);

		switch (p_surface_side) {
			case Surface::Side::FLOOR:
			case Surface::Side::CEILING: {
				if (shape_max_x < leftward_segment_point.x ||
					shape_min_x > rightward_segment_point.x) {
					// The shape is outside the bounds of the segment.
					return vector2_invalid;
				}

				const Vector2 segment_cast_start =
						shape_position - segment_normal * radius * 1.1;
				const Vector2 segment_cast_end = shape_position;
				const Vector2 shape_point_along_normal =
						Geometry::get_intersection_of_segment_and_circle(
								segment_cast_start, segment_cast_end,
								shape_position, radius, true);

				projection_displacement_x = 0.0;
				projection_displacement_y =
						(p_surface_side == Surface::Side::FLOOR) ? Math_INF
																 : -Math_INF;

				if (shape_min_x < leftward_segment_point.x) {
					// The shape overlaps with the segment left side.
					Vector2 segment_cast_start =
							shape_position - surface_normal * radius * 1.1;
					segment_cast_start.x = leftward_segment_point.x;
					Vector2 segment_cast_end = shape_position;
					segment_cast_end.x = leftward_segment_point.x;
					const Vector2 possible_contact_point =
							Geometry::get_intersection_of_segment_and_circle(
									segment_cast_start, segment_cast_end,
									shape_position, radius, true);
					const double possible_contact_point_displacement_y =
							leftward_segment_point.y - possible_contact_point.y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);
				}

				if (shape_max_x > rightward_segment_point.x) {
					// The shape overlaps with the segment right side.
					Vector2 segment_cast_start =
							shape_position - surface_normal * radius * 1.1;
					segment_cast_start.x = rightward_segment_point.x;
					Vector2 segment_cast_end = shape_position;
					segment_cast_end.x = rightward_segment_point.x;
					const Vector2 possible_contact_point =
							Geometry::get_intersection_of_segment_and_circle(
									segment_cast_start, segment_cast_end,
									shape_position, radius, true);
					const double possible_contact_point_displacement_y =
							rightward_segment_point.y -
							possible_contact_point.y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);
				}

				if (shape_point_along_normal.x > leftward_segment_point.x &&
					shape_point_along_normal.x < rightward_segment_point.x) {
					// The point along the shape that would contact the line
					// through the segment lies within the bounds of the
					// segment.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   y2 = m(x2-x1) + y1
					const double segment_y_at_shape_point_along_normal =
							segment_slope *
									(shape_point_along_normal.x -
									 leftward_segment_point.x) +
							leftward_segment_point.y;
					const double possible_contact_point_displacement_y =
							segment_y_at_shape_point_along_normal -
							shape_point_along_normal.y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);
				}

				break;
			}

			case Surface::Side::LEFT_WALL:
			case Surface::Side::RIGHT_WALL: {
				if (shape_max_y < upper_segment_point.y ||
					shape_min_y > lower_segment_point.y) {
					// The shape is outside the bounds of the segment.
					return vector2_invalid;
				}

				const Vector2 segment_cast_start =
						shape_position - segment_normal * radius * 1.1;
				const Vector2 segment_cast_end = shape_position;
				const Vector2 shape_point_along_normal =
						Geometry::get_intersection_of_segment_and_circle(
								segment_cast_start, segment_cast_end,
								shape_position, radius, true);

				projection_displacement_x =
						(p_surface_side == Surface::Side::LEFT_WALL) ? -Math_INF
																	 : Math_INF;
				projection_displacement_y = 0.0;

				if (shape_min_y < upper_segment_point.y) {
					// The shape overlaps with the segment top side.
					Vector2 segment_cast_start =
							shape_position - surface_normal * radius * 1.1;
					segment_cast_start.y = upper_segment_point.y;
					Vector2 segment_cast_end = shape_position;
					segment_cast_end.y = upper_segment_point.y;
					const Vector2 possible_contact_point =
							Geometry::get_intersection_of_segment_and_circle(
									segment_cast_start, segment_cast_end,
									shape_position, radius, true);
					const double possible_contact_point_displacement_x =
							upper_segment_point.x - possible_contact_point.x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);
				}

				if (shape_max_y > lower_segment_point.y) {
					// The shape overlaps with the segment bottom side.
					Vector2 segment_cast_start =
							shape_position - surface_normal * radius * 1.1;
					segment_cast_start.y = lower_segment_point.y;
					Vector2 segment_cast_end = shape_position;
					segment_cast_end.y = lower_segment_point.y;
					const Vector2 possible_contact_point =
							Geometry::get_intersection_of_segment_and_circle(
									segment_cast_start, segment_cast_end,
									shape_position, radius, true);
					const double possible_contact_point_displacement_x =
							lower_segment_point.x - possible_contact_point.x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);
				}

				if (shape_point_along_normal.y > upper_segment_point.y &&
					shape_point_along_normal.y < lower_segment_point.y) {
					// The point along the shape that would contact the line
					// through the segment, lies within the bounds of the
					// segment.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   x2 = (y2-y1)/m + x1
					const double segment_x_at_shape_point_along_normal =
							(shape_point_along_normal.y -
							 lower_segment_point.y) /
									segment_slope +
							lower_segment_point.x;
					const double possible_contact_point_displacement_x =
							segment_x_at_shape_point_along_normal -
							shape_point_along_normal.x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);
				}

				break;
			}

			default: {
				ENSURE(false, "SurfacerGeometry.project_shape_onto_segment");
			}
		}
	}

	if (is_shape_effectively_rectangle) {
		// - There are four possible contact points to consider:
		//   - Either end of the segment, but only if the rectangle extends
		//     beyond that end.
		//   - Either of the corners of the rectangle that face the surface, but
		//     only if the segment extends beyond that corner.
		// - We use the closest valid contact point.

		switch (p_surface_side) {
			case Surface::Side::FLOOR:
			case Surface::Side::CEILING: {
				if (shape_max_x < leftward_segment_point.x ||
					shape_min_x > rightward_segment_point.x) {
					// The shape is outside the bounds of the segment.
					return vector2_invalid;
				}

				const double shape_close_end_y =
						(p_surface_side == Surface::Side::FLOOR) ? shape_max_y
																 : shape_min_y;
				projection_displacement_x = 0.0;
				projection_displacement_y =
						(p_surface_side == Surface::Side::FLOOR) ? Math_INF
																 : -Math_INF;

				if (shape_min_x < leftward_segment_point.x) {
					// The shape overlaps with the segment left side.
					const double possible_contact_point_displacement_y =
							leftward_segment_point.y - shape_close_end_y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);

				} else if (shape_max_x > rightward_segment_point.x) {
					// The shape overlaps with the segment right side.
					const double possible_contact_point_displacement_y =
							rightward_segment_point.y - shape_close_end_y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);

				} else if (shape_min_x > leftward_segment_point.x) {
					// The segment overlaps with the shape left side.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   y2 = m(x2-x1) + y1
					const double segment_y_at_shape_left_side = segment_slope *
									(shape_min_x - leftward_segment_point.x) +
							leftward_segment_point.y;
					const double possible_contact_point_displacement_y =
							segment_y_at_shape_left_side - shape_close_end_y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);

				} else if (shape_max_x < rightward_segment_point.x) {
					// The segment overlaps with the shape right side.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   y2 = m(x2-x1) + y1
					const double segment_y_at_shape_right_side = segment_slope *
									(shape_max_x - leftward_segment_point.x) +
							leftward_segment_point.y;
					const double possible_contact_point_displacement_y =
							segment_y_at_shape_right_side - shape_close_end_y;
					projection_displacement_y =
							(p_surface_side == Surface::Side::FLOOR)
							? MIN(projection_displacement_y,
								  possible_contact_point_displacement_y)
							: MAX(projection_displacement_y,
								  possible_contact_point_displacement_y);
				} else {
					ENSURE(false,
						   "SurfacerGeometry.project_shape_onto_segment");
				}

				break;
			}

			case Surface::Side::LEFT_WALL:
			case Surface::Side::RIGHT_WALL: {
				if (shape_max_y < upper_segment_point.y ||
					shape_min_y > lower_segment_point.y) {
					// The shape is outside the bounds of the segment.
					return vector2_invalid;
				}

				const double shape_close_end_x =
						(p_surface_side == Surface::Side::RIGHT_WALL)
						? shape_max_x
						: shape_min_x;
				projection_displacement_x =
						(p_surface_side == Surface::Side::LEFT_WALL) ? -Math_INF
																	 : Math_INF;
				projection_displacement_y = 0.0;

				if (shape_min_y < upper_segment_point.y) {
					// The shape overlaps with the segment top side.
					const double possible_contact_point_displacement_x =
							upper_segment_point.x - shape_close_end_x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);

				} else if (shape_max_y > lower_segment_point.y) {
					// The shape overlaps with the segment bottom side.
					const double possible_contact_point_displacement_x =
							lower_segment_point.x - shape_close_end_x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);

				} else if (shape_min_y > upper_segment_point.y) {
					// The segment overlaps with the shape top side.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   x2 = (y2-y1)/m + x1
					const double segment_x_at_shape_upper_side =
							(shape_min_y - lower_segment_point.y) /
									segment_slope +
							lower_segment_point.x;
					const double possible_contact_point_displacement_x =
							segment_x_at_shape_upper_side - shape_close_end_x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);

				} else if (shape_max_y < lower_segment_point.y) {
					// The segment overlaps with the shape bottom side.

					// Slope formula:
					//   m = (y2-y1)/(x2-x1)
					//   x2 = (y2-y1)/m + x1
					const double segment_x_at_shape_lower_side =
							(shape_max_y - lower_segment_point.y) /
									segment_slope +
							lower_segment_point.x;
					const double possible_contact_point_displacement_x =
							segment_x_at_shape_lower_side - shape_close_end_x;
					projection_displacement_x =
							(p_surface_side == Surface::Side::LEFT_WALL)
							? MAX(projection_displacement_x,
								  possible_contact_point_displacement_x)
							: MIN(projection_displacement_x,
								  possible_contact_point_displacement_x);

				} else {
					ENSURE(false,
						   "SurfacerGeometry.project_shape_onto_segment");
				}

				break;
			}

			default: {
				ENSURE(false, "SurfacerGeometry.project_shape_onto_segment");
			}
		}
	}

	if (Math::is_inf(projection_displacement_x) ||
		Math::is_inf(projection_displacement_y)) {
		return vector2_invalid;
	}

	return p_shape_position +
			Vector2(projection_displacement_x, projection_displacement_y);
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
	if (!Geometry::is_valid(projection)) {
		return vector2_invalid;
	}

	const Ref<Surface> cw_neighbor = p_surface->get_clockwise_neighbor();
	const bool is_cw_neighbor_concave =
			cw_neighbor == p_surface->get_clockwise_concave_neighbor();
	if (is_cw_neighbor_concave) {
		const Surface::Side cw_neighbor_normal_side_override =
				get_concave_neighbor_projection_side_override(p_surface, true);
		const Vector2 neighbor_projection = project_away_from_concave_neighbor(
				projection, cw_neighbor, cw_neighbor_normal_side_override,
				p_shape);
		if (Geometry::is_valid(neighbor_projection)) {
			projection = neighbor_projection;
			if (p_rejects_non_overlapping_results &&
				!check_for_shape_to_surface_overlap(
						projection, p_shape, p_surface)) {
				return vector2_invalid;
			}
		}
	}

	const Ref<Surface> ccw_neighbor =
			p_surface->get_counter_clockwise_neighbor();
	const bool is_ccw_neighbor_concave =
			ccw_neighbor == p_surface->get_counter_clockwise_concave_neighbor();
	if (is_ccw_neighbor_concave) {
		const Surface::Side ccw_neighbor_normal_side_override =
				get_concave_neighbor_projection_side_override(p_surface, false);
		const Vector2 neighbor_projection = project_away_from_concave_neighbor(
				projection, ccw_neighbor, ccw_neighbor_normal_side_override,
				p_shape);
		if (Geometry::is_valid(neighbor_projection)) {
			projection = neighbor_projection;
			if (p_rejects_non_overlapping_results &&
				!check_for_shape_to_surface_overlap(
						projection, p_shape, p_surface)) {
				// The projection would leave the character not overlapping the
				// required surface on one end or the other.
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
	if (!Geometry::check_for_shape_to_rect_intersection(
				p_position, p_shape, p_neighbor->get_bounding_box())) {
		return vector2_invalid;
	}

	const Vector2 concave_neighbor_projection = project_shape_onto_surface(
			p_position, p_shape, p_neighbor, true,
			p_neighbor_normal_side_override);

	if (!Geometry::is_valid(concave_neighbor_projection)) {
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
		const Vector2 segment_start = vertices[i];
		const Vector2 segment_end = vertices[i + 1];
		const Vector2 segment_normal =
				get_segment_normal(segment_start, segment_end);
		const Vector2 closest_point_on_shape_to_segment =
				Geometry::get_furthest_shape_boundary_point_in_direction(
						p_shape_position, p_shape, -segment_normal);
		const Vector2 closest_point_on_segment_to_point =
				Geometry::get_closest_point_on_segment_to_point(
						closest_point_on_shape_to_segment, segment_start,
						segment_end);
		const double current_distance_squared =
				closest_point_on_shape_to_segment.distance_squared_to(
						closest_point_on_segment_to_point);
		if (current_distance_squared < closest_distance_squared) {
			closest_distance_squared = current_distance_squared;
			closest_point_on_surface = closest_point_on_segment_to_point;
		}
	}

	return closest_point_on_surface;
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

	const bool is_horizontal = p_surface->get_side() == Surface::Side::FLOOR ||
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

	PackedVector2Array segment_points =
			get_surface_segment_at_point(p_surface, p_point, true);
	const Vector2 segment_start = segment_points[0];
	const Vector2 segment_end = segment_points[1];
	const Vector2 displacement = segment_end - segment_start;
	const bool is_segment_axially_aligned = segment_start.x == segment_end.x ||
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
	const Rect2 bounding_box = p_surface->get_bounding_box();
	if (bounding_box.position.x > p_rectangle_max.x ||
		bounding_box.position.y > p_rectangle_max.y ||
		bounding_box.get_end().x < p_rectangle_min.x ||
		bounding_box.get_end().y < p_rectangle_min.y) {
		return false;
	}

	return Geometry::do_polyline_and_rectangle_intersect(
			p_surface->get_vertices(), p_rectangle_min, p_rectangle_max);
}

bool SurfacerGeometry::check_for_shape_to_surface_overlap(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Ref<Surface> &p_surface,
		double p_epsilon) {
	const double shape_min_x =
			p_shape_position.x - p_shape->get_half_width_height().x;
	const double shape_max_x =
			p_shape_position.x + p_shape->get_half_width_height().x;
	const double shape_min_y =
			p_shape_position.y - p_shape->get_half_width_height().y;
	const double shape_max_y =
			p_shape_position.y + p_shape->get_half_width_height().y;

	const Vector2 surface_bb_pos = p_surface->get_bounding_box().position;
	const Vector2 surface_bb_end = p_surface->get_bounding_box().get_end();

	const bool is_surface_horizontal =
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

PackedVector2Array SurfacerGeometry::get_surface_segment_at_point(
		const Ref<Surface> &p_surface,
		const Vector2 &p_point,
		bool p_uses_end_segment_if_outside_bounds) {
	PackedVector2Array segment_points_result;

	if (!IS_VALID_REF(p_surface)) {
		return segment_points_result;
	}

	const double epsilon = 0.01;
	const PackedVector2Array vertices = p_surface->get_vertices();
	const int count = vertices.size();

	if (count <= 1) {
		segment_points_result.resize(0);
		return segment_points_result;
	}

	bool inside_bounds = false;
	Vector2 segment_start = vector2_invalid;
	Vector2 segment_end = vector2_invalid;

	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR: {
			if (p_point.x < vertices[0].x + epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.x > vertices[count - 1].x - epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.x < vertices[i].x) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		}
		case Surface::Side::LEFT_WALL: {
			if (p_point.y < vertices[0].y + epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.y > vertices[count - 1].y - epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.y < vertices[i].y) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		}
		case Surface::Side::RIGHT_WALL: {
			if (p_point.y > vertices[0].y - epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.y < vertices[count - 1].y + epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.y > vertices[i].y) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		}
		case Surface::Side::CEILING: {
			if (p_point.x > vertices[0].x - epsilon) {
				inside_bounds = false;
				segment_start = vertices[0];
				segment_end = vertices[1];
			} else if (p_point.x < vertices[count - 1].x + epsilon) {
				inside_bounds = false;
				segment_start = vertices[count - 2];
				segment_end = vertices[count - 1];
			} else {
				inside_bounds = true;
				for (int i = 1; i < count; ++i) {
					if (p_point.x > vertices[i].x) {
						segment_start = vertices[i - 1];
						segment_end = vertices[i];
						break;
					}
				}
			}
			break;
		}
		default:
			ENSURE(false,
				   "SurfacerGeometry::get_surface_segment_at_point: Invalid "
				   "surface side");
			break;
	}

	if (inside_bounds || p_uses_end_segment_if_outside_bounds) {
		segment_points_result.resize(2);
		segment_points_result[0] = segment_start;
		segment_points_result[1] = segment_end;
	} else {
		segment_points_result.resize(0);
	}

	return segment_points_result;
}

PackedVector2Array SurfacerGeometry::get_vertices_around_range(
		const Ref<Surface> &p_surface,
		double p_range_min_x,
		double p_range_max_x,
		double p_range_min_y,
		double p_range_max_y) {
	if (!IS_VALID_REF(p_surface)) {
		return {};
	}

	const double epsilon = 0.01;
	const PackedVector2Array vertices = p_surface->get_vertices();
	const int count = vertices.size();

	if (count <= 1) {
		return { vertices[0] };
	}

	int start_index = 0;
	int end_index = 0;

	switch (p_surface->get_side()) {
		case Surface::Side::FLOOR: {
			for (int i = 0; i < count; ++i) {
				if (vertices[i].x > p_range_min_x) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (vertices[i].x > p_range_max_x) {
					break;
				}
			}

			break;
		}
		case Surface::Side::LEFT_WALL: {
			for (int i = 0; i < count; ++i) {
				if (vertices[i].y > p_range_min_y) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (vertices[i].y > p_range_max_y) {
					break;
				}
			}

			break;
		}
		case Surface::Side::RIGHT_WALL: {
			for (int i = 0; i < count; ++i) {
				if (vertices[i].y < p_range_max_y) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (vertices[i].y < p_range_min_y) {
					break;
				}
			}

			break;
		}
		case Surface::Side::CEILING: {
			for (int i = 0; i < count; ++i) {
				if (vertices[i].x < p_range_max_x) {
					start_index = i - 1;
					break;
				}
			}
			start_index = MAX(start_index, 0);

			end_index = start_index + 1;
			for (int i = end_index; i < count; ++i) {
				end_index = i;
				if (vertices[i].x < p_range_min_x) {
					break;
				}
			}

			break;
		}
		default:
			ENSURE(false,
				   "SurfacerGeometry::get_vertices_around_range: Invalid "
				   "surface side");
			break;
	}

	const int result_size = end_index - start_index + 1;
	PackedVector2Array result;
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
	if (!IS_VALID_REF(p_a) && !IS_VALID_REF(p_b)) {
		return true;
	} else if (!IS_VALID_REF(p_a) || !IS_VALID_REF(p_b)) {
		return false;
	} else if (p_a->get_surface() != p_b->get_surface()) {
		return false;
	}
	const double x_diff =
			p_b->get_target_position().x - p_a->get_target_position().x;
	const double y_diff =
			p_b->get_target_position().y - p_a->get_target_position().y;
	return -p_epsilon < x_diff && x_diff < p_epsilon && -p_epsilon < y_diff &&
			y_diff < p_epsilon;
}

Surface::Side SurfacerGeometry::get_surface_side_for_normal(
		const Vector2 &p_normal) {
	if (ABS(p_normal.angle_to(vector2_up)) <=
		Surfacer::floor_max_angle + wall_angle_epsilon) {
		return Surface::Side::FLOOR;
	} else if (
			ABS(p_normal.angle_to(vector2_down)) <=
			Surfacer::floor_max_angle + wall_angle_epsilon) {
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

	if (Surfacer::are_oddly_shaped_surfaces_used &&
		(IS_VALID_REF(p_origin_surface) ||
		 IS_VALID_REF(p_destination_surface))) {
		Vector2 destination_projection = vector2_invalid;
		if (IS_VALID_REF(p_destination_surface)) {
			destination_projection = project_shape_onto_surface(
					p_shape_position, p_shape, p_destination_surface, true,
					p_origin_surface->get_side());
		}

		Vector2 origin_projection = vector2_invalid;
		if (IS_VALID_REF(p_origin_surface)) {
			origin_projection = project_shape_onto_surface(
					p_shape_position, p_shape, p_origin_surface, true,
					p_origin_surface->get_side());
		}

		const bool is_destination_projection_valid =
				Geometry::is_valid(destination_projection);

		switch (p_origin_surface->get_side()) {
			case Surface::Side::FLOOR:
				if (is_destination_projection_valid &&
					destination_projection.y < origin_projection.y) {
					return destination_projection;
				} else {
					return origin_projection;
				}
			case Surface::Side::LEFT_WALL:
				if (is_destination_projection_valid &&
					destination_projection.x > origin_projection.x) {
					return destination_projection;
				} else {
					return origin_projection;
				}
			case Surface::Side::RIGHT_WALL:
				if (is_destination_projection_valid &&
					destination_projection.x < origin_projection.x) {
					return destination_projection;
				} else {
					return origin_projection;
				}
			case Surface::Side::CEILING:
				if (is_destination_projection_valid &&
					destination_projection.y > origin_projection.y) {
					return destination_projection;
				} else {
					return origin_projection;
				}
			default:
				ENSURE(false,
					   "SurfacerGeometry::project_shape_onto_convex_corner_"
					   "preserving_tangent_position: Invalid surface side");
				break;
		}
	} else {
		// TODO: Implement this case. Redirect to
		//       calculate_displacement_x_for_vertical_distance_past_edge and
		//       calculate_displacement_y_for_horizontal_distance_past_edge.
		ENSURE(false, "Not implemented yet.");
	}

	return projection;
}

double SurfacerGeometry::
		calculate_displacement_x_for_vertical_distance_past_edge(
				double p_distance_past_edge,
				bool p_is_left_wall,
				const Ref<RotatedShape> &p_collider) {
	if (const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr())) {
		if (p_distance_past_edge >= circle->get_radius()) {
			return 0.0;
		} else {
			return calculate_circular_displacement_x_for_vertical_distance_past_edge(
					p_distance_past_edge, circle->get_radius(), p_is_left_wall);
		}

	} else if (
			const CapsuleShape2D *capsule = Object::cast_to<CapsuleShape2D>(
					p_collider->get_shape().ptr())) {
		if (p_collider->get_is_rotated_90_degrees()) {
			const double half_height_offset = p_is_left_wall
					? capsule->get_height() / 2.0
					: -capsule->get_height() / 2.0;
			return calculate_circular_displacement_x_for_vertical_distance_past_edge(
						   p_distance_past_edge, capsule->get_radius(),
						   p_is_left_wall) +
					half_height_offset;
		} else {
			const double adjusted_distance_past_edge =
					p_distance_past_edge - capsule->get_height() / 2.0;
			if (adjusted_distance_past_edge <= 0) {
				// Treat the same as a rectangle.
				return p_is_left_wall ? capsule->get_radius()
									  : -capsule->get_radius();
			} else {
				// Treat the same as an offset circle.
				return calculate_circular_displacement_x_for_vertical_distance_past_edge(
						adjusted_distance_past_edge, capsule->get_radius(),
						p_is_left_wall);
			}
		}

	} else if (
			const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
					p_collider->get_shape().ptr())) {
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
	const double distance_x = (p_distance_past_edge >= p_radius)
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
	if (const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_collider->get_shape().ptr())) {
		if (p_distance_past_edge >= circle->get_radius()) {
			return 0.0;
		} else {
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
					p_distance_past_edge, circle->get_radius(), p_is_floor);
		}

	} else if (
			const CapsuleShape2D *capsule = Object::cast_to<CapsuleShape2D>(
					p_collider->get_shape().ptr())) {
		if (p_collider->get_is_rotated_90_degrees()) {
			const double adjusted_distance_past_edge =
					p_distance_past_edge - capsule->get_height() * 0.5;
			if (adjusted_distance_past_edge <= 0) {
				return p_is_floor ? -capsule->get_radius()
								  : capsule->get_radius();
			} else {
				return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						adjusted_distance_past_edge, capsule->get_radius(),
						p_is_floor);
			}
		} else {
			const double half_height_offset = p_is_floor
					? capsule->get_height() / 2.0
					: -capsule->get_height() / 2.0;
			return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
						   p_distance_past_edge, capsule->get_radius(),
						   p_is_floor) +
					half_height_offset;
		}

	} else if (
			const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
					p_collider->get_shape().ptr())) {
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
	const double distance_y = (p_distance_past_edge >= p_radius)
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
					"check_for_shape_to_surface_overlap", "p_shape_position",
					"p_shape", "p_surface", "p_epsilon"),
			&SurfacerGeometry::check_for_shape_to_surface_overlap,
			DEFVAL(shape_overlap_with_concave_surface_epsilon));

	ClassDB::bind_static_method(
			"SurfacerGeometry",
			D_METHOD(
					"get_surface_segment_at_point", "p_surface", "p_point",
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
