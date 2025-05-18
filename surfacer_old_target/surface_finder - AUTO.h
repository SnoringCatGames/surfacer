#ifndef SURFACE_FINDER_H
#define SURFACE_FINDER_H

#include <godot_cpp/classes/physics_direct_space_state2d.hpp>
#include <godot_cpp/classes/physics_server2d.hpp>
#include <godot_cpp/classes/reference.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/godot.hpp> // For INFINITY if not in cmath
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector2.hpp>

// Forward declarations
namespace godot {
class SurfaceStore;
class CollisionSurfaceResult;
class Surface;
class PositionAlongSurface;
// Assuming Character is a custom class, likely deriving from Object or Node
class Character;
class World2D;
} //namespace godot

// Assuming these enums are defined elsewhere, e.g., in a common header or
// surface.h
enum class SurfaceSide { // Example definition
	NONE = -1,
	FLOOR = 0,
	LEFT_WALL = 1,
	RIGHT_WALL = 2,
	CEILING = 3
	// Add other values as needed
};

enum class SurfaceReachability { // Example definition
	ANY,
	REACHABLE,
	REVERSIBLY_REACHABLE
};

// Placeholder for Sc.geometry and Sc.utils, you'll need to implement these
struct GeometryUtils {
	static godot::Vector2 world_to_tilemap(
			const godot::Vector2 &p_world_pos,
			godot::TileMap *p_tile_map);
	static int get_tilemap_index_from_grid_coord(
			const godot::Vector2 &p_grid_coord,
			godot::TileMap *p_tile_map);
	static SurfaceSide get_surface_side_for_normal(
			const godot::Vector2 &p_normal);
	static double distance_squared_from_point_to_rect(
			const godot::Vector2 &p_point,
			const godot::Rect2 &p_rect);
	static godot::Vector2 get_closest_point_on_polyline_to_point(
			const godot::Vector2 &p_point,
			const godot::Array &p_polyline_vertices); // Assuming vertices is
													  // Array of Vector2
	static bool are_points_equal_with_epsilon(
			const godot::Vector2 &p_p1,
			const godot::Vector2 &p_p2,
			double p_epsilon);
	// Add other geometry functions used by Sc.geometry
};

struct StringUtils {
	static godot::String get_vector_string(
			const godot::Vector2 &p_vector,
			int p_precision);
	// Add other string utils used by Sc.utils
};

struct GlobalAccessors { // Placeholder for Su.
	static godot::PhysicsDirectSpaceState2D *get_physics_space_state(
			godot::RID p_world_rid); // Example
	static bool are_reachable_surfaces_per_player_tracked(); // Example
};

class SurfaceFinder : public godot::Reference {
	GDCLASS(SurfaceFinder, godot::Reference);

public:
	// TODO: Map the TileMap into an RTree or BVH.

	static constexpr int SURFACES_TILE_MAPS_COLLISION_LAYER = 1;

	static constexpr double _CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET =
			0.02;
	static constexpr double _CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET =
			0.01;

	// TODO: We might want to instead replace this with a ratio (like 1.1) of
	// the
	//       KinematicBody2D.get_safe_margin value (defaults to 0.08, but we set
	//       it higher during graph calculations).
	static constexpr double _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD = 0.5;

protected:
	static void _bind_methods(); // If you need to expose static methods to
								 // GDScript

public:
	SurfaceFinder();
	~SurfaceFinder();

	static godot::Ref<godot::Surface> find_closest_surface_in_direction(
			godot::SurfaceStore *p_surface_store,
			godot::RID p_world_rid, // RID of the physics space
			const godot::Vector2 &p_target,
			const godot::Vector2 &p_direction,
			godot::Ref<godot::CollisionSurfaceResult>
					p_collision_surface_result = nullptr,
			double p_max_distance = 10000.0);

	static godot::Ref<godot::PositionAlongSurface>
	find_closest_position_on_a_surface(
			const godot::Vector2 &p_target,
			godot::Character
					*p_character, // Assuming Character is a defined C++ class
			SurfaceReachability p_surface_reachability,
			double p_max_distance_squared_threshold = INFINITY,
			const godot::Vector2 &p_max_distance_basis_point =
					godot::Vector2(INFINITY, INFINITY));

	static godot::Array find_closest_positions_on_surfaces(
			const godot::Vector2 &p_target,
			godot::Character *p_character,
			int p_position_count,
			double p_max_distance_squared_threshold = INFINITY,
			const godot::Vector2 &p_max_distance_basis_point =
					godot::Vector2(INFINITY, INFINITY),
			const godot::Variant &p_surfaces =
					godot::Array()); // Can be Array or Dictionary

	static godot::Array get_closest_surfaces(
			const godot::Vector2 &p_target,
			const godot::Variant &p_surfaces, // Can be Array or Dictionary
			int p_surface_count,
			double p_max_distance_squared_threshold = INFINITY,
			const godot::Vector2 &p_max_distance_basis_point =
					godot::Vector2(INFINITY, INFINITY));

	static bool maybe_add_surface_to_closest_n_collection(
			godot::Array &p_collection, // Array of [Surface, distance_squared]
			const godot::Array &p_surface_and_distance,
			int p_n);

	// Comparator for sorting [Surface, distance_squared] arrays
	static bool _surface_and_distance_sort_ascending_comparator(
			const godot::Variant &p_a,
			const godot::Variant &p_b);

	static void calculate_collision_surface(
			godot::Ref<godot::CollisionSurfaceResult> p_result,
			godot::SurfaceStore *p_surface_store,
			const godot::Vector2 &p_collision_position,
			const godot::Variant
					&p_collision_normal_or_side, // Can be Vector2 (normal) or
												 // int (SurfaceSide)
			godot::TileMap *p_tile_map,
			bool p_tries_adjusted_collision_normal,
			bool p_allows_errors,
			bool p_is_nested_call = false);
};

#endif // SURFACE_FINDER_H