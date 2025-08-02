#include "surfacer/surface/surface_chunk.h"

#include "surfacer/surface/surface.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SurfaceChunk::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_surfaces"), &SurfaceChunk::get_surfaces);
	ClassDB::bind_method(
			D_METHOD("set_surfaces", "p_surfaces"),
			&SurfaceChunk::set_surfaces);

	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "surfaces"), "set_surfaces",
			"get_surfaces");

	ClassDB::bind_method(
			D_METHOD("get_bounding_box"), &SurfaceChunk::get_bounding_box);
	ClassDB::bind_method(
			D_METHOD("set_bounding_box", "p_bounding_box"),
			&SurfaceChunk::set_bounding_box);

	ADD_PROPERTY(
			PropertyInfo(Variant::RECT2, "bounding_box"), "set_bounding_box",
			"get_bounding_box");
}
