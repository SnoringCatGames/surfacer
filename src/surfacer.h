#ifndef SURFACER_H
#define SURFACER_H

#include <godot_cpp/core/object.hpp>

namespace godot {

class Surfacer : public Object {
	GDCLASS(Surfacer, Object)

public:
	// TODO: Evaluate whether this is the right place for these.
	// TODO: Sync this with the game's project settings.
	static constexpr double floor_max_angle = Math_PI / 4.0;
	static constexpr bool are_oddly_shaped_surfaces_used = true;

	static void run_tests();

protected:
	static void _bind_methods();
};

} //namespace godot

#endif
