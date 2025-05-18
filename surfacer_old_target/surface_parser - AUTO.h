#ifndef SURFACE_PARSER_H
#define SURFACE_PARSER_H

#include <godot_cpp/classes/convex_polygon_shape2d.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/classes/tile_set.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/transform2d.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>

// Forward declarations for assumed helper classes and custom types
namespace godot {

class SurfaceStore; // Assumed to be a custom class/struct
class SurfaceMark; // Assumed to be a custom RefCounted class, likely extending
				   // Node or TileMap
class SurfacesTilemap; // Assumed to be a custom class extending TileMap
class CornerMatchInnerTilemap; // Assumed to be a custom class extending TileMap
class SurfacesTileset; // Assumed to be a custom class extending TileSet
class TileShapeData; // Assumed to be a custom RefCounted class
class SurfaceProperties; // Assumed to be a custom RefCounted class
class Surface; // Assumed to be a custom RefCounted class

// Enum for SurfaceSide
enum SurfaceSide {
	SURFACE_SIDE_FLOOR = 0,
	SURFACE_SIDE_CEILING,
	SURFACE_SIDE_LEFT_WALL,
	SURFACE_SIDE_RIGHT_WALL,
	// Add other sides if they exist in the original SurfaceSide enum
};

// Placeholder for Sc singleton/namespace access
// This needs to be adapted to the actual project structure.
// For brevity, only a few example functions are sketched here.
// A full implementation of these utilities is required.
struct Sc {
	struct Geometry {
		static bool are_points_collinear(
				Vector2 p_p1,
				Vector2 p_p2,
				Vector2 p_p3,
				double p_epsilon = 0.001);
		static bool are_points_equal_with_epsilon(
				Vector2 p_p1,
				Vector2 p_p2,
				double p_epsilon = 0.1);
		static bool are_floats_equal_with_epsilon(
				double p_f1,
				double p_f2,
				double p_epsilon = CMP_EPSILON);
		static bool is_polygon_clockwise(const Array &p_vertices);
		static Rect2 get_tilemap_bounds_in_world_coordinates(
				const TileMap *p_tile_map);
		static int get_tilemap_index_from_grid_coord(
				Vector2i p_grid_coord,
				const TileMap *p_tile_map);
		static bool do_point_and_segment_intersect(
				Vector2 p_point,
				Vector2 p_seg_start,
				Vector2 p_seg_end,
				double p_epsilon);
		static bool is_polygon_convex(
				const PackedVector2Array &p_points,
				double p_epsilon = 0.01);
		static bool do_surface_and_rectangle_intersect(
				const Ref<Surface> &p_surface,
				Vector2 p_rect_min,
				Vector2 p_rect_max);
		static Vector2i snap_vector2_to_integers(Vector2 p_vec);
		// Constants from GDScript (assuming they are part of Sc.geometry)
		static constexpr double FLOOR_MAX_ANGLE =
				Math_PI / 4.0; // Example value, replace with actual
		static constexpr double WALL_ANGLE_EPSILON = 0.01; // Example value
	};
	struct Utils {
		static void concat(Array &r_base_array, const Array &p_array_to_add);
	};
	struct Profiler {
		static void start(const StringName &p_name);
		static void stop(const StringName &p_name);
	};
	struct Levels { // Placeholder for Sc.levels.session.config.cell_size
		struct Session {
			struct Config {
				static Vector2 cell_size; // Needs to be initialized
			};
			Config config;
		};
		Session session;
		static Levels *get_singleton(); // Example singleton access
	};
};
// Placeholder for Su global access
struct Su {
	static bool are_oddly_shaped_surfaces_used;
};

// Temporary surface data structure, similar to _TmpSurface inner class
class _TmpSurface : public RefCounted {
	GDCLASS(_TmpSurface, RefCounted);

public:
	Array vertices_array; // Array of Vector2
	TileMap *tile_map = nullptr;
	Array tilemap_indices; // Array of int
	Ref<SurfaceProperties> properties;
	Ref<Surface> surface; // The final Surface object

	_TmpSurface() = default;

protected:
	static void _bind_methods() {}
};

class SurfaceParser : public RefCounted {
	GDCLASS(SurfaceParser, RefCounted);

public:
	// Constants
	static constexpr int SURFACES_TILE_MAPS_COLLISION_LAYER = 1;
	static constexpr double CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET =
			0.02;
	static constexpr double CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET =
			0.01;
	static constexpr double _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD = 0.5;
	static constexpr double _EQUAL_POINT_EPSILON = 0.1;

protected:
	static void _bind_methods();

public:
	SurfaceParser();
	~SurfaceParser();

	void parse(
			SurfaceStore *p_surface_store,
			const Array &p_tilemaps,
			const Array &p_surface_marks);

private:
	void _validate_tilemap_collection(const Array &p_tilemaps) const;
	void _calculate_max_tilemap_cell_size(
			SurfaceStore *p_surface_store,
			const Array &p_tilemaps) const;
	void _calculate_combined_tilemap_rect(
			SurfaceStore *p_surface_store,
			const Array &p_tilemaps) const;
	void _parse_tilemap(SurfaceStore *p_surface_store, TileMap *p_tile_map);
	void _store_surfaces(
			SurfaceStore *p_surface_store,
			TileMap *p_tile_map,
			const Array &p_floors,
			const Array &p_ceilings,
			const Array &p_left_walls,
			const Array &p_right_walls);
	void _populate_derivative_collections(
			SurfaceStore *p_surface_store,
			const Array &p_tilemaps);
	void _parse_surface_mark(
			SurfaceStore *p_surface_store,
			SurfaceMark *p_surface_mark,
			TileMap *p_tile_map);

	// Static helper methods (as in GDScript)
	static void _validate_tileset(TileMap *p_tile_map);
	static Dictionary _parse_tileset(TileMap *p_tile_map);
	static Dictionary _parse_tile(
			int p_tile_id,
			SurfacesTileset
					*p_tile_set, // Changed from TileSet to SurfacesTileset
			Vector2 p_cell_size);
	static Ref<TileShapeData> _parse_tile_shape(
			Shape2D *p_shape,
			Transform2D p_shape_transform,
			bool p_is_one_way,
			Vector2 p_cell_size);
	static bool _get_is_side_axially_aligned(
			const Array &p_vertices,
			bool p_is_horizontal);
	static bool _get_is_side_along_cell_boundary(
			const Array &p_vertices,
			bool p_is_horizontal,
			Vector2 p_cell_size);
	static void _parse_tilemap_cells_into_surfaces(
			Dictionary &r_tilemap_index_to_floor,
			Dictionary &r_tilemap_index_to_left_wall,
			Dictionary &r_tilemap_index_to_right_wall,
			Dictionary &r_tilemap_index_to_ceiling,
			const Dictionary &p_tile_id_to_coord_to_shape_data,
			TileMap *p_tile_map);
	static void _remove_internal_surfaces(
			Dictionary &r_tilemap_index_to_floor,
			Dictionary &r_tilemap_index_to_left_wall,
			Dictionary &r_tilemap_index_to_right_wall,
			Dictionary &r_tilemap_index_to_ceiling,
			const Dictionary
					&p_tile_id_to_coord_to_shape_data, // Added this parameter
													   // based on GDScript
			TileMap *p_tile_map);
	static void _remove_internal_single_vertex_surfaces(
			Dictionary &r_tilemap_index_to_floor,
			Dictionary &r_tilemap_index_to_left_wall,
			Dictionary &r_tilemap_index_to_right_wall,
			Dictionary &r_tilemap_index_to_ceiling,
			const Dictionary &p_tile_id_to_coord_to_shape_data, // Added
			TileMap *p_tile_map);
	static void _remove_internal_multi_vertex_surfaces(
			Dictionary &r_tilemap_index_to_floor,
			Dictionary &r_tilemap_index_to_left_wall,
			Dictionary &r_tilemap_index_to_right_wall,
			Dictionary &r_tilemap_index_to_ceiling,
			const Dictionary &p_tile_id_to_coord_to_shape_data, // Added
			TileMap *p_tile_map);
	static void _replace_surface(
			Ref<_TmpSurface> p_old_surface,
			Ref<_TmpSurface> p_new_surface,
			Dictionary &r_collection);
	static void _merge_continuous_surfaces(
			Dictionary &r_tilemap_index_to_floor,
			Dictionary &r_tilemap_index_to_left_wall,
			Dictionary &r_tilemap_index_to_right_wall,
			Dictionary &r_tilemap_index_to_ceiling,
			TileMap *p_tile_map);
	static Array _get_surface_list_from_map(
			const Dictionary &p_tilemap_index_to_surface);
	static void _remove_internal_collinear_vertices(const Array &p_surfaces);
	static void _assign_neighbor_surfaces(
			const Array &p_floors,
			const Array &p_ceilings,
			const Array &p_left_walls,
			const Array &p_right_walls);
	static void _calculate_shape_bounding_boxes_for_surfaces(
			const Array &p_surfaces);
	static void _assert_surfaces_have_neighbors(const Array &p_surfaces);
	static void _populate_surface_objects(
			const Array &p_tmp_surfaces,
			SurfaceSide p_side);
	static void _copy_surfaces_to_main_collection(
			const Array &p_tmp_surfaces,
			Array &r_main_collection);
	static Dictionary _create_tilemap_mapping_from_surfaces(
			const Array &p_surfaces,
			TileMap *p_tile_map);
	static void _free_objects(const Array &p_objects);
};

} // namespace godot

#endif // SURFACE_PARSER_H