#ifndef TILE_MAP_SURFACE_PARSER_H
#define TILE_MAP_SURFACE_PARSER_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class GDE_EXPORT TileMapSurfaceParser : public RefCounted {
	GDCLASS(TileMapSurfaceParser, RefCounted)

public:
	TileMapSurfaceParser() = default;
	~TileMapSurfaceParser() = default;

protected:
	static void _bind_methods();

private:
};

} //namespace godot

#endif
