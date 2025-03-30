#ifndef SURFACE_PROPERTIES_H
#define SURFACE_PROPERTIES_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceProperties : public RefCounted {
	GDCLASS(SurfaceProperties, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	SurfaceProperties();
	~SurfaceProperties();
};

} //namespace godot

#endif
