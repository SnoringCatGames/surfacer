#ifndef SURFACE_STORE_H
#define SURFACE_STORE_H

#include <godot_cpp/classes/reference.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/vector2.hpp>

// Forward declarations for types used.
// Ensure these C++ classes are defined in your project.
namespace godot {
class Surface;
class SurfaceMark;
class SurfaceEnablement; // Should inherit from SurfaceMark
class CollisionSurfaceResult;
class MovementParameters; // Define this class/struct as needed
// If SurfaceProperties is a class/struct used by Surface:
// class SurfaceProperties;
} //namespace godot

class SurfaceStore : public godot::Reference {
	GDCLASS(SurfaceStore, godot::Reference);

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

	// Collections of surfaces.
	// Array<Ref<Surface>>
	godot::Array floors;
	godot::Array ceilings;
	godot::Array left_walls;
	godot::Array right_walls;

	godot::Array all_surfaces;
	godot::Array non_ceiling_surfaces;
	godot::Array non_floor_surfaces;
	godot::Array non_wall_surfaces;
	godot::Array all_walls;

	// Array<Ref<SurfaceMark>>
	godot::Array marks;

	godot::Vector2 max_tilemap_cell_size;
	godot::Rect2 combined_tilemap_rect;

	// This supports mapping a cell in a TileMap to its corresponding surface.
	// Dictionary<TileMap*, Dictionary<int, Dictionary<int, Ref<Surface>>>>
	// Using Variant for TileMap* as key, as Dictionary keys are Variants.
	// TileMap* itself might not be a good key if its address changes; consider
	// using TileMap's ObjectID.
	godot::Dictionary _tilemap_index_to_surface_maps;

	godot::Ref<godot::CollisionSurfaceResult> _collision_surface_result;

protected:
	static void _bind_methods();

public:
	SurfaceStore();
	~SurfaceStore();

	godot::Ref<godot::Surface> get_surface_for_tile(
			godot::TileMap *p_tile_map,
			int p_tilemap_index,
			int p_side);

	// Assuming MovementParameters is a C++ class/struct.
	// If it's a Godot Object, pass Ref<MovementParameters> or
	// MovementParameters*.
	godot::Dictionary get_surface_set(
			const godot::MovementParameters *p_movement_params);

	// Assuming surface_parser is an Object pointer that has the required
	// methods.
	void load_from_json_object(
			const godot::Dictionary &p_json_object,
			const godot::Dictionary &p_context,
			godot::Object *p_surface_parser);

	godot::Dictionary to_json_object();

private:
	godot::Array _json_object_to_surface_array(
			const godot::Array &p_json_object,
			const godot::Dictionary &p_context);

	godot::Array _surface_array_to_json_object(const godot::Array &p_surfaces);
};

#endif // SURFACE_STORE_H