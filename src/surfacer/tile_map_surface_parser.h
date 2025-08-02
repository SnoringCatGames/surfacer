#ifndef TILE_MAP_SURFACE_PARSER_H
#define TILE_MAP_SURFACE_PARSER_H

#include "snore_core/snore_core_submodule.h"
#include "surfacer/surfacer_module.h"

namespace godot {

class TileMapSurfaceParser : public SnoreCoreSubmodule {
	GDCLASS(TileMapSurfaceParser, SnoreCoreSubmodule)
	SC_SUBMODULE_CLASS(TileMapSurfaceParser, Surfacer)

public:
	TileMapSurfaceParser() = default;
	~TileMapSurfaceParser() = default;

protected:
	static void _bind_methods();

private:
};

} //namespace godot

#endif
