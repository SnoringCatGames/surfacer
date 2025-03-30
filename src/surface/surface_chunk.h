#ifndef SURFACE_CHUNK_H
#define SURFACE_CHUNK_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/typed_array.hpp>

namespace godot {

class Surface;

class SurfaceChunk : public RefCounted {
	GDCLASS(SurfaceChunk, RefCounted)

private:
	TypedArray<Surface> surfaces;
	Rect2 bounding_box;

protected:
	static void _bind_methods();

public:
	SurfaceChunk();
	~SurfaceChunk();

	void set_surfaces(TypedArray<Surface> p_surfaces);
	TypedArray<Surface> get_surfaces() const;

	void set_bounding_box(Rect2 p_bounding_box) { bounding_box = p_bounding_box; }
	Rect2 get_bounding_box() const { return bounding_box; }
};

} //namespace godot

#endif
