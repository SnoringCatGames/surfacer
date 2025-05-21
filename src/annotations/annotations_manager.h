#ifndef ANNOTATIONS_MANAGER_H
#define ANNOTATIONS_MANAGER_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class AnnotationsManager : public RefCounted {
	GDCLASS(AnnotationsManager, RefCounted)

public:
	AnnotationsManager() {}
	~AnnotationsManager() {}
	
protected:
	static void _bind_methods();
};

} //namespace godot

#endif
