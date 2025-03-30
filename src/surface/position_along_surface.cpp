#include "surface/position_along_surface.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// TODO: Implement.

void PositionAlongSurface::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_surface"), &PositionAlongSurface::get_surface);
	ClassDB::bind_method(D_METHOD("set_surface", "p_surface"), &PositionAlongSurface::set_surface);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "surface"), "set_surface", "get_surface");

	ClassDB::bind_method(D_METHOD("get_target_position"), &PositionAlongSurface::get_target_position);
	ClassDB::bind_method(D_METHOD("set_target_position", "p_target_position"), &PositionAlongSurface::set_target_position);

	ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "target_position"), "set_target_position", "get_target_position");
}

PositionAlongSurface::PositionAlongSurface() {
}

PositionAlongSurface::~PositionAlongSurface() {
}
