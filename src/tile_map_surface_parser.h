#ifndef TILE_MAP_SURFACE_PARSER_H
#define TILE_MAP_SURFACE_PARSER_H

#include <godot_cpp/classes/ref_counted.hpp>

namespace godot {

class TileMapSurfaceParser : public RefCounted {
	GDCLASS(TileMapSurfaceParser, RefCounted)

private:
protected:
	static void _bind_methods();

public:
	TileMapSurfaceParser();
	~TileMapSurfaceParser();
};

} //namespace godot

#endif
