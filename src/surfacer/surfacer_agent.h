#ifndef SURFACER_AGENT_H
#define SURFACER_AGENT_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class GDE_EXPORT SurfacerAgent : public RefCounted {
	GDCLASS(SurfacerAgent, RefCounted)

public:
	SurfacerAgent() = default;
	~SurfacerAgent() = default;

protected:
	static void _bind_methods();

private:
};

} //namespace godot

#endif
