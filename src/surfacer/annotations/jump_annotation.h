#ifndef JUMP_ANNOTATION_H
#define JUMP_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class GDE_EXPORT JumpAnnotation : public RefCounted {
	GDCLASS(JumpAnnotation, RefCounted)

public:
	JumpAnnotation() = default;
	~JumpAnnotation() = default;

protected:
	static void _bind_methods();
};

} //namespace godot

#endif
