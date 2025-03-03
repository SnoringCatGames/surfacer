#include "surface/surface.h"

#include "surface/surface_chunk.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Surface::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_side"), &Surface::get_side);
    ClassDB::bind_method(D_METHOD("set_side", "p_side"), &Surface::set_side);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "side"), "set_side", "get_side");
    
    ClassDB::bind_method(D_METHOD("get_vertices"), &Surface::get_vertices);
    ClassDB::bind_method(D_METHOD("set_vertices", "p_vertices"), &Surface::set_vertices);
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_VECTOR2_ARRAY, "vertices"), "set_vertices", "get_vertices");
    
    ClassDB::bind_method(D_METHOD("get_bounding_box"), &Surface::get_bounding_box);
    ClassDB::bind_method(D_METHOD("set_bounding_box", "p_bounding_box"), &Surface::set_bounding_box);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2, "bounding_box"), "set_bounding_box", "get_bounding_box");
    
    ClassDB::bind_method(D_METHOD("get_chunk"), &Surface::get_chunk);
    ClassDB::bind_method(D_METHOD("set_chunk", "p_chunk"), &Surface::set_chunk);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "chunk"), "set_chunk", "get_chunk");
    
    ClassDB::bind_method(D_METHOD("get_tile_map"), &Surface::get_tile_map);
    ClassDB::bind_method(D_METHOD("set_tile_map", "p_tile_map"), &Surface::set_tile_map);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "tile_map"), "set_tile_map", "get_tile_map");
    
    ClassDB::bind_method(D_METHOD("get_tile_map_indices"), &Surface::get_tile_map_indices);
    ClassDB::bind_method(D_METHOD("set_tile_map_indices", "p_tile_map_indices"), &Surface::set_tile_map_indices);
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_INT32_ARRAY, "tile_map_indices"), "set_tile_map_indices", "get_tile_map_indices");
    
    ClassDB::bind_method(D_METHOD("get_clockwise_neighbor_curvature"), &Surface::get_clockwise_neighbor_curvature);
    ClassDB::bind_method(D_METHOD("set_clockwise_neighbor_curvature", "p_clockwise_neighbor_curvature"), &Surface::set_clockwise_neighbor_curvature);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "clockwise_neighbor_curvature"), "set_clockwise_neighbor_curvature", "get_clockwise_neighbor_curvature");
    
    ClassDB::bind_method(D_METHOD("get_clockwise_neighbor"), &Surface::get_clockwise_neighbor);
    ClassDB::bind_method(D_METHOD("set_clockwise_neighbor", "p_clockwise_neighbor"), &Surface::set_clockwise_neighbor);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "clockwise_neighbor"), "set_clockwise_neighbor", "get_clockwise_neighbor");
    
    ClassDB::bind_method(D_METHOD("get_counter_clockwise_neighbor_curvature"), &Surface::get_counter_clockwise_neighbor_curvature);
    ClassDB::bind_method(D_METHOD("set_counter_clockwise_neighbor_curvature", "p_counter_clockwise_neighbor_curvature"), &Surface::set_counter_clockwise_neighbor_curvature);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "counter_clockwise_neighbor_curvature"), "set_counter_clockwise_neighbor_curvature", "get_counter_clockwise_neighbor_curvature");
    
    ClassDB::bind_method(D_METHOD("get_counter_clockwise_neighbor"), &Surface::get_counter_clockwise_neighbor);
    ClassDB::bind_method(D_METHOD("set_counter_clockwise_neighbor", "p_counter_clockwise_neighbor"), &Surface::set_counter_clockwise_neighbor);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "counter_clockwise_neighbor"), "set_counter_clockwise_neighbor", "get_counter_clockwise_neighbor");
    
    ClassDB::bind_method(D_METHOD("get_normal"), &Surface::get_normal);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "normal"), "", "get_normal");

    ClassDB::bind_method(D_METHOD("get_clockwise_convex_neighbor"), &Surface::get_clockwise_convex_neighbor);
    ClassDB::bind_method(D_METHOD("get_clockwise_concave_neighbor"), &Surface::get_clockwise_concave_neighbor);
    ClassDB::bind_method(D_METHOD("get_clockwise_collinear_neighbor"), &Surface::get_clockwise_collinear_neighbor);

    ClassDB::bind_method(D_METHOD("get_counter_clockwise_convex_neighbor"), &Surface::get_counter_clockwise_convex_neighbor);
    ClassDB::bind_method(D_METHOD("get_counter_clockwise_concave_neighbor"), &Surface::get_counter_clockwise_concave_neighbor);
    ClassDB::bind_method(D_METHOD("get_counter_clockwise_collinear_neighbor"), &Surface::get_counter_clockwise_collinear_neighbor);
}

Surface::Surface() {
}

Surface::~Surface() {
}

void Surface::set_chunk(Ref<SurfaceChunk> p_chunk) { chunk = p_chunk; }
Ref<SurfaceChunk> Surface::get_chunk() const { return chunk; }
