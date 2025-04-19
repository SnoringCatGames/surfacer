#ifndef SURFACER_H
#define SURFACER_H

#include <godot_cpp/core/object.hpp>

namespace godot {

class Surfacer : public Object {
	GDCLASS(Surfacer, Object)

protected:
	static void _bind_methods();

public:
	static void run_tests();
};

} //namespace godot

#endif
