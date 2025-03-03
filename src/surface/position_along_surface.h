#ifndef POSITION_ALONG_SURFACE_H
#define POSITION_ALONG_SURFACE_H

#include "surface/surface.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// FIXME: LEFT OFF HERE: ---------------

// - Represents a position along a surface.
// - Rather than considering polyline length, this only specifies the position
//   along the axis the surface is aligned to.
// - The position always indicates the center of the character's bounding
//   box.
class PositionAlongSurface : public RefCounted {
	GDCLASS(PositionAlongSurface, RefCounted)

private:
	Ref<Surface> surface;
	Vector2 target_position;

protected:
	static void _bind_methods();

public:
	PositionAlongSurface();
	~PositionAlongSurface();

	void set_surface(Ref<Surface> p_surface) { surface = p_surface; }
	Ref<Surface> get_surface() const { return surface; }

	void set_target_position(Vector2 p_target_position) { target_position = p_target_position; }
	Vector2 get_target_position() const { return target_position; }
};

}

#endif
