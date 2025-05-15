#ifndef ROTATED_SHAPE_H
#define ROTATED_SHAPE_H

#include "scaffolder/geometry.h"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class RotatedShape : public RefCounted {
	GDCLASS(RotatedShape, RefCounted)

public:
	RotatedShape() = default;
	~RotatedShape() = default;

	Ref<Shape2D> get_shape() const { return shape; }
	void set_shape(const Ref<Shape2D> &p_shape);

	double get_rotation() const { return rotation; }
	void set_rotation(double p_rotation);

	bool get_is_rotated_90_degrees() const;
	bool get_is_axially_aligned() const;

	Vector2 get_half_width_height() const { return half_width_height; }

	void set_up(
			const Ref<Shape2D> &p_shape = nullptr,
			double p_rotation = Math_INF);

	void reset();

protected:
	static void _bind_methods();

private:
	Ref<Shape2D> shape;
	double rotation = Math_INF;
	Vector2 half_width_height = vector2_invalid;
};

} // namespace godot

#endif
