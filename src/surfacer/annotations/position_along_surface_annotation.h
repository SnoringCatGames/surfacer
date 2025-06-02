#ifndef POSITION_ALONG_SURFACE_ANNOTATION_H
#define POSITION_ALONG_SURFACE_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class PositionAlongSurfaceAnnotation : public RefCounted {
	GDCLASS(PositionAlongSurfaceAnnotation, RefCounted)

public:
	PositionAlongSurfaceAnnotation() = default;
	~PositionAlongSurfaceAnnotation() = default;

protected:
	static void _bind_methods();
};

} //namespace godot

#endif
