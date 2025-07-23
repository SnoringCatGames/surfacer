#ifndef SURFACE_ANNOTATION_H
#define SURFACE_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class GDE_EXPORT SurfaceAnnotation : public RefCounted {
	GDCLASS(SurfaceAnnotation, RefCounted)

public:
	SurfaceAnnotation() = default;
	~SurfaceAnnotation() = default;

protected:
	static void _bind_methods();
};

} //namespace godot

#endif
