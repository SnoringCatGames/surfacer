#ifndef MOVEMENT_PROFILE_H
#define MOVEMENT_PROFILE_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

// TODO: Update this to extend Resource.
class MovementProfile : public RefCounted {
	GDCLASS(MovementProfile, RefCounted)

private:

protected:
	static void _bind_methods();

public:
	MovementProfile();
	~MovementProfile();
};

}

#endif
