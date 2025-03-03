#ifndef SURFACER_AGENT_H
#define SURFACER_AGENT_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfacerAgent : public RefCounted {
	GDCLASS(SurfacerAgent, RefCounted)

private:

protected:
	static void _bind_methods();

public:
	SurfacerAgent();
	~SurfacerAgent();
};

}

#endif
