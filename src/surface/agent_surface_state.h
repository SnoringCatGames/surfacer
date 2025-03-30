#ifndef AGENT_SURFACE_STATE_H
#define AGENT_SURFACE_STATE_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class AgentSurfaceState : public RefCounted {
	GDCLASS(AgentSurfaceState, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	AgentSurfaceState();
	~AgentSurfaceState();
};

} //namespace godot

#endif
