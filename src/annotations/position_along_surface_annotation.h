#ifndef POSITION_ALONG_SURFACE_ANNOTATION_H
#define POSITION_ALONG_SURFACE_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class PositionAlongSurfaceAnnotation : public RefCounted {
	GDCLASS(PositionAlongSurfaceAnnotation, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	PositionAlongSurfaceAnnotation();
	~PositionAlongSurfaceAnnotation();
};

} //namespace godot

#endif
