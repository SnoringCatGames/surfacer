#ifndef SURFACE_STORE_H
#define SURFACE_STORE_H

#include "movement_profile.h"
#include "surface/surface.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/tile_map_layer.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class SurfaceParser;

class SurfaceStore : public RefCounted {
	GDCLASS(SurfaceStore, RefCounted);

private:
	// TODO: Map the TileMap into an RTree or BVH.

	static constexpr int SURFACES_TILE_MAPS_COLLISION_LAYER = 1;

	static constexpr double CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET =
			0.02;
	static constexpr double CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET =
			0.01;

	// TODO: We might want to instead replace this with a ratio (like 1.1) of
	//       the KinematicBody2D.get_safe_margin value (defaults to 0.08, but we
	//       set it higher during graph calculations).
	static constexpr double COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD = 0.5;

	// Collections of surfaces.
	// TypedArray<Surface><Ref<Surface>>
	TypedArray<Surface> floors;
	TypedArray<Surface> ceilings;
	TypedArray<Surface> left_walls;
	TypedArray<Surface> right_walls;

	TypedArray<Surface> all_surfaces;
	TypedArray<Surface> non_ceiling_surfaces;
	TypedArray<Surface> non_floor_surfaces;
	TypedArray<Surface> non_wall_surfaces;
	TypedArray<Surface> all_walls;

	// TypedArray<SurfaceMark> marks;

	Vector2 max_tile_map_cell_size;
	Rect2 combined_tile_map_rect;

	// This supports mapping a cell in a TileMap to its corresponding surface.
	// Dictionary<get_instance_id, Dictionary<int, Dictionary<int,
	// Ref<Surface>>>>
	Dictionary tilemap_index_to_surface_maps;

	void set_floors(TypedArray<Surface> p_floors) { floors = p_floors; }

	void set_ceilings(TypedArray<Surface> p_ceilings) { ceilings = p_ceilings; }

	void set_left_walls(TypedArray<Surface> p_left_walls) {
		left_walls = p_left_walls;
	}

	void set_right_walls(TypedArray<Surface> p_right_walls) {
		right_walls = p_right_walls;
	}

	void set_all_surfaces(TypedArray<Surface> p_all_surfaces) {
		all_surfaces = p_all_surfaces;
	}

	void set_non_ceiling_surfaces(TypedArray<Surface> p_non_ceiling_surfaces) {
		non_ceiling_surfaces = p_non_ceiling_surfaces;
	}

	void set_non_floor_surfaces(TypedArray<Surface> p_non_floor_surfaces) {
		non_floor_surfaces = p_non_floor_surfaces;
	}

	void set_non_wall_surfaces(TypedArray<Surface> p_non_wall_surfaces) {
		non_wall_surfaces = p_non_wall_surfaces;
	}

	void set_all_walls(TypedArray<Surface> p_all_walls) {
		all_walls = p_all_walls;
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

protected:
	static void _bind_methods();

public:
	SurfaceStore() {}
	~SurfaceStore() {}

	TypedArray<Surface> get_floors() const { return floors; }

	TypedArray<Surface> get_ceilings() const { return ceilings; }

	TypedArray<Surface> get_left_walls() const { return left_walls; }

	TypedArray<Surface> get_right_walls() const { return right_walls; }

	TypedArray<Surface> get_all_surfaces() const { return all_surfaces; }

	TypedArray<Surface> get_non_ceiling_surfaces() const {
		return non_ceiling_surfaces;
	}

	TypedArray<Surface> get_non_floor_surfaces() const {
		return non_floor_surfaces;
	}

	TypedArray<Surface> get_non_wall_surfaces() const {
		return non_wall_surfaces;
	}

	TypedArray<Surface> get_all_walls() const { return all_walls; }

	// TODO
	// TypedArray<SurfaceMark> get_marks() const { return marks; }

	Vector2 get_max_tile_map_cell_size() const {
		return max_tile_map_cell_size;
	}

	Rect2 get_combined_tile_map_rect() const { return combined_tile_map_rect; }

	Ref<Surface> get_surface_for_tile(
			TileMapLayer *p_tile_map,
			int p_tilemap_index,
			int p_side);

	Dictionary get_surface_set(const MovementProfile *p_profile);
};

} // namespace godot

#endif // SURFACE_STORE_H
