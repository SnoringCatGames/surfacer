#ifndef DRAW_UTILS_H
#define DRAW_UTILS_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class SurfaceStore;
class SurfaceMark;
class TileMap;

class DrawUtils : public RefCounted {
	GDCLASS(DrawUtils, RefCounted)

public:
	void parse(
			SurfaceStore *surface_store,
			const Array &tilemaps,
			const Array &surface_marks);

protected:
	static void _bind_methods();

private:
	static constexpr int surfaces_tile_maps_collision_layer = 1;
	static constexpr float corner_target_less_preferred_surface_side_offset =
			0.02f;
	static constexpr float corner_target_more_preferred_surface_side_offset =
			0.01f;
	static constexpr float collision_between_cells_distance_threshold = 0.5f;
	static constexpr float equal_point_epsilon = 0.1f;

	DrawUtils() = default;
	~DrawUtils() = default;

	void _validate_tilemap_collection(const Array &tilemaps);
	void _calculate_max_tilemap_cell_size(
			SurfaceStore *surface_store,
			const Array &tilemaps);
	void _calculate_combined_tilemap_rect(
			SurfaceStore *surface_store,
			const Array &tilemaps);
	void _parse_tilemap(SurfaceStore *surface_store, TileMap *tile_map);
	void _populate_derivative_collections(
			SurfaceStore *surface_store,
			const Array &tilemaps);
	void _parse_surface_mark(
			SurfaceStore *surface_store,
			SurfaceMark *mark,
			TileMap *tile_map);
};

} //namespace godot

#endif
