#include "surfacer/surface/surface_store.h"

#include "snore_core/internal/debug_utils.h"
#include "surfacer/movement_profile.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void SurfaceStore::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD(
					"get_surface_for_tile", "p_tile_map", "p_tilemap_index",
					"p_side"),
			&SurfaceStore::get_surface_for_tile);
	ClassDB::bind_method(
			D_METHOD("get_surface_set", "p_movement_profile"),
			&SurfaceStore::get_surface_set);

	ClassDB::bind_method(D_METHOD("get_floors"), &SurfaceStore::get_floors);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "floors"), "", "get_floors");
	ClassDB::bind_method(D_METHOD("get_ceilings"), &SurfaceStore::get_ceilings);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "ceilings"), "", "get_ceilings");
	ClassDB::bind_method(
			D_METHOD("get_left_walls"), &SurfaceStore::get_left_walls);
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "left_walls"), "", "get_left_walls");
	ClassDB::bind_method(
			D_METHOD("get_right_walls"), &SurfaceStore::get_right_walls);
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "right_walls"), "", "get_right_walls");

	ClassDB::bind_method(
			D_METHOD("get_max_tilemap_cell_size"),
			&SurfaceStore::get_max_tile_map_cell_size);
	ADD_PROPERTY(
			PropertyInfo(Variant::VECTOR2, "max_tilemap_cell_size"), "",
			"get_max_tilemap_cell_size");
	ClassDB::bind_method(
			D_METHOD("get_combined_tilemap_rect"),
			&SurfaceStore::get_combined_tile_map_rect);
	ADD_PROPERTY(
			PropertyInfo(Variant::RECT2, "combined_tilemap_rect"), "",
			"get_combined_tilemap_rect");
}

Ref<Surface> SurfaceStore::get_surface_for_tile(
		TileMapLayer *p_tile_map,
		int p_tile_map_index,
		Surface::Side p_side) const {
	if (!ENSURE_SIMPLE(p_side != Surface::Side::UNKNOWN_SIDE)) {
		return nullptr;
	}

	const uint64_t map_key = p_tile_map->get_instance_id();

	if (tile_map_to_side_to_index_to_surface.count(map_key) == 0) {
		return nullptr;
	}

	const std::unordered_map<int, Ref<Surface>> &index_to_surface =
			tile_map_to_side_to_index_to_surface.at(map_key).at(p_side - 1);

	if (index_to_surface.count(p_tile_map_index) == 0) {
		return nullptr;
	}

	return index_to_surface.at(p_tile_map_index);
}

Dictionary SurfaceStore::get_surface_set(
		const MovementProfile *p_profile) const {
	// TODO: Port this

	Dictionary set;

	// 	if (!p_movement_params)
	// 		return set; // Guard against null p_movement_params

	// 	Array surface_collections;
	// 	// Assuming MovementParameters has public bool members or getters like
	// 	// can_grab_floors()
	// 	if (p_movement_params->can_grab_floors) {
	// 		surface_collections.push_back(floors);
	// 	}
	// 	if (p_movement_params->can_grab_walls) {
	// 		surface_collections.push_back(all_walls);
	// 	}
	// 	if (p_movement_params->can_grab_ceilings) {
	// 		surface_collections.push_back(ceilings);
	// 	}

	// 	for (int i = 0; i < surface_collections.size(); ++i) {
	// 		Array surface_collection = surface_collections[i];
	// 		for (int j = 0; j < surface_collection.size(); ++j) {
	// 			Ref<Surface> surface = surface_collection[j];
	// 			// Assuming Surface has a method like 'can_be_grabbed()' or
	// similar
	// 			// For 'surface.properties.can_grab', this implies Surface has a
	// way
	// 			// to get this boolean. Example: if (surface.is_valid() &&
	// 			// surface->get_properties_config()->can_grab) For simplicity,
	// let's
	// 			// assume a method: surface->allows_grabbing()
	// 			if (surface.is_valid() &&
	// 				surface->allows_grabbing_via_properties()) {
	// 				set[surface] = true;
	// 			}
	// 		}
	// 	}

	// 	for (int i = 0; i < marks.size(); ++i) {
	// 		Ref<SurfaceMark> mark = marks[i];
	// 		if (!mark.is_valid())
	// 			continue;

	// 		SurfaceEnablement *enablement_mark =
	// 				Object::cast_to<SurfaceEnablement>(mark.ptr());
	// 		if (!enablement_mark) {
	// 			continue;
	// 		}

	// 		bool does_mark_match_character = false;
	// 		// Assuming SurfaceMark has get_character_category_names() -> Array
	// 		// Assuming MovementParameters has character_category_name (String
	// or
	// 		// StringName)
	// 		Array category_names = mark->get_character_category_names();
	// 		StringName char_category_name =
	// 				p_movement_params->character_category_name;

	// 		if (category_names.has(char_category_name)) {
	// 			does_mark_match_character = true;
	// 		}

	// 		if (does_mark_match_character) {
	// 			// Assuming SurfaceEnablement has these getters
	// 			bool include_exclusively =
	// 					enablement_mark->is_include_exclusively();
	// 			bool exclude = enablement_mark->is_exclude();

	// 			if (include_exclusively) {
	// 				Array current_surfaces_in_set = set.keys();
	// 				for (int k = 0; k < current_surfaces_in_set.size(); ++k) {
	// 					Ref<Surface> surface_in_set =
	// current_surfaces_in_set[k];
	// 					// Assuming SurfaceMark has
	// 					// get_is_surface_marked(Ref<Surface>) -> bool
	// 					if (surface_in_set.is_valid() &&
	// 						!mark->is_surface_marked(surface_in_set)) {
	// 						set.erase(surface_in_set);
	// 					}
	// 				}
	// 			} else if (exclude) {
	// 				// Assuming SurfaceEnablement has get_marked_surfaces() ->
	// Array
	// 				// of Ref<Surface>
	// 				Array marked_surfaces_by_this_mark =
	// 						enablement_mark->get_explicitly_marked_surfaces();
	// 				for (int k = 0; k < marked_surfaces_by_this_mark.size();
	// ++k) { 					Ref<Surface> marked_surface =
	// marked_surfaces_by_this_mark[k];
	// 					// Assuming Surface has get_first_point() -> Vector2
	// 					if (marked_surface.is_valid() &&
	// 						marked_surface->get_first_point() ==
	// 								Vector2(-352, 256)) {
	// 						UtilityFunctions::print(
	// 								"C++ port: break condition met for surface "
	// 								"exclusion");
	// 					}
	// 					set.erase(marked_surface); // Erasing by Ref<Surface>
	// key
	// 				}
	// 			}
	// 		}
	// 	}

	return set;
}
