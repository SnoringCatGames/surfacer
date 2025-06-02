#ifndef SURFACE_STORE_H
#define SURFACE_STORE_H

#include "surfacer/movement_profile.h"
#include "surfacer/surface/surface.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/tile_map_layer.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <array>
#include <unordered_map>

namespace godot {

class SurfaceParser;

class SurfaceStore : public RefCounted {
	GDCLASS(SurfaceStore, RefCounted);

public:
	SurfaceStore() = default;
	~SurfaceStore() = default;

	TypedArray<const Surface> get_floors() const { return floors; }

	TypedArray<const Surface> get_ceilings() const { return ceilings; }

	TypedArray<const Surface> get_left_walls() const { return left_walls; }

	TypedArray<const Surface> get_right_walls() const { return right_walls; }

	// TODO
	// TypedArray<SurfaceMark> get_marks() const { return marks; }

	Vector2 get_max_tile_map_cell_size() const {
		return max_tile_map_cell_size;
	}

	Rect2 get_combined_tile_map_rect() const { return combined_tile_map_rect; }

	Ref<Surface> get_surface_for_tile(
			TileMapLayer *p_tile_map,
			int p_tilemap_index,
			Surface::Side p_side) const;

	Dictionary get_surface_set(const MovementProfile *p_profile) const;

protected:
	static void _bind_methods();

private:
	// TODO: Map the TileMap into an RTree or BVH.

	// Collections of surfaces.
	// TypedArray<Surface><Ref<Surface>>
	TypedArray<const Surface> floors;
	TypedArray<const Surface> ceilings;
	TypedArray<const Surface> left_walls;
	TypedArray<const Surface> right_walls;

	// TypedArray<SurfaceMark> marks;

	Vector2 max_tile_map_cell_size;
	Rect2 combined_tile_map_rect;

	// This supports mapping a cell in a TileMapLayer to its corresponding
	// surface.
	std::unordered_map<
			uint64_t,
			std::array<
					std::unordered_map<int, Ref<Surface>>,
					Surface::Side::_Side_COUNT - 1>>
			tile_map_to_side_to_index_to_surface;

	void set_floors(TypedArray<Surface> p_floors) { floors = p_floors; }

	void set_ceilings(TypedArray<Surface> p_ceilings) { ceilings = p_ceilings; }

	void set_left_walls(TypedArray<Surface> p_left_walls) {
		left_walls = p_left_walls;
	}

	void set_right_walls(TypedArray<Surface> p_right_walls) {
		right_walls = p_right_walls;
	}

	// TODO
	// void set_marks(TypedArray<SurfaceMark> p_marks) { marks = p_marks; }

	void set_max_tile_map_cell_size(Vector2 p_max_tile_map_cell_size) {
		max_tile_map_cell_size = p_max_tile_map_cell_size;
	}

	void set_combined_tile_map_rect(Rect2 p_combined_tile_map_rect) {
		combined_tile_map_rect = p_combined_tile_map_rect;
	}

	friend SurfaceParser;
};

} // namespace godot

#endif // SURFACE_STORE_H
