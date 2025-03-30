#ifndef SURFACER_AGENT_ANNOTATION_H
#define SURFACER_AGENT_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfacerAgentAnnotation : public RefCounted {
	GDCLASS(SurfacerAgentAnnotation, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	SurfacerAgentAnnotation();
	~SurfacerAgentAnnotation();
};

} //namespace godot

#endif
