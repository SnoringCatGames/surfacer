#include "collision_surface_result.h"

// Make sure surface.h is included if it defines Surface::Side and Surface
// #include "surface.h"

using namespace godot;

CollisionSurfaceResult::CollisionSurfaceResult() {
	_surface_side = Surface::Side::UNKNOWN_SIDE; // Or your equivalent of NONE
	_surface = nullptr;
	_tilemap_coord = Vector2(INFINITY, INFINITY);
	_tilemap_index = -1;
	_flipped_sides_for_nested_call = false;
	_error_message = "";
}

CollisionSurfaceResult::~CollisionSurfaceResult() {}

void CollisionSurfaceResult::_bind_methods() {
	// Bind methods (getters, setters, reset)
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
					"Unknown,Floor,Ceiling,LeftWall,RightWall"),
			"set_surface_side",
			"get_surface_side"); // Adjust HINT_ENUM string as per your
								 // Surface::Side definition

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
	_surface_side = Surface::Side::UNKNOWN_SIDE; // Or your equivalent of NONE
	_surface = nullptr;
	_tilemap_coord = Vector2(INFINITY, INFINITY);
	_tilemap_index = -1;
	_flipped_sides_for_nested_call = false;
	_error_message = "";
}

// Getters
Surface::Side CollisionSurfaceResult::get_surface_side() const {
	return _surface_side;
}

Ref<Surface> CollisionSurfaceResult::get_surface() const { return _surface; }

Vector2 CollisionSurfaceResult::get_tilemap_coord() const {
	return _tilemap_coord;
}

int CollisionSurfaceResult::get_tilemap_index() const { return _tilemap_index; }

bool CollisionSurfaceResult::get_flipped_sides_for_nested_call() const {
	return _flipped_sides_for_nested_call;
}

String CollisionSurfaceResult::get_error_message() const {
	return _error_message;
}

// Setters
void CollisionSurfaceResult::set_surface_side(Surface::Side p_side) {
	_surface_side = p_side;
}

void CollisionSurfaceResult::set_surface(const Ref<Surface> &p_surface) {
	_surface = p_surface;
}

void CollisionSurfaceResult::set_tilemap_coord(const Vector2 &p_coord) {
	_tilemap_coord = p_coord;
}

void CollisionSurfaceResult::set_tilemap_index(int p_index) {
	_tilemap_index = p_index;
}

void CollisionSurfaceResult::set_flipped_sides_for_nested_call(bool p_flipped) {
	_flipped_sides_for_nested_call = p_flipped;
}

void CollisionSurfaceResult::set_error_message(const String &p_message) {
	_error_message = p_message;
}