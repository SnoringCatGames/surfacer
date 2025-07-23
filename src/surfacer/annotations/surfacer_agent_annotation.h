#ifndef SURFACER_AGENT_ANNOTATION_H
#define SURFACER_AGENT_ANNOTATION_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class GDE_EXPORT SurfacerAgentAnnotation : public RefCounted {
	GDCLASS(SurfacerAgentAnnotation, RefCounted)

public:
	SurfacerAgentAnnotation() = default;
	~SurfacerAgentAnnotation() = default;

protected:
	static void _bind_methods();
};

} //namespace godot

#endif // SURFACER_AGENT_ANNOTATION_H
