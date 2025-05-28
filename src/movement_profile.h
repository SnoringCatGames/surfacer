#ifndef MOVEMENT_PROFILE_H
#define MOVEMENT_PROFILE_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

// TODO: Update this to extend Resource.
class MovementProfile : public RefCounted {
	GDCLASS(MovementProfile, RefCounted)

public:
	MovementProfile() = default;
	~MovementProfile() = default;

protected:
	static void _bind_methods();

private:
	// FIXME: LEFT OFF HERE: Add these, and their getters/setters.

	// FIXME: LEFT OFF HERE: And figure out how to set up bitmasks, while
	// allowing the client app to specify tag-name options for each bit
	// (probably allow specifying names for bits in the manifest, and then allow
	// specifying multi-selecting from list of registered names, and then add a
	// function for translating string to bit).

	bool can_grab_floors = true;
	bool can_grab_walls = true;
	bool can_grab_ceilings = true;
	uint32_t character_categories = 0;
};

} //namespace godot

#endif
