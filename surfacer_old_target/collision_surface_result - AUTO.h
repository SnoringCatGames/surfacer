#ifndef COLLISION_SURFACE_RESULT_H
#define COLLISION_SURFACE_RESULT_H

#include <godot_cpp/classes/reference.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp> // For INFINITY
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/vector2.hpp>

// Assuming Surface::Side enum and Surface class are defined/included elsewhere
// For example, if SurfaceSide is part of a Surface class:
#include "surface.h" // Assuming this defines godot::Surface and godot::Surface::Side

namespace godot {

class CollisionSurfaceResult : public Reference {
	GDCLASS(CollisionSurfaceResult, Reference);

private:
	Surface::Side _surface_side;
	Ref<Surface> _surface;
	Vector2 _tilemap_coord;
	int _tilemap_index;
	bool _flipped_sides_for_nested_call;
	String _error_message;

protected:
	static void _bind_methods();

public:
	CollisionSurfaceResult();
	~CollisionSurfaceResult();

	void reset();

	// Getters
	Surface::Side get_surface_side() const;
	Ref<Surface> get_surface() const;
	Vector2 get_tilemap_coord() const;
	int get_tilemap_index() const;
	bool get_flipped_sides_for_nested_call() const;
	String get_error_message() const;

	// Setters
	void set_surface_side(Surface::Side p_side);
	void set_surface(const Ref<Surface> &p_surface);
	void set_tilemap_coord(const Vector2 &p_coord);
	void set_tilemap_index(int p_index);
	void set_flipped_sides_for_nested_call(bool p_flipped);
	void set_error_message(const String &p_message);
};

} // namespace godot

#endif // COLLISION_SURFACE_RESULT_H