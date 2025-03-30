#ifndef SURFACE_ANNOTATION_H
#define SURFACE_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceAnnotation : public RefCounted {
	GDCLASS(SurfaceAnnotation, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	SurfaceAnnotation();
	~SurfaceAnnotation();
};

} //namespace godot

#endif
