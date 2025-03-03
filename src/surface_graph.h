#ifndef SURFACE_GRAPH_H
#define SURFACE_GRAPH_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceGraph : public RefCounted {
	GDCLASS(SurfaceGraph, RefCounted)

private:

protected:
	static void _bind_methods();

public:
	SurfaceGraph();
	~SurfaceGraph();
};

}

#endif
