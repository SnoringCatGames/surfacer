#ifndef SURFACE_PROPERTIES_H
#define SURFACE_PROPERTIES_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceProperties : public RefCounted {
	GDCLASS(SurfaceProperties, RefCounted)

private:
	// TODO: Use these.

	// TODO:
	// - Add some way of checking fall - through / walk - through state.
	// - And add a way to validate that this matches the normal TileSet encoding.

	String name;
	bool can_grab = true;
	float friction_multiplier = 1.0f;
	float speed_multiplier = 1.0f;

protected:
	static void _bind_methods();

public:
	SurfaceProperties();
	~SurfaceProperties();

	void set_name(String p_name) { name = p_name; }
	String get_name() const { return name; }

	void set_can_grab(bool p_can_grab) { can_grab = p_can_grab; }
	bool get_can_grab() const { return can_grab; }

	void set_friction_multiplier(float p_friction_multiplier) { friction_multiplier = p_friction_multiplier; }
	float get_friction_multiplier() const { return friction_multiplier; }

	// - This affects the character's speed while moving along the surface.
	// - This does not affect jump start/end velocities or in-air velocities.
	// - This will modify both acceleration and max-speed.
	// - This is similar to MovementParameters.surface_speed_multiplier.
	void set_speed_multiplier(float p_speed_multiplier) { speed_multiplier = p_speed_multiplier; }
	float get_speed_multiplier() const { return speed_multiplier; }
};

} //namespace godot

#endif
