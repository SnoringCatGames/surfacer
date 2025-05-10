#include "tile_shape_data.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// FIXME: REVIEW THIS.

void TileShapeData::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_tileset_index"), &TileShapeData::get_tileset_index);
	ClassDB::bind_method(
			D_METHOD("set_tileset_index", "index"),
			&TileShapeData::set_tileset_index);
	ADD_PROPERTY(
			PropertyInfo(Variant::INT, "tileset_index"), "set_tileset_index",
			"get_tileset_index");

	ClassDB::bind_method(
			D_METHOD("get_top_vertices"), &TileShapeData::get_top_vertices);
	ClassDB::bind_method(
			D_METHOD("set_top_vertices", "vertices"),
			&TileShapeData::set_top_vertices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "top_vertices"),
			"set_top_vertices", "get_top_vertices");

	ClassDB::bind_method(
			D_METHOD("get_right_vertices"), &TileShapeData::get_right_vertices);
	ClassDB::bind_method(
			D_METHOD("set_right_vertices", "vertices"),
			&TileShapeData::set_right_vertices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "right_vertices"),
			"set_right_vertices", "get_right_vertices");

	ClassDB::bind_method(
			D_METHOD("get_bottom_vertices"),
			&TileShapeData::get_bottom_vertices);
	ClassDB::bind_method(
			D_METHOD("set_bottom_vertices", "vertices"),
			&TileShapeData::set_bottom_vertices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "bottom_vertices"),
			"set_bottom_vertices", "get_bottom_vertices");

	ClassDB::bind_method(
			D_METHOD("get_left_vertices"), &TileShapeData::get_left_vertices);
	ClassDB::bind_method(
			D_METHOD("set_left_vertices", "vertices"),
			&TileShapeData::set_left_vertices);
	ADD_PROPERTY(
			PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "left_vertices"),
			"set_left_vertices", "get_left_vertices");

	ClassDB::bind_method(
			D_METHOD("get_is_top_axially_aligned"),
			&TileShapeData::get_is_top_axially_aligned);
	ClassDB::bind_method(
			D_METHOD("set_is_top_axially_aligned", "is_axially_aligned"),
			&TileShapeData::set_is_top_axially_aligned);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_top_axially_aligned"),
			"set_is_top_axially_aligned", "get_is_top_axially_aligned");

	ClassDB::bind_method(
			D_METHOD("get_is_right_axially_aligned"),
			&TileShapeData::get_is_right_axially_aligned);
	ClassDB::bind_method(
			D_METHOD("set_is_right_axially_aligned", "is_axially_aligned"),
			&TileShapeData::set_is_right_axially_aligned);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_right_axially_aligned"),
			"set_is_right_axially_aligned", "get_is_right_axially_aligned");

	ClassDB::bind_method(
			D_METHOD("get_is_bottom_axially_aligned"),
			&TileShapeData::get_is_bottom_axially_aligned);
	ClassDB::bind_method(
			D_METHOD("set_is_bottom_axially_aligned", "is_axially_aligned"),
			&TileShapeData::set_is_bottom_axially_aligned);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_bottom_axially_aligned"),
			"set_is_bottom_axially_aligned", "get_is_bottom_axially_aligned");

	ClassDB::bind_method(
			D_METHOD("get_is_left_axially_aligned"),
			&TileShapeData::get_is_left_axially_aligned);
	ClassDB::bind_method(
			D_METHOD("set_is_left_axially_aligned", "is_axially_aligned"),
			&TileShapeData::set_is_left_axially_aligned);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_left_axially_aligned"),
			"set_is_left_axially_aligned", "get_is_left_axially_aligned");

	ClassDB::bind_method(
			D_METHOD("get_is_top_along_cell_boundary"),
			&TileShapeData::get_is_top_along_cell_boundary);
	ClassDB::bind_method(
			D_METHOD(
					"set_is_top_along_cell_boundary", "is_along_cell_boundary"),
			&TileShapeData::set_is_top_along_cell_boundary);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_top_along_cell_boundary"),
			"set_is_top_along_cell_boundary", "get_is_top_along_cell_boundary");

	ClassDB::bind_method(
			D_METHOD("get_is_right_along_cell_boundary"),
			&TileShapeData::get_is_right_along_cell_boundary);
	ClassDB::bind_method(
			D_METHOD(
					"set_is_right_along_cell_boundary",
					"is_along_cell_boundary"),
			&TileShapeData::set_is_right_along_cell_boundary);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_right_along_cell_boundary"),
			"set_is_right_along_cell_boundary",
			"get_is_right_along_cell_boundary");

	ClassDB::bind_method(
			D_METHOD("get_is_bottom_along_cell_boundary"),
			&TileShapeData::get_is_bottom_along_cell_boundary);
	ClassDB::bind_method(
			D_METHOD(
					"set_is_bottom_along_cell_boundary",
					"is_along_cell_boundary"),
			&TileShapeData::set_is_bottom_along_cell_boundary);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_bottom_along_cell_boundary"),
			"set_is_bottom_along_cell_boundary",
			"get_is_bottom_along_cell_boundary");

	ClassDB::bind_method(
			D_METHOD("get_is_left_along_cell_boundary"),
			&TileShapeData::get_is_left_along_cell_boundary);
	ClassDB::bind_method(
			D_METHOD(
					"set_is_left_along_cell_boundary",
					"is_along_cell_boundary"),
			&TileShapeData::set_is_left_along_cell_boundary);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_left_along_cell_boundary"),
			"set_is_left_along_cell_boundary",
			"get_is_left_along_cell_boundary");
}
