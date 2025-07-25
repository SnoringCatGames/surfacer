#include "surfacer/surface/collision_surface_result.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void CollisionSurfaceResult::_bind_methods() {
	ClassDB::bind_method(D_METHOD("reset"), &CollisionSurfaceResult::reset);

	ClassDB::bind_method(
			D_METHOD("get_surface_side"),
			&CollisionSurfaceResult::get_surface_side);
	ClassDB::bind_method(
			D_METHOD("set_surface_side", "p_side"),
			&CollisionSurfaceResult::set_surface_side);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::INT, "surface_side", PROPERTY_HINT_ENUM,
					Surface::get_side_hint_string()),
			"set_surface_side", "get_surface_side");

	ClassDB::bind_method(
			D_METHOD("get_surface"), &CollisionSurfaceResult::get_surface);
	ClassDB::bind_method(
			D_METHOD("set_surface", "p_surface"),
			&CollisionSurfaceResult::set_surface);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::OBJECT, "surface", PROPERTY_HINT_RESOURCE_TYPE,
					"Surface"),
			"set_surface", "get_surface");

	ClassDB::bind_method(
			D_METHOD("get_tilemap_coord"),
			&CollisionSurfaceResult::get_tilemap_coord);
	ClassDB::bind_method(
			D_METHOD("set_tilemap_coord", "p_coord"),
			&CollisionSurfaceResult::set_tilemap_coord);
	ADD_PROPERTY(
			PropertyInfo(Variant::VECTOR2, "tilemap_coord"),
			"set_tilemap_coord", "get_tilemap_coord");

	ClassDB::bind_method(
			D_METHOD("get_tilemap_index"),
			&CollisionSurfaceResult::get_tilemap_index);
	ClassDB::bind_method(
			D_METHOD("set_tilemap_index", "p_index"),
			&CollisionSurfaceResult::set_tilemap_index);
	ADD_PROPERTY(
			PropertyInfo(Variant::INT, "tilemap_index"), "set_tilemap_index",
			"get_tilemap_index");

	ClassDB::bind_method(
			D_METHOD("get_flipped_sides_for_nested_call"),
			&CollisionSurfaceResult::get_flipped_sides_for_nested_call);
	ClassDB::bind_method(
			D_METHOD("set_flipped_sides_for_nested_call", "p_flipped"),
			&CollisionSurfaceResult::set_flipped_sides_for_nested_call);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "flipped_sides_for_nested_call"),
			"set_flipped_sides_for_nested_call",
			"get_flipped_sides_for_nested_call");

	ClassDB::bind_method(
			D_METHOD("get_error_message"),
			&CollisionSurfaceResult::get_error_message);
	ClassDB::bind_method(
			D_METHOD("set_error_message", "p_message"),
			&CollisionSurfaceResult::set_error_message);
	ADD_PROPERTY(
			PropertyInfo(Variant::STRING, "error_message"), "set_error_message",
			"get_error_message");
}

void CollisionSurfaceResult::reset() {
	surface_side = Surface::Side::UNKNOWN_SIDE;
	surface.unref();
	tilemap_coord = vector2_invalid;
	tilemap_index = -1;
	flipped_sides_for_nested_call = false;
	error_message = "";
}
