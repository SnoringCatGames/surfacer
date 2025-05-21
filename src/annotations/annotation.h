#ifndef ANNOTATION_H
#define ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class Annotation : public RefCounted {
	GDCLASS(Annotation, RefCounted)

public:
	Annotation() {}
	~Annotation() {}
	
protected:
	static void _bind_methods();
};

} //namespace godot

#endif
