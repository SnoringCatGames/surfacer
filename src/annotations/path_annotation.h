#ifndef PATH_ANNOTATION_H
#define PATH_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class PathAnnotation : public RefCounted {
	GDCLASS(PathAnnotation, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	PathAnnotation();
	~PathAnnotation();
};

} //namespace godot

#endif
