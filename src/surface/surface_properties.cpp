#include "surface_properties.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SurfaceProperties::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_name"), &SurfaceProperties::get_name);
	ClassDB::bind_method(
			D_METHOD("set_name", "p_name"), &SurfaceProperties::set_name);
	ADD_PROPERTY(
			PropertyInfo(Variant::STRING_NAME, "name"), "set_name", "get_name");

	ClassDB::bind_method(
			D_METHOD("get_can_grab"), &SurfaceProperties::get_can_grab);
	ClassDB::bind_method(
			D_METHOD("set_can_grab", "p_can_grab"),
			&SurfaceProperties::set_can_grab);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "can_grab"), "set_can_grab",
			"get_can_grab");

	ClassDB::bind_method(
			D_METHOD("get_friction_multiplier"),
			&SurfaceProperties::get_friction_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_friction_multiplier", "p_friction_multiplier"),
			&SurfaceProperties::set_friction_multiplier);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "friction_multiplier"),
			"set_friction_multiplier", "get_friction_multiplier");

	ClassDB::bind_method(
			D_METHOD("get_speed_multiplier"),
			&SurfaceProperties::get_speed_multiplier);
	ClassDB::bind_method(
			D_METHOD("set_speed_multiplier", "p_speed_multiplier"),
			&SurfaceProperties::set_speed_multiplier);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "speed_multiplier"),
			"set_speed_multiplier", "get_speed_multiplier");
}

SurfaceProperties::SurfaceProperties() {}

SurfaceProperties::~SurfaceProperties() {}
