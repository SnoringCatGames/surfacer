#ifndef JUMP_ANNOTATION_H
#define JUMP_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class JumpAnnotation : public RefCounted {
	GDCLASS(JumpAnnotation, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	JumpAnnotation();
	~JumpAnnotation();
};

} //namespace godot

#endif
