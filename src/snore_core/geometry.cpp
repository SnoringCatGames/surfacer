#include "snore_core/geometry.h"

#include "rotated_shape.h"
#include "snore_core/internal_utils.h"

#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/vector2i.hpp>

using namespace godot;

void Geometry::_bind_methods() {
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_distance_squared_from_point_to_segment", "point",
					"segment_a", "segment_b"),
			&Geometry::get_distance_squared_from_point_to_segment);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_distance_squared_from_point_to_polyline", "point",
					"polyline"),
			&Geometry::get_distance_squared_from_point_to_polyline);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_distance_squared_between_non_intersecting_segments",
					"segment_1_a", "segment_1_b", "segment_2_a", "segment_2_b"),
			&Geometry::get_distance_squared_between_non_intersecting_segments);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("get_distance_squared_from_rect_to_rect", "a", "b"),
			&Geometry::get_distance_squared_from_rect_to_rect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_closest_point_on_segment_to_point", "point",
					"segment_a", "segment_b"),
			&Geometry::get_closest_point_on_segment_to_point);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_closest_point_on_polyline_to_point", "point",
					"polyline"),
			&Geometry::get_closest_point_on_polyline_to_point);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("get_closest_point_on_polyline_to_polyline", "a", "b"),
			&Geometry::get_closest_point_on_polyline_to_polyline);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_intersection_of_segments", "segment_1_a",
					"segment_1_b", "segment_2_a", "segment_2_b"),
			&Geometry::get_intersection_of_segments);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_intersection_of_segment_and_polyline", "segment_a",
					"segment_b", "vertices"),
			&Geometry::get_intersection_of_segment_and_polyline);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_intersection_of_segment_and_circle", "segment_a",
					"segment_b", "center", "radius",
					"uses_first_possible_intersection"),
			&Geometry::get_intersection_of_segment_and_circle, DEFVAL(true));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("is_point_in_triangle", "point", "a", "b", "c"),
			&Geometry::is_point_in_triangle);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"is_point_in_rectangle", "point", "rectangle_min",
					"rectangle_max"),
			&Geometry::is_point_in_rectangle);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_rectangles_intersect", "a_min", "a_max", "b_min",
					"b_max"),
			&Geometry::do_rectangles_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"does_rectangle_and_circle_intersect", "rectangle_min",
					"rectangle_max", "circle_center", "circle_radius"),
			&Geometry::does_rectangle_and_circle_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_segment_and_rectangle_intersect", "segment_a",
					"segment_b", "rectangle_min", "rectangle_max"),
			&Geometry::do_segment_and_rectangle_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_segment_and_triangle_intersect", "segment_a",
					"segment_b", "triangle_a", "triangle_b", "triangle_c"),
			&Geometry::do_segment_and_triangle_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_segment_and_polygon_intersect", "segment_a",
					"segment_b", "polygon"),
			&Geometry::do_segment_and_polygon_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_polyline_and_rectangle_intersect", "vertices",
					"rectangle_min", "rectangle_max"),
			&Geometry::do_polyline_and_rectangle_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_polyline_and_triangle_intersect", "vertices",
					"triangle_a", "triangle_b", "triangle_c"),
			&Geometry::do_polyline_and_triangle_intersect);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_polyline_and_polygon_intersect", "vertices", "polygon"),
			&Geometry::do_polyline_and_polygon_intersect);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("is_polygon_clockwise", "vertices"),
			&Geometry::is_polygon_clockwise);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("are_three_points_clockwise", "a", "b", "c"),
			&Geometry::are_three_points_clockwise);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("is_polygon_convex", "vertices", "epsilon"),
			&Geometry::is_polygon_convex, DEFVAL(0.001f));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("are_points_collinear", "p1", "p2", "p3", "epsilon"),
			&Geometry::are_points_collinear, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"do_point_and_segment_intersect", "point", "segment_a",
					"segment_b", "epsilon"),
			&Geometry::do_point_and_segment_intersect, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("get_bounding_box_for_points", "points"),
			&Geometry::get_bounding_box_for_points);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("distance_squared_from_point_to_rect", "point", "rect"),
			&Geometry::distance_squared_from_point_to_rect);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("calculate_manhattan_distance", "a", "b"),
			&Geometry::calculate_manhattan_distance);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("is_point_inf", "point"),
			&Geometry::is_point_inf);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("is_point_partial_inf", "point"),
			&Geometry::is_point_partial_inf);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("are_floats_equal_with_epsilon", "a", "b", "epsilon"),
			&Geometry::are_floats_equal_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("are_points_equal_with_epsilon", "a", "b", "epsilon"),
			&Geometry::are_points_equal_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("are_rects_equal_with_epsilon", "a", "b", "epsilon"),
			&Geometry::are_rects_equal_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("are_colors_equal_with_epsilon", "a", "b", "epsilon"),
			&Geometry::are_colors_equal_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"is_float_integer_aligned_with_epsilon", "number",
					"epsilon"),
			&Geometry::is_float_integer_aligned_with_epsilon,
			DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("is_float_gte_with_epsilon", "a", "b", "epsilon"),
			&Geometry::is_float_gte_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("is_float_lte_with_epsilon", "a", "b", "epsilon"),
			&Geometry::is_float_lte_with_epsilon, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"clamp_vector_length", "vector", "min_length",
					"max_length"),
			&Geometry::clamp_vector_length);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("snap_float_to_integer", "number", "epsilon"),
			&Geometry::snap_float_to_integer, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("snap_vector2_to_integers", "point", "epsilon"),
			&Geometry::snap_vector2_to_integers, DEFVAL(float_epsilon));
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("do_shapes_match", "shape_a", "shape_b"),
			&Geometry::do_shapes_match);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"calculate_half_width_height", "shape",
					"is_rotated_90_degrees"),
			&Geometry::calculate_half_width_height);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("world_to_tile_map", "position", "tile_map_layer"),
			&Geometry::world_to_tile_map_layer);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("tile_map_to_world", "position", "tile_map_layer"),
			&Geometry::tile_map_layer_to_world);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_tile_map_index_from_world_coord", "position",
					"tile_map_layer"),
			&Geometry::get_tile_map_layer_index_from_world_coord);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_tile_map_index_from_grid_coord", "position",
					"tile_map_layer"),
			&Geometry::get_tile_map_layer_index_from_grid_coord);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_grid_coord_from_tile_map_index", "index",
					"tile_map_layer"),
			&Geometry::get_grid_coord_from_tile_map_layer_index);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_tile_map_bounds_in_world_coordinates",
					"tile_map_layer"),
			&Geometry::get_tile_map_layer_bounds_in_world_coordinates);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("get_vector2_array_front", "vertices"),
			&Geometry::get_vector2_array_front);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("get_vector2_array_back", "vertices"),
			&Geometry::get_vector2_array_back);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD("get_vector_string", "vector", "decimal_place_count"),
			&Geometry::get_vector_string, DEFVAL(2));
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("get_perpendicular_vector", "vector"),
			&Geometry::get_perpendicular_vector);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("is_vector_valid", "vector"),
			&Geometry::is_valid);
	ClassDB::bind_static_method(
			"Geometry", D_METHOD("get_radius", "shape"), &Geometry::get_radius);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"get_furthest_shape_boundary_point_in_direction",
					"p_shape_position", "p_shape", "p_direction"),
			&Geometry::get_furthest_shape_boundary_point_in_direction);
	ClassDB::bind_static_method(
			"Geometry",
			D_METHOD(
					"check_for_shape_to_rect_intersection", "p_shape_position",
					"p_shape", "p_rect", "p_epsilon"),
			&Geometry::check_for_shape_to_rect_intersection, DEFVAL(0.0f));
}

float Geometry::get_distance_squared_from_point_to_segment(
		const Vector2 &p_point,
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b) {
	Vector2 closest_point = get_closest_point_on_segment_to_point(
			p_point, p_segment_a, p_segment_b);
	return p_point.distance_squared_to(std::move(closest_point));
}

float Geometry::get_distance_squared_from_point_to_polyline(
		const Vector2 &p_point,
		const PackedVector2Array &p_polyline) {
	Vector2 closest_point =
			get_closest_point_on_polyline_to_point(p_point, p_polyline);
	return p_point.distance_squared_to(std::move(closest_point));
}

float Geometry::get_distance_squared_between_non_intersecting_segments(
		const Vector2 &p_segment_1_a,
		const Vector2 &p_segment_1_b,
		const Vector2 &p_segment_2_a,
		const Vector2 &p_segment_2_b) {
	const Vector2 closest_on_2_to_1_a = get_closest_point_on_segment_to_point(
			p_segment_1_a, p_segment_2_a, p_segment_2_b);
	const Vector2 closest_on_2_to_1_b = get_closest_point_on_segment_to_point(
			p_segment_1_b, p_segment_2_a, p_segment_2_b);
	const Vector2 closest_on_1_to_2_a = get_closest_point_on_segment_to_point(
			p_segment_2_a, p_segment_1_a, p_segment_1_b);
	const Vector2 closest_on_1_to_2_b = get_closest_point_on_segment_to_point(
			p_segment_2_b, p_segment_1_a, p_segment_1_b);

	const float distance_squared_from_2_to_1_a =
			closest_on_2_to_1_a.distance_squared_to(p_segment_1_a);
	const float distance_squared_from_2_to_1_b =
			closest_on_2_to_1_b.distance_squared_to(p_segment_1_b);
	const float distance_squared_from_1_to_2_a =
			closest_on_1_to_2_a.distance_squared_to(p_segment_2_a);
	const float distance_squared_from_1_to_2_b =
			closest_on_1_to_2_b.distance_squared_to(p_segment_2_b);

	return MIN(
			MIN(distance_squared_from_2_to_1_a, distance_squared_from_2_to_1_b),
			MIN(distance_squared_from_1_to_2_a,
				distance_squared_from_1_to_2_b));
}

float Geometry::get_distance_squared_from_rect_to_rect(
		const Rect2 &p_a,
		const Rect2 &p_b) {
	const float min_x = MIN(p_a.position.x, p_b.position.x);
	const float min_y = MIN(p_a.position.y, p_b.position.y);
	const float max_x = MAX(p_a.get_end().x, p_b.get_end().x);
	const float max_y = MAX(p_a.get_end().y, p_b.get_end().y);

	const float inner_width =
			MAX(0.0f, (max_x - min_x) - p_a.size.x - p_b.size.x);
	const float inner_height =
			MAX(0.0f, (max_y - min_y) - p_a.size.y - p_b.size.y);

	return inner_width * inner_width + inner_height * inner_height;
}

Vector2 Geometry::get_closest_point_on_segment_to_point(
		const Vector2 &p_point,
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b) {
	const Vector2 v = p_segment_b - p_segment_a;
	const Vector2 u = p_point - p_segment_a;
	const float uv = u.dot(v);
	const float vv = v.dot(v);

	if (uv <= 0.0f) {
		// The projection of the point lies before the first point in the
		// segment.
		return p_segment_a;
	} else if (vv <= uv) {
		// The projection of the point lies after the last point in the
		// segment.
		return p_segment_b;
	} else {
		// The projection of the point lies within the bounds of the
		// segment.
		const float t = uv / vv;
		return p_segment_a + v * t;
	}
}

Vector2 Geometry::get_closest_point_on_polyline_to_point(
		const Vector2 &p_point,
		const PackedVector2Array &p_polyline) {
	if (p_polyline.is_empty()) {
		return vector2_invalid;
	}
	if (p_polyline.size() == 1) {
		return p_polyline[0];
	}

	Vector2 closest_point = get_closest_point_on_segment_to_point(
			p_point, p_polyline[0], p_polyline[1]);
	float closest_distance_squared = p_point.distance_squared_to(closest_point);

	for (int i = 1; i < p_polyline.size() - 1; ++i) {
		Vector2 current_point = get_closest_point_on_segment_to_point(
				p_point, p_polyline[i], p_polyline[i + 1]);
		float current_distance_squared =
				p_point.distance_squared_to(current_point);
		if (current_distance_squared < closest_distance_squared) {
			closest_distance_squared = std::move(current_distance_squared);
			closest_point = std::move(current_point);
		}
	}

	return closest_point;
}

Vector2 Geometry::get_closest_point_on_polyline_to_polyline(
		const PackedVector2Array &p_a,
		const PackedVector2Array &p_b) {
	if (p_a.is_empty() || p_b.is_empty()) {
		return vector2_invalid;
	}
	if (p_a.size() == 1) {
		return p_a[0];
	}

	Vector2 closest_point = vector2_invalid;
	float closest_distance_squared = Math_INF;

	for (const auto &vertex_b : p_b) {
		Vector2 current_point =
				get_closest_point_on_polyline_to_point(vertex_b, p_a);
		float current_distance_squared =
				vertex_b.distance_squared_to(current_point);
		if (current_distance_squared < closest_distance_squared) {
			closest_distance_squared = std::move(current_distance_squared);
			closest_point = std::move(current_point);
		}
	}

	return closest_point;
}

Vector2 Geometry::get_intersection_of_segments(
		const Vector2 &p_segment_1_a,
		const Vector2 &p_segment_1_b,
		const Vector2 &p_segment_2_a,
		const Vector2 &p_segment_2_b) {
	const Vector2 r = p_segment_1_b - p_segment_1_a;
	const Vector2 s = p_segment_2_b - p_segment_2_a;

	const float u_numerator = (p_segment_2_a - p_segment_1_a).cross(r);
	const float denominator = r.cross(s);

	if (u_numerator == 0 && denominator == 0) {
		// The segments are collinear.
		const float t0_numerator = (p_segment_2_a - p_segment_1_a).dot(r);
		const float t1_numerator = (p_segment_1_a - p_segment_2_a).dot(s);
		if ((0 <= t0_numerator && t0_numerator <= r.dot(r)) ||
			(0 <= t1_numerator && t1_numerator <= s.dot(s))) {
			// The segments overlap. Return one of the segment endpoints
			// that lies within the overlap region.
			if ((p_segment_1_a.x >= p_segment_2_a.x &&
				 p_segment_1_a.x <= p_segment_2_b.x) ||
				(p_segment_1_a.x <= p_segment_2_a.x &&
				 p_segment_1_a.x >= p_segment_2_b.x)) {
				return p_segment_1_a;
			} else {
				return p_segment_1_b;
			}
		} else {
			// The segments are disjoint.
			return vector2_invalid;
		}
	} else if (denominator == 0) {
		// The segments are parallel.
		return vector2_invalid;
	} else {
		// The segments are not parallel.
		const float u = u_numerator / denominator;
		const float t = (p_segment_2_a - p_segment_1_a).cross(s) / denominator;
		if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
			// The segments intersect.
			return p_segment_1_a + t * r;
		} else {
			// The segments don't touch.
			return vector2_invalid;
		}
	}
}

Vector2 Geometry::get_intersection_of_segment_and_polyline(
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		const PackedVector2Array &p_vertices) {
	if (p_vertices.is_empty()) {
		return vector2_invalid;
	} else if (p_vertices.size() == 1) {
		// Check if the single vertex intersects the segment.
		if (do_point_and_segment_intersect(
					p_segment_a, p_segment_b, p_vertices[0])) {
			return p_vertices[0];
		}
	} else {
		for (int i = 0; i < p_vertices.size() - 1; ++i) {
			const Vector2 intersection = get_intersection_of_segments(
					p_segment_a, p_segment_b, p_vertices[i], p_vertices[i + 1]);
			if (Geometry::is_valid(intersection)) {
				return intersection;
			}
		}
	}
	return vector2_invalid;
}

Vector2 Geometry::get_intersection_of_segment_and_circle(
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		const Vector2 &p_center,
		float p_radius,
		bool p_uses_first_possible_intersection) {
	const Vector2 d = p_segment_b - p_segment_a;
	const Vector2 f = p_segment_a - p_center;

	const float a = d.dot(d);
	const float b = 2.0f * f.dot(d);
	const float c = f.dot(f) - p_radius * p_radius;

	const float discriminant = b * b - 4.0f * a * c;

	if (discriminant < 0) {
		// The collinear line of the segment does not intersect the circle.
		return vector2_invalid;
	} else {
		const float discriminant_sqrt = Math::sqrt(discriminant);

		// t1 represents the intersection closer to segment_a.
		const float t1 = (-b - discriminant_sqrt) / (2.0f * a);
		const float t2 = (-b + discriminant_sqrt) / (2.0f * a);

		const bool is_t1_intersecting = t1 >= 0 && t1 <= 1;
		const bool is_t2_intersecting = t2 >= 0 && t2 <= 1;

		if (p_uses_first_possible_intersection) {
			if (is_t1_intersecting) {
				return p_segment_a + d * t1;
			}
			if (is_t2_intersecting) {
				return p_segment_a + d * t2;
			}
		} else {
			if (is_t2_intersecting) {
				return p_segment_a + d * t2;
			}
			if (is_t1_intersecting) {
				return p_segment_a + d * t1;
			}
		}

		// The collinear line intersects the circle, but the segment does
		// not.
		return vector2_invalid;
	}
}

bool Geometry::is_point_in_triangle(
		const Vector2 &p_point,
		const Vector2 &p_a,
		const Vector2 &p_b,
		const Vector2 &p_c) {
	// Use barycentric coordinates to determine if the point is inside the
	// triangle.
	const Vector2 ac = p_c - p_a;
	const Vector2 ab = p_b - p_a;
	const Vector2 ap = p_point - p_a;

	const float dot_ac_ac = ac.dot(ac);
	const float dot_ac_ab = ac.dot(ab);
	const float dot_ac_ap = ac.dot(ap);
	const float dot_ab_ab = ab.dot(ab);
	const float dot_ab_ap = ab.dot(ap);

	const float denominator = dot_ac_ac * dot_ab_ab - dot_ac_ab * dot_ac_ab;
	if (denominator == 0) {
		// Degenerate triangle.
		return false;
	}

	// The barycentric coordinates.
	const float inverse_denominator = 1.0f / denominator;
	const float u = (dot_ab_ab * dot_ac_ap - dot_ac_ab * dot_ab_ap) *
			inverse_denominator;
	const float v = (dot_ac_ac * dot_ab_ap - dot_ac_ab * dot_ac_ap) *
			inverse_denominator;

	return (u >= 0) && (v >= 0) && (u + v < 1);
}

bool Geometry::is_point_in_rectangle(
		const Vector2 &p_point,
		const Vector2 &p_rectangle_min,
		const Vector2 &p_rectangle_max) {
	return p_point.x > p_rectangle_min.x && p_point.y > p_rectangle_min.y &&
			p_point.x < p_rectangle_max.x && p_point.y < p_rectangle_max.y;
}

bool Geometry::do_rectangles_intersect(
		const Vector2 &p_a_min,
		const Vector2 &p_a_max,
		const Vector2 &p_b_min,
		const Vector2 &p_b_max) {
	return p_a_min.x <= p_b_max.x && p_a_min.y <= p_b_max.y &&
			p_a_max.x >= p_b_min.x && p_a_max.y >= p_b_min.y;
}

bool Geometry::does_rectangle_and_circle_intersect(
		const Vector2 &p_rectangle_min,
		const Vector2 &p_rectangle_max,
		const Vector2 &p_circle_center,
		float p_circle_radius) {
	const Vector2 rectangle_extents =
			(p_rectangle_max - p_rectangle_min) * 0.5f;
	const Vector2 rectangle_center = p_rectangle_min + rectangle_extents;

	const float centers_distance_x =
			ABS(p_circle_center.x - rectangle_center.x);
	const float centers_distance_y =
			ABS(p_circle_center.y - rectangle_center.y);

	if (centers_distance_x >= rectangle_extents.x + p_circle_radius) {
		return false;
	}
	if (centers_distance_y >= rectangle_extents.y + p_circle_radius) {
		return false;
	}

	if (centers_distance_x < rectangle_extents.x) {
		return true;
	}
	if (centers_distance_y < rectangle_extents.y) {
		return true;
	}

	const float rectangle_diagonal_extent_distance_squared =
			(centers_distance_x - rectangle_extents.x) *
					(centers_distance_x - rectangle_extents.x) +
			(centers_distance_y - rectangle_extents.y) *
					(centers_distance_y - rectangle_extents.y);

	return rectangle_diagonal_extent_distance_squared <
			(p_circle_radius * p_circle_radius);
}

bool Geometry::do_segment_and_rectangle_intersect(
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		const Vector2 &p_rectangle_min,
		const Vector2 &p_rectangle_max) {
	// First, check line intersection.
	const float is_segment_left_of_corner_1 =
			(p_segment_b.y - p_segment_a.y) * p_rectangle_min.x +
			(p_segment_a.x - p_segment_b.x) * p_rectangle_min.y +
			(p_segment_b.x * p_segment_a.y - p_segment_a.x * p_segment_b.y);
	const float is_segment_left_of_corner_2 =
			(p_segment_b.y - p_segment_a.y) * p_rectangle_max.x +
			(p_segment_a.x - p_segment_b.x) * p_rectangle_min.y +
			(p_segment_b.x * p_segment_a.y - p_segment_a.x * p_segment_b.y);
	const float is_segment_left_of_corner_3 =
			(p_segment_b.y - p_segment_a.y) * p_rectangle_max.x +
			(p_segment_a.x - p_segment_b.x) * p_rectangle_max.y +
			(p_segment_b.x * p_segment_a.y - p_segment_a.x * p_segment_b.y);
	const float is_segment_left_of_corner_4 =
			(p_segment_b.y - p_segment_a.y) * p_rectangle_min.x +
			(p_segment_a.x - p_segment_b.x) * p_rectangle_max.y +
			(p_segment_b.x * p_segment_a.y - p_segment_a.x * p_segment_b.y);
	if ((is_segment_left_of_corner_1 == is_segment_left_of_corner_2) &&
		(is_segment_left_of_corner_1 == is_segment_left_of_corner_3) &&
		(is_segment_left_of_corner_1 == is_segment_left_of_corner_4)) {
		// If all rectangle corners are on the same side of the line, then
		// there is no intersection.
		return false;
	}

	// Second, check line-segment projection.
	return (p_segment_a.x <= p_rectangle_max.x ||
			p_segment_b.x <= p_rectangle_max.x) &&
			(p_segment_a.x >= p_rectangle_min.x ||
			 p_segment_b.x >= p_rectangle_min.x) &&
			(p_segment_a.y <= p_rectangle_max.y ||
			 p_segment_b.y <= p_rectangle_max.y) &&
			(p_segment_a.y >= p_rectangle_min.y ||
			 p_segment_b.y >= p_rectangle_min.y);
}

bool Geometry::do_segment_and_triangle_intersect(
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		const Vector2 &p_triangle_a,
		const Vector2 &p_triangle_b,
		const Vector2 &p_triangle_c) {
	// Check if the segment intersects any of the triangle's edges.
	if (Geometry::is_valid(get_intersection_of_segments(
				p_segment_a, p_segment_b, p_triangle_a, p_triangle_b)) ||
		Geometry::is_valid(get_intersection_of_segments(
				p_segment_a, p_segment_b, p_triangle_b, p_triangle_c)) ||
		Geometry::is_valid(get_intersection_of_segments(
				p_segment_a, p_segment_b, p_triangle_c, p_triangle_a))) {
		return true;
	}

	// Check if one of the segment's endpoints is inside the triangle.
	// We only need to check one endpoint, as the other is guaranteed to be
	// inside if the segment didn't intersect the triangle's edges.
	if (is_point_in_triangle(
				p_segment_a, p_triangle_a, p_triangle_b, p_triangle_c)) {
		return true;
	}

	return false;
}

bool Geometry::do_segment_and_polygon_intersect(
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		const PackedVector2Array &p_polygon) {
	// -------------------------------------------------------------------------
	// Based on the "parametric line-clipping" approach described by Dan
	// Sunday at http://geomalgorithms.com/a13-_intersect-4.html.
	//
	// Copyright 2001 softSurfer, 2012 Dan Sunday
	// This code may be freely used and modified for any purpose
	// providing that this copyright notice is included with it.
	// SoftSurfer makes no warranty for this code, and cannot be held
	// liable for any real or imagined damage resulting from its use.
	// Users of this code must verify correctness for their application.
	// -------------------------------------------------------------------------

	ENSURE(get_vector2_array_front(p_polygon) ==
				   get_vector2_array_back(p_polygon),
		   vformat("Polygon is not closed: front=%s, back=%s",
				   get_vector2_array_front(p_polygon),
				   get_vector2_array_back(p_polygon)));

	const Vector2 segment_diff = p_segment_b - p_segment_a;
	float t_entering = 0.0f;
	float t_leaving = 1.0f;

	for (int i = 0; i < p_polygon.size() - 1; ++i) {
		const Vector2 polygon_segment = p_polygon[i + 1] - p_polygon[i];
		const Vector2 p_to_a = p_segment_a - p_polygon[i];
		const float n =
				polygon_segment.x * p_to_a.y - polygon_segment.y * p_to_a.x;
		const float d = polygon_segment.y * segment_diff.x -
				polygon_segment.x * segment_diff.y;

		if (ABS(d) < float_epsilon) {
			if (n < 0) {
				return false;
			} else {
				continue;
			}
		}

		const float t = n / d;
		if (d < 0) {
			if (t > t_entering) {
				t_entering = t;
				if (t_entering > t_leaving) {
					return false;
				}
			}
		} else {
			if (t < t_leaving) {
				t_leaving = t;
				if (t_leaving < t_entering) {
					return false;
				}
			}
		}
	}

	// Possible point of intersection 1: segment_a + t_entering *
	// segment_diff Possible point of intersection 2: segment_a + t_leaving
	// * segment_diff

	return true;
}

bool Geometry::do_polyline_and_rectangle_intersect(
		const PackedVector2Array &p_vertices,
		const Vector2 &p_rectangle_min,
		const Vector2 &p_rectangle_max) {
	for (int i = 0; i < p_vertices.size() - 1; ++i) {
		if (do_segment_and_rectangle_intersect(
					p_vertices[i], p_vertices[i + 1], p_rectangle_min,
					p_rectangle_max)) {
			return true;
		}
	}
	return false;
}

bool Geometry::do_polyline_and_triangle_intersect(
		const PackedVector2Array &p_vertices,
		const Vector2 &p_triangle_a,
		const Vector2 &p_triangle_b,
		const Vector2 &p_triangle_c) {
	for (int i = 0; i < p_vertices.size() - 1; ++i) {
		if (do_segment_and_triangle_intersect(
					p_vertices[i], p_vertices[i + 1], p_triangle_a,
					p_triangle_b, p_triangle_c)) {
			return true;
		}
	}
	return false;
}

bool Geometry::do_polyline_and_polygon_intersect(
		const PackedVector2Array &p_vertices,
		const PackedVector2Array &p_polygon) {
	for (int i = 0; i < p_vertices.size() - 1; ++i) {
		if (do_segment_and_polygon_intersect(
					p_vertices[i], p_vertices[i + 1], p_polygon)) {
			return true;
		}
	}
	return false;
}

bool Geometry::is_polygon_clockwise(const PackedVector2Array &p_vertices) {
	// This uses the shoelace formula.

	const int vertex_count = p_vertices.size();
	float sum = 0.0f;

	Vector2 v1 = p_vertices[vertex_count - 1];
	Vector2 v2 = p_vertices[0];
	sum += (v2.x - v1.x) * (v2.y + v1.y);

	for (int i = 0; i < vertex_count - 1; ++i) {
		v1 = p_vertices[i];
		v2 = p_vertices[i + 1];
		sum += (v2.x - v1.x) * (v2.y + v1.y);
	}

	return sum < 0;
}

bool Geometry::are_three_points_clockwise(
		const Vector2 &p_a,
		const Vector2 &p_b,
		const Vector2 &p_c) {
	const float result = (p_a.y - p_b.y) * (p_c.x - p_a.x) -
			(p_a.x - p_b.x) * (p_c.y - p_a.y);
	return result > 0;
}

bool Geometry::is_polygon_convex(
		const PackedVector2Array &p_vertices,
		float p_epsilon) {
	const int vertex_count = p_vertices.size();

	ENSURE(get_vector2_array_front(p_vertices) ==
				   get_vector2_array_back(p_vertices),
		   vformat("Polygon is closed: front=%s, back=%s",
				   get_vector2_array_front(p_vertices),
				   get_vector2_array_back(p_vertices)));

	if (vertex_count < 3) {
		return true;
	}

	int w_sign = 0;

	int x_sign = 0;
	int x_first_sign = 0;
	int x_flips = 0;

	int y_sign = 0;
	int y_first_sign = 0;
	int y_flips = 0;

	Vector2 previous_vertex;
	Vector2 current_vertex = p_vertices[vertex_count - 2];
	Vector2 next_vertex = p_vertices[vertex_count - 1];

	for (const Vector2 &vertex : p_vertices) {
		previous_vertex = current_vertex;
		current_vertex = next_vertex;
		next_vertex = vertex;

		const Vector2 previous_displacement = current_vertex - previous_vertex;
		const Vector2 next_displacement = next_vertex - current_vertex;

		// Count the number of sign flips, and record the first sign.
		if (next_displacement.x > p_epsilon) {
			if (x_sign == 0) {
				x_first_sign = 1;
			} else if (x_sign < 0) {
				x_flips += 1;
			}
			x_sign = 1;
		} else if (next_displacement.x < -p_epsilon) {
			if (x_sign == 0) {
				x_first_sign = -1;
			} else if (x_sign > 0) {
				x_flips += 1;
			}
			x_sign = -1;
		}

		if (x_flips > 2) {
			return false;
		}

		// Count the number of sign flips, and record the first sign.
		if (next_displacement.y > p_epsilon) {
			if (y_sign == 0) {
				y_first_sign = 1;
			} else if (y_sign < 0) {
				y_flips += 1;
			}
			y_sign = 1;
		} else if (next_displacement.y < -p_epsilon) {
			if (y_sign == 0) {
				y_first_sign = -1;
			} else if (y_sign > 0) {
				y_flips += 1;
			}
			y_sign = -1;
		}

		if (y_flips > 2) {
			return false;
		}

		// Calculate the edge-pair orientation, and check whether it has
		// changed.
		const float w = previous_displacement.x * next_displacement.y -
				next_displacement.x * previous_displacement.y;
		if (w_sign == 0 && (w < -p_epsilon || w > p_epsilon)) {
			w_sign = (w > 0) ? 1 : -1;
		} else if (w_sign > 0 && w < -p_epsilon) {
			return false;
		} else if (w_sign < 0 && w > p_epsilon) {
			return false;
		}
	}

	// Wrap-around sign flips (the fencepost problem).
	if (x_sign != 0 && x_first_sign != 0 && x_sign != x_first_sign) {
		x_flips += 1;
	}
	if (y_sign != 0 && y_first_sign != 0 && y_sign != y_first_sign) {
		y_flips += 1;
	}

	// Convex polygons have two sign flips along each axis.
	return x_flips == 2 && y_flips == 2;
}

bool Geometry::are_points_collinear(
		const Vector2 &p_p1,
		const Vector2 &p_p2,
		const Vector2 &p_p3,
		float p_epsilon) {
	return ABS((p_p2.x - p_p1.x) * (p_p3.y - p_p1.y) -
			   (p_p3.x - p_p1.x) * (p_p2.y - p_p1.y)) < p_epsilon;
}

bool Geometry::do_point_and_segment_intersect(
		const Vector2 &p_point,
		const Vector2 &p_segment_a,
		const Vector2 &p_segment_b,
		float p_epsilon) {
	const float cross_product =
			(p_segment_a.x - p_point.x) * (p_segment_b.y - p_point.y) -
			(p_segment_b.x - p_point.x) * (p_segment_a.y - p_point.y);
	if (ABS(cross_product) >= p_epsilon) {
		return false;
	}

	if ((p_point.x <= p_segment_a.x + p_epsilon &&
		 p_point.x >= p_segment_b.x - p_epsilon) ||
		(p_point.x >= p_segment_a.x - p_epsilon &&
		 p_point.x <= p_segment_b.x + p_epsilon)) {
		return true;
	}

	return false;
}

Rect2 Geometry::get_bounding_box_for_points(
		const PackedVector2Array &p_points) {
	ENSURE_SIMPLE(!p_points.is_empty());

	Vector2 min = p_points[0];
	Vector2 max = p_points[0];

	for (int i = 1; i < p_points.size(); ++i) {
		const Vector2 &point = p_points[i];
		min.x = MIN(min.x, point.x);
		min.y = MIN(min.y, point.y);
		max.x = MAX(max.x, point.x);
		max.y = MAX(max.y, point.y);
	}

	return Rect2(min, max - min);
}

float Geometry::distance_squared_from_point_to_rect(
		const Vector2 &p_point,
		const Rect2 &p_rect) {
	const Vector2 rect_min = p_rect.position;
	const Vector2 rect_max = p_rect.get_end();

	if (p_point.x < rect_min.x) {
		if (p_point.y < rect_min.y) {
			return p_point.distance_squared_to(rect_min);
		} else if (p_point.y > rect_max.y) {
			return p_point.distance_squared_to(Vector2(rect_min.x, rect_max.y));
		} else {
			const float distance = rect_min.x - p_point.x;
			return distance * distance;
		}
	} else if (p_point.x > rect_max.x) {
		if (p_point.y < rect_min.y) {
			return p_point.distance_squared_to(Vector2(rect_max.x, rect_min.y));
		} else if (p_point.y > rect_max.y) {
			return p_point.distance_squared_to(rect_max);
		} else {
			const float distance = p_point.x - rect_max.x;
			return distance * distance;
		}
	} else {
		if (p_point.y < rect_min.y) {
			const float distance = rect_min.y - p_point.y;
			return distance * distance;
		} else if (p_point.y > rect_max.y) {
			const float distance = p_point.y - rect_max.y;
			return distance * distance;
		} else {
			return 0.0f;
		}
	}
}

float Geometry::calculate_manhattan_distance(
		const Vector2 &p_a,
		const Vector2 &p_b) {
	return ABS(p_b.x - p_a.x) + ABS(p_b.y - p_a.y);
}

bool Geometry::is_point_inf(const Vector2 &p_point) {
	return Math::is_inf(p_point.x) && Math::is_inf(p_point.y);
}

bool Geometry::is_point_partial_inf(const Vector2 &p_point) {
	return Math::is_inf(p_point.x) || Math::is_inf(p_point.y);
}

bool Geometry::are_floats_equal_with_epsilon(
		float p_a,
		float p_b,
		float p_epsilon) {
	const float diff = p_b - p_a;
	return -p_epsilon < diff && diff < p_epsilon;
}

bool Geometry::are_points_equal_with_epsilon(
		const Vector2 &p_a,
		const Vector2 &p_b,
		float p_epsilon) {
	const float x_diff = p_b.x - p_a.x;
	const float y_diff = p_b.y - p_a.y;
	return -p_epsilon < x_diff && x_diff < p_epsilon && -p_epsilon < y_diff &&
			y_diff < p_epsilon;
}

bool Geometry::are_rects_equal_with_epsilon(
		const Rect2 &p_a,
		const Rect2 &p_b,
		float p_epsilon) {
	const float x_diff = p_b.position.x - p_a.position.x;
	const float y_diff = p_b.position.y - p_a.position.y;
	const float w_diff = p_b.size.x - p_a.size.x;
	const float h_diff = p_b.size.y - p_a.size.y;

	return -p_epsilon < x_diff && x_diff < p_epsilon && -p_epsilon < y_diff &&
			y_diff < p_epsilon && -p_epsilon < w_diff && w_diff < p_epsilon &&
			-p_epsilon < h_diff && h_diff < p_epsilon;
}

bool Geometry::are_colors_equal_with_epsilon(
		const Color &p_a,
		const Color &p_b,
		float p_epsilon) {
	const float r_diff = p_b.r - p_a.r;
	const float g_diff = p_b.g - p_a.g;
	const float b_diff = p_b.b - p_a.b;
	const float a_diff = p_b.a - p_a.a;

	return -p_epsilon < r_diff && r_diff < p_epsilon && -p_epsilon < g_diff &&
			g_diff < p_epsilon && -p_epsilon < b_diff && b_diff < p_epsilon &&
			-p_epsilon < a_diff && a_diff < p_epsilon;
}

bool Geometry::is_float_integer_aligned_with_epsilon(
		float p_number,
		float p_epsilon) {
	const float remainder = Math::fmod(p_number, 1.0f);
	return remainder < p_epsilon || remainder > 1.0f - p_epsilon;
}

bool Geometry::is_float_gte_with_epsilon(
		float p_a,
		float p_b,
		float p_epsilon) {
	const float diff = p_b - p_a;
	return p_a >= p_b || (-p_epsilon < diff && diff < p_epsilon);
}

bool Geometry::is_float_lte_with_epsilon(
		float p_a,
		float p_b,
		float p_epsilon) {
	const float diff = p_b - p_a;
	return p_a <= p_b || (-p_epsilon < diff && diff < p_epsilon);
}

Vector2 Geometry::clamp_vector_length(
		const Vector2 &p_vector,
		float p_min_length,
		float p_max_length) {
	const float length_squared = p_vector.length_squared();
	if (length_squared > p_max_length * p_max_length) {
		return p_vector.normalized() * p_max_length;
	} else if (length_squared < p_min_length * p_min_length) {
		return p_vector.normalized() * p_min_length;
	} else {
		return p_vector;
	}
}

float Geometry::snap_float_to_integer(float p_number, float p_epsilon) {
	if (is_float_integer_aligned_with_epsilon(p_number, p_epsilon)) {
		return Math::round(p_number);
	} else {
		return p_number;
	}
}

Vector2 Geometry::snap_vector2_to_integers(
		const Vector2 &p_point,
		float p_epsilon) {
	return Vector2(
			snap_float_to_integer(p_point.x, p_epsilon),
			snap_float_to_integer(p_point.y, p_epsilon));
}

bool Geometry::do_shapes_match(
		const Ref<Shape2D> &p_shape_a,
		const Ref<Shape2D> &p_shape_b) {
	if (p_shape_a->is_class("CircleShape2D")) {
		if (p_shape_b->is_class("CircleShape2D")) {
			CircleShape2D *circle_a =
					Object::cast_to<CircleShape2D>(p_shape_a.ptr());
			CircleShape2D *circle_b =
					Object::cast_to<CircleShape2D>(p_shape_b.ptr());
			return circle_a->get_radius() == circle_b->get_radius();
		}
	} else if (p_shape_a->is_class("CapsuleShape2D")) {
		if (p_shape_b->is_class("CapsuleShape2D")) {
			CapsuleShape2D *capsule_a =
					Object::cast_to<CapsuleShape2D>(p_shape_a.ptr());
			CapsuleShape2D *capsule_b =
					Object::cast_to<CapsuleShape2D>(p_shape_b.ptr());
			return capsule_a->get_radius() == capsule_b->get_radius() &&
					capsule_a->get_height() == capsule_b->get_height();
		}
	} else if (p_shape_a->is_class("RectangleShape2D")) {
		if (p_shape_b->is_class("RectangleShape2D")) {
			RectangleShape2D *rectangle_a =
					Object::cast_to<RectangleShape2D>(p_shape_a.ptr());
			RectangleShape2D *rectangle_b =
					Object::cast_to<RectangleShape2D>(p_shape_b.ptr());
			return rectangle_a->get_size() == rectangle_b->get_size();
		}
	} else {
		ENSURE(false,
			   vformat("Invalid Shape2D provided for do_shapes_match: %s. "
					   "Supported shapes are: CircleShape2D, "
					   "CapsuleShape2D, "
					   "RectangleShape2D.",
					   p_shape_a->to_string()));
	}
	return false;
}

Vector2 Geometry::calculate_half_width_height(
		const Ref<Shape2D> &p_shape,
		bool p_is_rotated_90_degrees) {
	Vector2 half_width_height = vector2_invalid;

	if (CircleShape2D *circle = Object::cast_to<CircleShape2D>(p_shape.ptr())) {
		half_width_height = Vector2(circle->get_radius(), circle->get_radius());
	} else if (
			CapsuleShape2D *capsule =
					Object::cast_to<CapsuleShape2D>(p_shape.ptr())) {
		half_width_height =
				Vector2(capsule->get_radius(),
						capsule->get_radius() + capsule->get_height() / 2.0f);
	} else if (
			RectangleShape2D *rectangle =
					Object::cast_to<RectangleShape2D>(p_shape.ptr())) {
		half_width_height = rectangle->get_size() / 2.0f;
	} else {
		ENSURE(false,
			   vformat("Invalid Shape2D provided to "
					   "calculate_half_width_height: %s. Supported shapes "
					   "are: "
					   "CircleShape2D, CapsuleShape2D, RectangleShape2D.",
					   p_shape->to_string()));
	}

	if (p_is_rotated_90_degrees) {
		std::swap(half_width_height.x, half_width_height.y);
	}

	return half_width_height;
}

Vector2 Geometry::world_to_tile_map_layer(
		const Vector2 &p_position,
		const TileMapLayer *p_tile_map_layer) {
	const Vector2 position_map_coord =
			(p_position - p_tile_map_layer->get_position()) /
			p_tile_map_layer->get_tile_set()->get_tile_size();
	return Vector2(
			Math::floor(position_map_coord.x),
			Math::floor(position_map_coord.y));
}

Vector2 Geometry::tile_map_layer_to_world(
		const Vector2 &p_position,
		const TileMapLayer *p_tile_map_layer) {
	return p_tile_map_layer->get_position() +
			p_position * p_tile_map_layer->get_tile_set()->get_tile_size();
}

int Geometry::get_tile_map_layer_index_from_world_coord(
		const Vector2 &p_position,
		const TileMapLayer *p_tile_map_layer) {
	const Vector2 position_grid_coord =
			world_to_tile_map_layer(p_position, p_tile_map_layer);
	return get_tile_map_layer_index_from_grid_coord(
			position_grid_coord, p_tile_map_layer);
}

int Geometry::get_tile_map_layer_index_from_grid_coord(
		const Vector2 &p_position,
		const TileMapLayer *p_tile_map_layer) {
	const Rect2i used_rect = p_tile_map_layer->get_used_rect();
	const Vector2 tile_map_start(used_rect.position.x, used_rect.position.y);
	const int tile_map_width = static_cast<int>(used_rect.size.x);
	const Vector2 tile_map_position = p_position - tile_map_start;
	return static_cast<int>(tile_map_position.y) * tile_map_width +
			static_cast<int>(tile_map_position.x);
}

Vector2 Geometry::get_grid_coord_from_tile_map_layer_index(
		int p_index,
		const TileMapLayer *p_tile_map_layer) {
	const Rect2i used_rect = p_tile_map_layer->get_used_rect();
	const Vector2i tile_size =
			p_tile_map_layer->get_tile_set()->get_tile_size();
	const Vector2 tile_map_grid_offset(
			used_rect.position.x / tile_size.x,
			used_rect.position.y / tile_size.y);
	const int tile_map_width = static_cast<int>(used_rect.size.x);
	const int tile_map_position_x = p_index % tile_map_width;
	const int tile_map_position_y = p_index / tile_map_width;
	return Vector2(tile_map_position_x, tile_map_position_y) +
			tile_map_grid_offset;
}

Rect2 Geometry::get_tile_map_layer_bounds_in_world_coordinates(
		const TileMapLayer *p_tile_map_layer) {
	const Rect2i used_rect = p_tile_map_layer->get_used_rect();
	const Vector2i tile_size =
			p_tile_map_layer->get_tile_set()->get_tile_size();
	return Rect2(
			p_tile_map_layer->get_position().x +
					used_rect.position.x * tile_size.x,
			p_tile_map_layer->get_position().y +
					used_rect.position.y * tile_size.y,
			used_rect.size.x * tile_size.x, used_rect.size.y * tile_size.y);
}

Vector2 Geometry::get_vector2_array_front(
		const PackedVector2Array &p_vertices) {
	if (p_vertices.is_empty()) {
		return vector2_invalid;
	}
	return p_vertices[0];
}

Vector2 Geometry::get_vector2_array_back(const PackedVector2Array &p_vertices) {
	if (p_vertices.is_empty()) {
		return vector2_invalid;
	}
	return p_vertices[p_vertices.size() - 1];
}

String Geometry::get_vector_string(
		const Vector2 &p_vector,
		int p_decimal_place_count) {
	return vformat(
			"(%.*f,%.*f)", p_decimal_place_count, p_vector.x,
			p_decimal_place_count, p_vector.y);
}

Vector2 Geometry::get_perpendicular_vector(const Vector2 &p_vector) {
	return Vector2(p_vector.y, -p_vector.x);
}

bool Geometry::is_valid(const Vector2 &p_vector) {
	return !Math::is_inf(p_vector.x) && Math::is_inf(p_vector.y);
}

float Geometry::get_radius(const Ref<Shape2D> &p_shape) {
	if (const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_shape.ptr())) {
		return circle->get_radius();
	} else if (
			const CapsuleShape2D *capsule =
					Object::cast_to<CapsuleShape2D>(p_shape.ptr())) {
		return capsule->get_radius();
	} else {
		ENSURE(false, "Geometry.get_radius: Invalid shape.");
		return Math_INF;
	}
}

Vector2 Geometry::get_furthest_shape_boundary_point_in_direction(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Vector2 &p_direction) {
	if (const CircleShape2D *circle =
				Object::cast_to<CircleShape2D>(p_shape->get_shape().ptr())) {
		return p_shape_position + circle->get_radius() * p_direction;

	} else if (
			const RectangleShape2D *rect = Object::cast_to<RectangleShape2D>(
					p_shape->get_shape().ptr())) {
		const Vector2 extents = rect->get_size() / 2.0f;
		if (p_direction.x == 0.0) {
			return p_shape_position + Vector2(0.0, extents.y * p_direction.y);
		} else if (p_direction.y == 0.0) {
			return p_shape_position + Vector2(extents.x * p_direction.x, 0.0);
		} else if (p_direction.x < 0.0 && p_direction.y < 0.0) {
			return p_shape_position + Vector2(-extents.x, -extents.y);
		} else if (p_direction.x < 0.0 && p_direction.y > 0.0) {
			return p_shape_position + Vector2(-extents.x, extents.y);
		} else if (p_direction.x > 0.0 && p_direction.y < 0.0) {
			return p_shape_position + Vector2(extents.x, -extents.y);
		} else { // p_direction.x > 0.0 && p_direction.y > 0.0
			return p_shape_position + Vector2(extents.x, extents.y);
		}

	} else if (
			const CapsuleShape2D *capsule = Object::cast_to<CapsuleShape2D>(
					p_shape->get_shape().ptr())) {
		const double radius = capsule->get_radius();
		const double height = capsule->get_height();
		if (p_shape->get_is_rotated_90_degrees()) {
			if (p_direction.x == 0.0) {
				return p_shape_position + Vector2(0.0, radius * p_direction.y);
			} else if (p_direction.x < 0.0) {
				const Vector2 capsule_end_center =
						p_shape_position + Vector2(-height * 0.5, 0.0);
				return capsule_end_center + radius * p_direction;
			} else { // p_direction.x > 0.0
				const Vector2 capsule_end_center =
						p_shape_position + Vector2(height * 0.5, 0.0);
				return capsule_end_center + radius * p_direction;
			}
		} else {
			if (p_direction.y == 0.0) {
				return p_shape_position + Vector2(radius * p_direction.x, 0.0);
			} else if (p_direction.y < 0.0) {
				const Vector2 capsule_end_center =
						p_shape_position + Vector2(0.0, -height * 0.5);
				return capsule_end_center + radius * p_direction;
			} else { // p_direction.y > 0.0
				const Vector2 capsule_end_center =
						p_shape_position + Vector2(0.0, height * 0.5);
				return capsule_end_center + radius * p_direction;
			}
		}
	}

	ENSURE(false,
		   "Geometry::get_furthest_shape_boundary_point_in_direction: "
		   "Unsupported shape type");
	return vector2_invalid;
}

bool Geometry::check_for_shape_to_rect_intersection(
		const Vector2 &p_shape_position,
		const Ref<RotatedShape> &p_shape,
		const Rect2 &p_rect,
		float p_epsilon) {
	const Vector2 half_width_height = p_shape->get_half_width_height();
	return p_rect.position.x <
			p_shape_position.x + half_width_height.x + p_epsilon &&
			p_rect.get_end().x >
			p_shape_position.x - half_width_height.x - p_epsilon &&
			p_rect.position.y <
			p_shape_position.y + half_width_height.y + p_epsilon &&
			p_rect.get_end().y >
			p_shape_position.y - half_width_height.y - p_epsilon;
}
