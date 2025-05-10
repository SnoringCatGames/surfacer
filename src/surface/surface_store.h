#ifndef SURFACE_STORE_H
#define SURFACE_STORE_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class SurfaceStore : public RefCounted {
	GDCLASS(SurfaceStore, RefCounted)

public:
	SurfaceStore() = default;
	~SurfaceStore() = default;

protected:
	static void _bind_methods();

private:
};

} //namespace godot

#endif
