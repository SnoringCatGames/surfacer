#include "surface.h"

#include "scaffolder/geometry.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// FIXME: REVIEW ALL BINDINGS FOR DEFAULT VALUES (Use DEFVAL()).

Vector2 Surface::get_normal_from_side(Side p_side) {
	switch (p_side) {
		case Side::FLOOR:
			return vector2_up;
		case Side::CEILING:
			return vector2_down;
		case Side::LEFT_WALL:
			return vector2_right;
		case Side::RIGHT_WALL:
			return vector2_left;
		case Side::UNKNOWN_SIDE:
		default: {
			return vector2_invalid;
		}
	}
}

void Surface::set_vertices(const PackedVector2Array &p_vertices) {
	vertices = p_vertices;
	bounding_box = Geometry::get_bounding_box_for_points(vertices);
}

Vector2 Surface::get_first_point() const {
	return Geometry::get_vector2_array_front(vertices);
}

Vector2 Surface::get_last_point() const {
	return Geometry::get_vector2_array_back(vertices);
}

String Surface::to_string(bool p_verbose) const {
	if (p_verbose) {
		return vformat(
				"Surface{ %s, [ %s, %s ] }", side_to_string(side),
				get_first_point(), get_last_point());
	} else {
		return vformat(
				"%s%s", side_to_prefix_string(side),
				Geometry::get_vector_string(get_first_point(), 1));
	}
}

void Surface::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_side"), &Surface::get_side);
	ClassDB::bind_method(D_METHOD("set_side", "side"), &Surface::set_side);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "side"), "set_side", "get_side");

	ClassDB::bind_method(D_METHOD("get_properties"), &Surface::get_properties);
	ClassDB::bind_method(
			D_METHOD("set_properties", "properties"), &Surface::set_properties);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "properties"), "set_properties",
			"get_properties");

	ClassDB::bind_method(D_METHOD("get_vertices"), &Surface::get_vertices);
	ClassDB::bind_method(
			D_METHOD("set_vertices", "vertices"), &Surface::set_vertices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "vertices"),
			"set_vertices", "get_vertices");

	ClassDB::bind_method(
			D_METHOD("get_bounding_box"), &Surface::get_bounding_box);
	ClassDB::bind_method(
			D_METHOD("set_bounding_box", "bounding_box"),
			&Surface::set_bounding_box);
	ADD_PROPERTY(
			PropertyInfo(Variant::RECT2, "bounding_box"), "set_bounding_box",
			"get_bounding_box");

	ClassDB::bind_method(D_METHOD("get_chunk"), &Surface::get_chunk);
	ClassDB::bind_method(D_METHOD("set_chunk", "chunk"), &Surface::set_chunk);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "chunk"), "set_chunk", "get_chunk");

	ClassDB::bind_method(
			D_METHOD("get_tile_map_layer"), &Surface::get_tile_map_layer);
	ClassDB::bind_method(
			D_METHOD("set_tile_map_layer", "tile_map_layer"),
			&Surface::set_tile_map_layer);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "tile_map_layer"),
			"set_tile_map_layer", "get_tile_map_layer");

	ClassDB::bind_method(
			D_METHOD("get_tile_map_indices"), &Surface::get_tile_map_indices);
	ClassDB::bind_method(
			D_METHOD("set_tile_map_indices", "tile_map_indices"),
			&Surface::set_tile_map_indices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_INT32_ARRAY, "tile_map_indices"),
			"set_tile_map_indices", "get_tile_map_indices");

	ClassDB::bind_method(
			D_METHOD("get_clockwise_neighbor_curvature"),
			&Surface::get_clockwise_neighbor_curvature);
	ClassDB::bind_method(
			D_METHOD(
					"set_clockwise_neighbor_curvature",
					"clockwise_neighbor_curvature"),
			&Surface::set_clockwise_neighbor_curvature);
	ADD_PROPERTY(
			PropertyInfo(Variant::INT, "clockwise_neighbor_curvature"),
			"set_clockwise_neighbor_curvature",
			"get_clockwise_neighbor_curvature");

	ClassDB::bind_method(
			D_METHOD("get_clockwise_neighbor"),
			&Surface::get_clockwise_neighbor);
	ClassDB::bind_method(
			D_METHOD("set_clockwise_neighbor", "clockwise_neighbor"),
			&Surface::set_clockwise_neighbor);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "clockwise_neighbor"),
			"set_clockwise_neighbor", "get_clockwise_neighbor");

	ClassDB::bind_method(
			D_METHOD("get_counter_clockwise_neighbor_curvature"),
			&Surface::get_counter_clockwise_neighbor_curvature);
	ClassDB::bind_method(
			D_METHOD(
					"set_counter_clockwise_neighbor_curvature",
					"counter_clockwise_neighbor_curvature"),
			&Surface::set_counter_clockwise_neighbor_curvature);
	ADD_PROPERTY(
			PropertyInfo(Variant::INT, "counter_clockwise_neighbor_curvature"),
			"set_counter_clockwise_neighbor_curvature",
			"get_counter_clockwise_neighbor_curvature");

	ClassDB::bind_method(
			D_METHOD("get_counter_clockwise_neighbor"),
			&Surface::get_counter_clockwise_neighbor);
	ClassDB::bind_method(
			D_METHOD(
					"set_counter_clockwise_neighbor",
					"counter_clockwise_neighbor"),
			&Surface::set_counter_clockwise_neighbor);
	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "counter_clockwise_neighbor"),
			"set_counter_clockwise_neighbor", "get_counter_clockwise_neighbor");

	// Read-only property.
	ClassDB::bind_method(D_METHOD("get_normal"), &Surface::get_normal);
	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "normal"), "", "get_normal");

	ClassDB::bind_method(
			D_METHOD("get_clockwise_convex_neighbor"),
			&Surface::get_clockwise_convex_neighbor);
	ClassDB::bind_method(
			D_METHOD("get_clockwise_concave_neighbor"),
			&Surface::get_clockwise_concave_neighbor);
	ClassDB::bind_method(
			D_METHOD("get_clockwise_collinear_neighbor"),
			&Surface::get_clockwise_collinear_neighbor);

	ClassDB::bind_method(
			D_METHOD("get_counter_clockwise_convex_neighbor"),
			&Surface::get_counter_clockwise_convex_neighbor);
	ClassDB::bind_method(
			D_METHOD("get_counter_clockwise_concave_neighbor"),
			&Surface::get_counter_clockwise_concave_neighbor);
	ClassDB::bind_method(
			D_METHOD("get_counter_clockwise_collinear_neighbor"),
			&Surface::get_counter_clockwise_collinear_neighbor);

	ClassDB::bind_method(
			D_METHOD("get_first_point"), &Surface::get_first_point);
	ClassDB::bind_method(D_METHOD("get_last_point"), &Surface::get_last_point);
	ClassDB::bind_method(
			D_METHOD("get_is_single_vertex"), &Surface::get_is_single_vertex);
	ClassDB::bind_method(
			D_METHOD("get_bounds_center"), &Surface::get_bounds_center);
	ClassDB::bind_method(D_METHOD("to_string", "verbose"), &Surface::to_string);

	ClassDB::bind_static_method(
			"Surface", D_METHOD("get_normal_from_side", "side"),
			&Surface::get_normal_from_side);

	BIND_ENUM_CONSTANT(UNKNOWN_SIDE);
	BIND_ENUM_CONSTANT(FLOOR);
	BIND_ENUM_CONSTANT(CEILING);
	BIND_ENUM_CONSTANT(LEFT_WALL);
	BIND_ENUM_CONSTANT(RIGHT_WALL);

	BIND_ENUM_CONSTANT(UNKNOWN_CURVATURE);
	BIND_ENUM_CONSTANT(COLLINEAR);
	BIND_ENUM_CONSTANT(CONVEX);
	BIND_ENUM_CONSTANT(CONCAVE);
}
