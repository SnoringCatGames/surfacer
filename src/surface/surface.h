#ifndef SURFACE_H
#define SURFACE_H

#include "internal_utils.h"

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/tile_map.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class SurfaceChunk;

class Surface : public RefCounted {
	GDCLASS(Surface, RefCounted)

public:
	enum Side
	{
		UNKNOWN_SIDE,
		FLOOR,
		CEILING,
		LEFT_WALL,
		RIGHT_WALL,
		_Side_COUNT,
	};
private:
	static constexpr char* _side_strings[Side::_Side_COUNT] = {
		"UNKNOWN",
		"FLOOR",
		"CEILING",
		"LEFT_WALL",
		"RIGHT_WALL",
	};
public:
	static String side_to_string(Side p_side)
	{
		return _side_strings[p_side];
	}

public:
	enum NeighborCurvature
	{
		UNKNOWN_CURVATURE,
		COLLINEAR,
		CONVEX,
		CONCAVE,
		_NeighborCurvature_COUNT,
	};
private:
	static constexpr char* _neighbor_curvature_strings[NeighborCurvature::_NeighborCurvature_COUNT] = {
		"UNKNOWN",
		"COLLINEAR",
		"CONVEX",
		"CONCAVE",
	};
public:
	static String neighbor_curvature_to_string(NeighborCurvature p_side)
	{
		return _neighbor_curvature_strings[p_side];
	}

private:
	Side side = Side::UNKNOWN_SIDE;
	
	PackedVector2Array vertices;
	Rect2 bounding_box;

	Ref<SurfaceChunk> chunk;
	
	TileMap* tile_map;
	PackedInt32Array tile_map_indices;

	NeighborCurvature clockwise_neighbor_curvature = NeighborCurvature::UNKNOWN_CURVATURE;
	Ref<Surface> clockwise_neighbor;
	
	NeighborCurvature counter_clockwise_neighbor_curvature = NeighborCurvature::UNKNOWN_CURVATURE;
	Ref<Surface> counter_clockwise_neighbor;

protected:
	static void _bind_methods();

public:
	static Vector2 get_normal_from_side(Side p_side);

	Surface();
	~Surface();

	void set_side(Side p_side) { side = p_side; }
	Side get_side() const { return side; }

	void set_vertices(PackedVector2Array p_vertices) { vertices = p_vertices; }
	PackedVector2Array get_vertices() const { return vertices; }

	void set_bounding_box(Rect2 p_bounding_box) { bounding_box = p_bounding_box; }
	Rect2 get_bounding_box() const { return bounding_box; }

	void set_chunk(Ref<SurfaceChunk> p_chunk);
	Ref<SurfaceChunk> get_chunk() const;

	void set_tile_map(TileMap* p_tile_map) { tile_map = p_tile_map; }
	TileMap* get_tile_map() const { return tile_map; }

	void set_tile_map_indices(PackedInt32Array p_tile_map_indices) { tile_map_indices = p_tile_map_indices; }
	PackedInt32Array get_tile_map_indices() const { return tile_map_indices; }

	void set_clockwise_neighbor_curvature(NeighborCurvature p_clockwise_neighbor_curvature) { clockwise_neighbor_curvature = p_clockwise_neighbor_curvature; }
	NeighborCurvature get_clockwise_neighbor_curvature() const { return clockwise_neighbor_curvature; }

	void set_clockwise_neighbor(Ref<Surface> p_clockwise_neighbor) { clockwise_neighbor = p_clockwise_neighbor; }
	Ref<Surface> get_clockwise_neighbor() const { return clockwise_neighbor; }

	void set_counter_clockwise_neighbor_curvature(NeighborCurvature p_counter_clockwise_neighbor_curvature) { counter_clockwise_neighbor_curvature = p_counter_clockwise_neighbor_curvature; }
	NeighborCurvature get_counter_clockwise_neighbor_curvature() const { return counter_clockwise_neighbor_curvature; }

	void set_counter_clockwise_neighbor(Ref<Surface> p_counter_clockwise_neighbor) { counter_clockwise_neighbor = p_counter_clockwise_neighbor; }
	Ref<Surface> get_counter_clockwise_neighbor() const { return counter_clockwise_neighbor; }

	Vector2 get_normal() const
	{
		return get_normal_from_side(side);
	}

	Ref<Surface> get_clockwise_convex_neighbor() const
	{
		return clockwise_neighbor_curvature == NeighborCurvature::CONVEX ? clockwise_neighbor : nullptr;
	}
	Ref<Surface> get_clockwise_concave_neighbor() const
	{
		return clockwise_neighbor_curvature == NeighborCurvature::CONCAVE ? clockwise_neighbor : nullptr;
	}
	Ref<Surface> get_clockwise_collinear_neighbor() const
	{
		return clockwise_neighbor_curvature == NeighborCurvature::COLLINEAR ? clockwise_neighbor : nullptr;
	}

	Ref<Surface> get_counter_clockwise_convex_neighbor() const
	{
		return counter_clockwise_neighbor_curvature == NeighborCurvature::CONVEX ? counter_clockwise_neighbor : nullptr;
	}
	Ref<Surface> get_counter_clockwise_concave_neighbor() const
	{
		return counter_clockwise_neighbor_curvature == NeighborCurvature::CONCAVE ? counter_clockwise_neighbor : nullptr;
	}
	Ref<Surface> get_counter_clockwise_collinear_neighbor() const
	{
		return counter_clockwise_neighbor_curvature == NeighborCurvature::COLLINEAR ? counter_clockwise_neighbor : nullptr;
	}
};

}

VARIANT_ENUM_CAST(Surface::Side);
VARIANT_ENUM_CAST(Surface::NeighborCurvature);

#endif
