#ifndef SURFACE_FINDER_H
#define SURFACE_FINDER_H

#include "surface/collision_surface_result.h"
#include "surface/surface_store.h"

#include <godot_cpp/classes/physics_direct_space_state2d.hpp>
#include <godot_cpp/classes/physics_server2d.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/godot.hpp> // For infinity if not in cmath
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

enum class SurfaceReachability { // Example definition
	ANY,
	REACHABLE,
	REVERSIBLY_REACHABLE
};

class SurfaceFinder : public RefCounted {
	GDCLASS(SurfaceFinder, RefCounted);

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

public:
	SurfaceFinder();
	~SurfaceFinder();

	static Ref<Surface> find_closest_surface_in_direction(
			SurfaceStore *p_surface_store,
			RID p_world_rid, // RID of the physics space
			const Vector2 &p_target,
			const Vector2 &p_direction,
			Ref<CollisionSurfaceResult> p_collision_surface_result = nullptr,
			double p_max_distance = 10000.0);

	static Ref<PositionAlongSurface> find_closest_position_on_a_surface(
			const Vector2 &p_target,
			Character *p_character, // Assuming Character is a defined C++ class
			SurfaceReachability p_surface_reachability,
			double p_max_distance_squared_threshold = infinity,
			const Vector2 &p_max_distance_basis_point =
					Vector2(infinity, infinity));

	static Array find_closest_positions_on_surfaces(
			const Vector2 &p_target,
			Character *p_character,
			int p_position_count,
			double p_max_distance_squared_threshold = infinity,
			const Vector2 &p_max_distance_basis_point =
					Vector2(infinity, infinity),
			const Variant &p_surfaces = Array()); // Can be Array or Dictionary

	static Array get_closest_surfaces(
			const Vector2 &p_target,
			const Variant &p_surfaces, // Can be Array or Dictionary
			int p_surface_count,
			double p_max_distance_squared_threshold = infinity,
			const Vector2 &p_max_distance_basis_point =
					Vector2(infinity, infinity));

	static bool maybe_add_surface_to_closest_n_collection(
			Array &p_collection, // Array of [Surface, distance_squared]
			const Array &p_surface_and_distance,
			int p_n);

	// Comparator for sorting [Surface, distance_squared] arrays
	static bool _surface_and_distance_sort_ascending_comparator(
			const Variant &p_a,
			const Variant &p_b);

	static void calculate_collision_surface(
			Ref<CollisionSurfaceResult> p_result,
			SurfaceStore *p_surface_store,
			const Vector2 &p_collision_position,
			const Variant
					&p_collision_normal_or_side, // Can be Vector2 (normal) or
												 // int (SurfaceSide)
			TileMap *p_tile_map,
			bool p_tries_adjusted_collision_normal,
			bool p_allows_errors,
			bool p_is_nested_call = false);

protected:
	static void _bind_methods();
};

} // namespace godot

#endif // SURFACE_FINDER_H
