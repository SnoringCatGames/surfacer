#ifndef SURFACE_PARSER_H
#define SURFACE_PARSER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class SurfaceParser;

class GDE_EXPORT SurfaceParser : public RefCounted {
	GDCLASS(SurfaceParser, RefCounted);

public:
	SurfaceParser() = default;
	~SurfaceParser() = default;

	// FIXME: Port.

protected:
	static void _bind_methods();

private:
};

} // namespace godot

#endif // SURFACE_PARSER_H
