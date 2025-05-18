#include "surface_store.h"

// You'll need to create/include these headers for your custom classes
#include "collision_surface_result.h"
#include "movement_parameters.h"
#include "surface.h"
#include "surface_enablement.h"
#include "surface_mark.h"
// #include "surface_properties.h" // If Surface has a properties object

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SurfaceStore::_bind_methods() {
	// Method bindings
	ClassDB::bind_method(
			D_METHOD(
					"get_surface_for_tile", "p_tile_map", "p_tilemap_index",
					"p_side"),
			&SurfaceStore::get_surface_for_tile);
	// Assuming MovementParameters is a registered Object-derived type (e.g.,
	// RefCounted or Resource) If MovementParameters is a plain C++ struct, it
	// cannot be directly used as a parameter like this and would need to be
	// wrapped in a Variant or be a registered Godot type.
	ClassDB::bind_method(
			D_METHOD("get_surface_set", "p_movement_params"),
			&SurfaceStore::get_surface_set);
	ClassDB::bind_method(
			D_METHOD(
					"load_from_json_object", "p_json_object", "p_context",
					"p_surface_parser"),
			&SurfaceStore::load_from_json_object);
	ClassDB::bind_method(
			D_METHOD("to_json_object"), &SurfaceStore::to_json_object);

	// Property bindings
	// IMPORTANT: The following ADD_PROPERTY calls assume you will add
	// corresponding public getter (e.g., get_floors) and setter (e.g.,
	// set_floors) methods to your SurfaceStore C++ class for each of these
	// member variables. Example for 'floors': In SurfaceStore.h:
	//   public:
	//     void set_floors(const godot::Array& p_floors) { floors = p_floors; }
	//     godot::Array get_floors() const { return floors; }
	// (and similarly for other properties listed below)

	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "floors"), "set_floors", "get_floors");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "ceilings"), "set_ceilings",
			"get_ceilings");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "left_walls"), "set_left_walls",
			"get_left_walls");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "right_walls"), "set_right_walls",
			"get_right_walls");

	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "all_surfaces"), "set_all_surfaces",
			"get_all_surfaces");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "non_ceiling_surfaces"),
			"set_non_ceiling_surfaces", "get_non_ceiling_surfaces");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "non_floor_surfaces"),
			"set_non_floor_surfaces", "get_non_floor_surfaces");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "non_wall_surfaces"),
			"set_non_wall_surfaces", "get_non_wall_surfaces");
	ADD_PROPERTY(
			PropertyInfo(Variant::ARRAY, "all_walls"), "set_all_walls",
			"get_all_walls");

	// For 'marks', assuming SurfaceMark is a registered class (e.g., derives
	// from RefCounted or Resource). The hint string "SurfaceMark" helps the
	// editor understand the array element type.
	ADD_PROPERTY(
			PropertyInfo(
					Variant::ARRAY, "marks", PROPERTY_HINT_ARRAY_TYPE,
					"SurfaceMark"),
			"set_marks", "get_marks");

	ADD_PROPERTY(
			PropertyInfo(Variant::VECTOR2, "max_tilemap_cell_size"),
			"set_max_tilemap_cell_size", "get_max_tilemap_cell_size");
	ADD_PROPERTY(
			PropertyInfo(Variant::RECT2, "combined_tilemap_rect"),
			"set_combined_tilemap_rect", "get_combined_tilemap_rect");

	// Constant bindings
	// This makes the C++ constant available to GDScript as
	// SurfaceStore.SURFACES_TILE_MAPS_COLLISION_LAYER.
	ClassDB::bind_integer_constant(
			"SurfaceStore", "SURFACES_TILE_MAPS_COLLISION_LAYER",
			SURFACES_TILE_MAPS_COLLISION_LAYER);

	// The underscore-prefixed constants
	// (_CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET, etc.) are typically
	// internal. If they need to be exposed to script, you could:
	// 1. Expose them via static getter methods and bind those methods or
	// properties.
	// 2. If using a Godot version that supports it for GDExtension, use a
	// specific float constant binding method.
	//    (Note: ClassDB::bind_float_constant is not available in all Godot 4.x
	//    versions for GDExtension)
	// For now, they are not bound as they seem internal.
}

SurfaceStore::SurfaceStore() {
	// Assuming CollisionSurfaceResult is a RefCounted type (derives from
	// godot::Reference or godot::RefCounted)
	_collision_surface_result.instantiate();
}

SurfaceStore::~SurfaceStore() {}

Ref<Surface> SurfaceStore::get_surface_for_tile(
		TileMap *p_tile_map,
		int p_tilemap_index,
		int p_side) {
	// Using p_tile_map directly as a key might be problematic if the pointer
	// value is not stable. Consider using p_tile_map->get_instance_id() if
	// TileMap is an Object.
	Variant map_key = Variant(p_tile_map); // Or p_tile_map->get_instance_id();

	if (!_tilemap_index_to_surface_maps.has(map_key)) {
		return nullptr;
	}
	Dictionary tile_map_data = _tilemap_index_to_surface_maps[map_key];

	if (!tile_map_data.has(p_side)) {
		return nullptr;
	}
	Dictionary side_data = tile_map_data[p_side];

	if (side_data.has(p_tilemap_index)) {
		return side_data[p_tilemap_index]; // Assumes it stores Ref<Surface>
	} else {
		return nullptr;
	}
}

Dictionary SurfaceStore::get_surface_set(
		const MovementParameters *p_movement_params) {
	Dictionary set;
	if (!p_movement_params)
		return set; // Guard against null p_movement_params

	Array surface_collections;
	// Assuming MovementParameters has public bool members or getters like
	// can_grab_floors()
	if (p_movement_params->can_grab_floors) {
		surface_collections.push_back(floors);
	}
	if (p_movement_params->can_grab_walls) {
		surface_collections.push_back(all_walls);
	}
	if (p_movement_params->can_grab_ceilings) {
		surface_collections.push_back(ceilings);
	}

	for (int i = 0; i < surface_collections.size(); ++i) {
		Array surface_collection = surface_collections[i];
		for (int j = 0; j < surface_collection.size(); ++j) {
			Ref<Surface> surface = surface_collection[j];
			// Assuming Surface has a method like 'can_be_grabbed()' or similar
			// For 'surface.properties.can_grab', this implies Surface has a way
			// to get this boolean. Example: if (surface.is_valid() &&
			// surface->get_properties_config()->can_grab) For simplicity, let's
			// assume a method: surface->allows_grabbing()
			if (surface.is_valid() &&
				surface->allows_grabbing_via_properties()) {
				set[surface] = true;
			}
		}
	}

	for (int i = 0; i < marks.size(); ++i) {
		Ref<SurfaceMark> mark = marks[i];
		if (!mark.is_valid())
			continue;

		SurfaceEnablement *enablement_mark =
				Object::cast_to<SurfaceEnablement>(mark.ptr());
		if (!enablement_mark) {
			continue;
		}

		bool does_mark_match_character = false;
		// Assuming SurfaceMark has get_character_category_names() -> Array
		// Assuming MovementParameters has character_category_name (String or
		// StringName)
		Array category_names = mark->get_character_category_names();
		StringName char_category_name =
				p_movement_params->character_category_name;

		if (category_names.has(char_category_name)) {
			does_mark_match_character = true;
		}

		if (does_mark_match_character) {
			// Assuming SurfaceEnablement has these getters
			bool include_exclusively =
					enablement_mark->is_include_exclusively();
			bool exclude = enablement_mark->is_exclude();

			if (include_exclusively) {
				Array current_surfaces_in_set = set.keys();
				for (int k = 0; k < current_surfaces_in_set.size(); ++k) {
					Ref<Surface> surface_in_set = current_surfaces_in_set[k];
					// Assuming SurfaceMark has
					// get_is_surface_marked(Ref<Surface>) -> bool
					if (surface_in_set.is_valid() &&
						!mark->is_surface_marked(surface_in_set)) {
						set.erase(surface_in_set);
					}
				}
			} else if (exclude) {
				// Assuming SurfaceEnablement has get_marked_surfaces() -> Array
				// of Ref<Surface>
				Array marked_surfaces_by_this_mark =
						enablement_mark->get_explicitly_marked_surfaces();
				for (int k = 0; k < marked_surfaces_by_this_mark.size(); ++k) {
					Ref<Surface> marked_surface =
							marked_surfaces_by_this_mark[k];
					// Assuming Surface has get_first_point() -> Vector2
					if (marked_surface.is_valid() &&
						marked_surface->get_first_point() ==
								Vector2(-352, 256)) {
						UtilityFunctions::print(
								"C++ port: break condition met for surface "
								"exclusion");
					}
					set.erase(marked_surface); // Erasing by Ref<Surface> key
				}
			}
		}
	}
	return set;
}

void SurfaceStore::load_from_json_object(
		const Dictionary &p_json_object,
		const Dictionary &p_context,
		Object *p_surface_parser) {
	Array tilemaps_array;
	if (p_context.has("id_to_tilemap") &&
		p_context["id_to_tilemap"].get_type() == Variant::DICTIONARY) {
		Dictionary id_to_tilemap_dict = p_context["id_to_tilemap"];
		tilemaps_array = id_to_tilemap_dict.values();
	}

	if (p_surface_parser) {
		// Ensure p_surface_parser methods accept 'this' (SurfaceStore*) as the
		// first arg if mirroring 'self'
		p_surface_parser->call(
				"_calculate_max_tilemap_cell_size", this, tilemaps_array);
		p_surface_parser->call(
				"_calculate_combined_tilemap_rect", this, tilemaps_array);
	}

	floors = _json_object_to_surface_array(
			p_json_object.get("floors", Array()), p_context);
	ceilings = _json_object_to_surface_array(
			p_json_object.get("ceilings", Array()), p_context);
	left_walls = _json_object_to_surface_array(
			p_json_object.get("left_walls", Array()), p_context);
	right_walls = _json_object_to_surface_array(
			p_json_object.get("right_walls", Array()), p_context);

	// Assuming Surface has load_references_from_json_context(const Variant&
	// json_data, const Dictionary& context)
	Array json_floors = p_json_object.get("floors", Array());
	for (int i = 0; i < floors.size(); ++i) {
		Ref<Surface> surface = floors[i];
		if (surface.is_valid() && i < json_floors.size()) {
			surface->load_references_from_json_context(
					json_floors[i], p_context);
		}
	}
	Array json_ceilings = p_json_object.get("ceilings", Array());
	for (int i = 0; i < ceilings.size(); ++i) {
		Ref<Surface> surface = ceilings[i];
		if (surface.is_valid() && i < json_ceilings.size()) {
			surface->load_references_from_json_context(
					json_ceilings[i], p_context);
		}
	}
	Array json_left_walls = p_json_object.get("left_walls", Array());
	for (int i = 0; i < left_walls.size(); ++i) {
		Ref<Surface> surface = left_walls[i];
		if (surface.is_valid() && i < json_left_walls.size()) {
			surface->load_references_from_json_context(
					json_left_walls[i], p_context);
		}
	}
	Array json_right_walls = p_json_object.get("right_walls", Array());
	for (int i = 0; i < right_walls.size(); ++i) {
		Ref<Surface> surface = right_walls[i];
		if (surface.is_valid() && i < json_right_walls.size()) {
			surface->load_references_from_json_context(
					json_right_walls[i], p_context);
		}
	}

	if (p_surface_parser) {
		p_surface_parser->call(
				"_populate_derivative_collections", this, tilemaps_array);
	}
}

Dictionary SurfaceStore::to_json_object() {
	Dictionary result;
	result["floors"] = _surface_array_to_json_object(floors);
	result["ceilings"] = _surface_array_to_json_object(ceilings);
	result["left_walls"] = _surface_array_to_json_object(left_walls);
	result["right_walls"] = _surface_array_to_json_object(right_walls);
	return result;
}

Array SurfaceStore::_json_object_to_surface_array(
		const Array &p_json_object,
		const Dictionary &p_context) {
	Array result;
	result.resize(p_json_object.size());
	for (int i = 0; i < p_json_object.size(); ++i) {
		Ref<Surface> surface;
		surface.instantiate();
		// Assuming Surface has load_from_json_object(const Variant& json_data,
		// const Dictionary& context)
		if (p_json_object[i].get_type() == Variant::DICTIONARY) {
			surface->load_from_json_object(p_json_object[i], p_context);
		}
		result[i] = surface;
	}
	return result;
}

Array SurfaceStore::_surface_array_to_json_object(const Array &p_surfaces) {
	Array result;
	result.resize(p_surfaces.size());
	for (int i = 0; i < p_surfaces.size(); ++i) {
		Ref<Surface> surface = p_surfaces[i];
		if (surface.is_valid()) {
			// Assuming Surface has to_json_object() -> Dictionary
			result[i] = surface->to_json_object();
		} else {
			result[i] = Dictionary(); // Represent null/invalid surface as empty
									  // dictionary
		}
	}
	return result;
}
