#ifndef SURFACE_PROPERTIES_H
#define SURFACE_PROPERTIES_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceProperties : public RefCounted {
	GDCLASS(SurfaceProperties, RefCounted)

public:
	SurfaceProperties() = default;
	~SurfaceProperties() = default;

	void set_name(const StringName &p_name) { name = p_name; }
	const StringName &get_name() const { return name; }

	void set_can_grab(bool p_can_grab) { can_grab = p_can_grab; }
	bool get_can_grab() const { return can_grab; }

	void set_friction_multiplier(float p_friction_multiplier) {
		friction_multiplier = p_friction_multiplier;
	}
	float get_friction_multiplier() const { return friction_multiplier; }

	void set_speed_multiplier(float p_speed_multiplier) {
		speed_multiplier = p_speed_multiplier;
	}
	float get_speed_multiplier() const { return speed_multiplier; }

protected:
	static void _bind_methods();

private:
	// TODO: Use these.

	// TODO:
	// - Add some way of checking fall - through / walk - through state.
	// - And add a way to validate that this matches the normal TileSet
	// encoding.

	StringName name;
	bool can_grab = true;
	float friction_multiplier = 1.0f;
	float speed_multiplier = 1.0f;
};

} //namespace godot

#endif
