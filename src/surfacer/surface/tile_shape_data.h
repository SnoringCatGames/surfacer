#ifndef TILE_SHAPE_DATA_H
#define TILE_SHAPE_DATA_H

#include <godot_cpp/variant/packed_vector2_array.hpp>

namespace godot {

// This is only used internally by SurfaceParser while parsing surfaces.
struct TileShapeData {
	int tileset_index = 0;

	PackedVector2Array top_vertices;
	PackedVector2Array right_vertices;
	PackedVector2Array bottom_vertices;
	PackedVector2Array left_vertices;

	bool is_top_axially_aligned = false;
	bool is_right_axially_aligned = false;
	bool is_bottom_axially_aligned = false;
	bool is_left_axially_aligned = false;

	bool is_top_along_cell_boundary = false;
	bool is_right_along_cell_boundary = false;
	bool is_bottom_along_cell_boundary = false;
	bool is_left_along_cell_boundary = false;
};

} // namespace godot

#endif
