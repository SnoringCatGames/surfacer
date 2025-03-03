#ifndef ANNOTATIONS_MANAGER_H
#define ANNOTATIONS_MANAGER_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class AnnotationsManager : public RefCounted {
	GDCLASS(AnnotationsManager, RefCounted)

private:

protected:
	static void _bind_methods();

public:
	AnnotationsManager();
	~AnnotationsManager();
};

}

#endif
