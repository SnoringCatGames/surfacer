#ifndef COLLISION_SURFACE_RESULT_H
#define COLLISION_SURFACE_RESULT_H

#include "snore_core/internal_utils.h"
#include "surfacer/surface/surface.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class CollisionSurfaceResult : public RefCounted {
	GDCLASS(CollisionSurfaceResult, RefCounted);

public:
	CollisionSurfaceResult() = default;
	~CollisionSurfaceResult() = default;

	void reset();

	Surface::Side get_surface_side() const { return surface_side; }
	void set_surface_side(Surface::Side p_side) { surface_side = p_side; }

	Ref<Surface> get_surface() const { return surface; }
	void set_surface(const Ref<Surface> &p_surface) { surface = p_surface; }

	Vector2 get_tilemap_coord() const { return tilemap_coord; }
	void set_tilemap_coord(const Vector2 &p_coord) { tilemap_coord = p_coord; }

	int get_tilemap_index() const { return tilemap_index; }
	void set_tilemap_index(int p_index) { tilemap_index = p_index; }

	bool get_flipped_sides_for_nested_call() const {
		return flipped_sides_for_nested_call;
	}
	void set_flipped_sides_for_nested_call(bool p_flipped) {
		flipped_sides_for_nested_call = p_flipped;
	}

	String get_error_message() const { return error_message; }
	void set_error_message(const String &p_message) {
		error_message = p_message;
	}

protected:
	static void _bind_methods();

private:
	// In case the SurfacerCharacter is colliding with multiple sides, this
	// should indicate which side tilemap_coord corresponds to.
	Surface::Side surface_side = Surface::Side::UNKNOWN_SIDE;
	Ref<Surface> surface;
	Vector2 tilemap_coord = vector2_invalid;
	int tilemap_index = -1;
	bool flipped_sides_for_nested_call = false;
	String error_message;
};

} // namespace godot

#endif // COLLISION_SURFACE_RESULT_H
