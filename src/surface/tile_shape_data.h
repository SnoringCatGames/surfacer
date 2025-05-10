#ifndef TILE_SHAPE_DATA_H
#define TILE_SHAPE_DATA_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class TileShapeData : public RefCounted {
	GDCLASS(TileShapeData, RefCounted)

public:
	TileShapeData() = default;
	~TileShapeData() = default;

	int get_tileset_index() const { return tileset_index; }
	void set_tileset_index(int p_value) { tileset_index = p_value; }

	PackedVector2Array get_top_vertices() const { return top_vertices; }
	void set_top_vertices(const PackedVector2Array &p_value) {
		top_vertices = p_value;
	}

	PackedVector2Array get_right_vertices() const { return right_vertices; }
	void set_right_vertices(const PackedVector2Array &p_value) {
		right_vertices = p_value;
	}

	PackedVector2Array get_bottom_vertices() const { return bottom_vertices; }
	void set_bottom_vertices(const PackedVector2Array &p_value) {
		bottom_vertices = p_value;
	}

	PackedVector2Array get_left_vertices() const { return left_vertices; }
	void set_left_vertices(const PackedVector2Array &p_value) {
		left_vertices = p_value;
	}

	bool get_is_top_axially_aligned() const { return is_top_axially_aligned; }
	void set_is_top_axially_aligned(bool p_value) {
		is_top_axially_aligned = p_value;
	}

	bool get_is_right_axially_aligned() const {
		return is_right_axially_aligned;
	}
	void set_is_right_axially_aligned(bool p_value) {
		is_right_axially_aligned = p_value;
	}

	bool get_is_bottom_axially_aligned() const {
		return is_bottom_axially_aligned;
	}
	void set_is_bottom_axially_aligned(bool p_value) {
		is_bottom_axially_aligned = p_value;
	}

	bool get_is_left_axially_aligned() const { return is_left_axially_aligned; }
	void set_is_left_axially_aligned(bool p_value) {
		is_left_axially_aligned = p_value;
	}

	bool get_is_top_along_cell_boundary() const {
		return is_top_along_cell_boundary;
	}
	void set_is_top_along_cell_boundary(bool p_value) {
		is_top_along_cell_boundary = p_value;
	}

	bool get_is_right_along_cell_boundary() const {
		return is_right_along_cell_boundary;
	}
	void set_is_right_along_cell_boundary(bool p_value) {
		is_right_along_cell_boundary = p_value;
	}

	bool get_is_bottom_along_cell_boundary() const {
		return is_bottom_along_cell_boundary;
	}
	void set_is_bottom_along_cell_boundary(bool p_value) {
		is_bottom_along_cell_boundary = p_value;
	}

	bool get_is_left_along_cell_boundary() const {
		return is_left_along_cell_boundary;
	}
	void set_is_left_along_cell_boundary(bool p_value) {
		is_left_along_cell_boundary = p_value;
	}

protected:
	static void _bind_methods();

private:
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
