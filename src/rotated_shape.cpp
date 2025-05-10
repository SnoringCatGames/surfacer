#include "rotated_shape.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// FIXME: REVIEW THIS.

bool RotatedShape::get_is_axially_aligned() const {
	return rotation != Math_INF &&
			(is_rotated_90_degrees || ABS(rotation) < float_epsilon);
}
void RotatedShape::update(
		const Ref<Shape2D> &p_shape = nullptr,
		double p_rotation = Math_INF) {
	if (p_shape.is_valid()) {
		shape = p_shape;
	}
	if (p_rotation != Math_INF) {
		rotation = p_rotation;
	}

	if (shape.is_null() || rotation == Math_INF) {
		return;
	}

	is_rotated_90_degrees = ABS(fmod(rotation + Math_TAU, Math_PI) -
								Math_PI / 2.0) < float_epsilon;
	half_width_height = get_is_axially_aligned()
			? Geometry::calculate_half_width_height(
					  shape, is_rotated_90_degrees)
			: vector2_invalid;
}

void RotatedShape::reset() {
	shape.unref();
	rotation = Math_INF;
	is_rotated_90_degrees = false;
	half_width_height = vector2_invalid;
}

void RotatedShape::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_shape"), &RotatedShape::get_shape);
	ClassDB::bind_method(
			D_METHOD("set_shape", "shape"), &RotatedShape::set_shape);
	ADD_PROPERTY(
			PropertyInfo(
					Variant::OBJECT, "shape", PROPERTY_HINT_RESOURCE_TYPE,
					"Shape2D"),
			"set_shape", "get_shape");

	ClassDB::bind_method(D_METHOD("get_rotation"), &RotatedShape::get_rotation);
	ClassDB::bind_method(
			D_METHOD("set_rotation", "rotation"), &RotatedShape::set_rotation);
	ADD_PROPERTY(
			PropertyInfo(Variant::FLOAT, "rotation"), "set_rotation",
			"get_rotation");

	ClassDB::bind_method(
			D_METHOD("get_is_rotated_90_degrees"),
			&RotatedShape::get_is_rotated_90_degrees);
	ClassDB::bind_method(
			D_METHOD("set_is_rotated_90_degrees", "value"),
			&RotatedShape::set_is_rotated_90_degrees);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_rotated_90_degrees"),
			"set_is_rotated_90_degrees", "get_is_rotated_90_degrees");

	ClassDB::bind_method(
			D_METHOD("get_is_axially_aligned"),
			&RotatedShape::get_is_axially_aligned);
	ADD_PROPERTY(
			PropertyInfo(Variant::BOOL, "is_axially_aligned"), "",
			"get_is_axially_aligned");

	ClassDB::bind_method(
			D_METHOD("get_half_width_height"),
			&RotatedShape::get_half_width_height);
	ClassDB::bind_method(
			D_METHOD("set_half_width_height", "value"),
			&RotatedShape::set_half_width_height);
	ADD_PROPERTY(
			PropertyInfo(Variant::VECTOR2, "half_width_height"),
			"set_half_width_height", "get_half_width_height");

	ClassDB::bind_method(
			D_METHOD("update", "shape", "rotation"), &RotatedShape::update,
			DEFVAL(Ref<Shape2D>()), DEFVAL(Math_INF));
	ClassDB::bind_method(D_METHOD("reset"), &RotatedShape::reset);
}
