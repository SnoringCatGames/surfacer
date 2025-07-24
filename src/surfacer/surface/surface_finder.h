#ifndef SURFACE_FINDER_H
#define SURFACE_FINDER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class SurfaceFinder;

class SurfaceFinder : public RefCounted {
	GDCLASS(SurfaceFinder, RefCounted);

public:
	SurfaceFinder() = default;
	~SurfaceFinder() = default;

	// FIXME: Port.

protected:
	static void _bind_methods();

private:
};

} // namespace godot

#endif // SURFACE_FINDER_H
