#include "surface_finder.h"

#include <godot_cpp/core/class_db.hpp>

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/world2d.hpp> // Required for get_direct_space_state from world

using namespace godot;

// --- Static helper implementations (GeometryUtils, StringUtils,
// GlobalAccessors) ---
// TODO: You need to implement these utility functions based on your project's
// structure. Example stubs:
godot::Vector2 GeometryUtils::world_to_tilemap(
		const godot::Vector2 &p_world_pos,
		godot::TileMap *p_tile_map) {
	if (p_tile_map)
		return p_tile_map->local_to_map(p_tile_map->to_local(p_world_pos));
	return godot::Vector2(inf, inf);
}

int GeometryUtils::get_tilemap_index_from_grid_coord(
		const godot::Vector2 &p_grid_coord,
		godot::TileMap *p_tile_map) {
	// This depends on how you calculate tilemap index (e.g., for 1D array
	// mapping of 2D grid) For Godot TileMap, often you use the Vector2i
	// coordinate directly with get_cell_source_id etc. This function might need
	// to be adapted or removed if SurfaceStore handles indexing differently.
	if (p_tile_map) {
		// Placeholder: Godot TileMap uses Vector2i for cell coords.
		// If your 'tilemap_index' is a single int, you need a conversion.
		// This is a common pattern if you flatten 2D coords: return
		// p_grid_coord.y * width + p_grid_coord.x; For now, returning a hash or
		// simple conversion as a placeholder.
		return static_cast<int>(p_grid_coord.x) ^
				(static_cast<int>(p_grid_coord.y) << 16);
	}
	return -1;
}

SurfaceSide GeometryUtils::get_surface_side_for_normal(
		const godot::Vector2 &p_normal) {
	if (p_normal.is_equal_approx(Vector2(0, -1)))
		return SurfaceSide::FLOOR;
	if (p_normal.is_equal_approx(Vector2(0, 1)))
		return SurfaceSide::CEILING;
	if (p_normal.is_equal_approx(Vector2(1, 0)))
		return SurfaceSide::LEFT_WALL;
	if (p_normal.is_equal_approx(Vector2(-1, 0)))
		return SurfaceSide::RIGHT_WALL;
	// Add more precise logic for angled normals if needed
	if (abs(p_normal.x) > abs(p_normal.y)) {
		return p_normal.x > 0 ? SurfaceSide::LEFT_WALL
							  : SurfaceSide::RIGHT_WALL;
	} else {
		return p_normal.y > 0 ? SurfaceSide::CEILING : SurfaceSide::FLOOR;
	}
}
double GeometryUtils::distance_squared_from_point_to_rect(
		const godot::Vector2 &p_point,
		const godot::Rect2 &p_rect) {
	// Basic implementation, can be optimized
	if (p_rect.has_point(p_point))
		return 0.0;
	Vector2 closest_point = p_point.clamp(
			p_rect.get_position(), p_rect.get_position() + p_rect.get_size());
	return p_point.distance_squared_to(closest_point);
}
godot::Vector2 GeometryUtils::get_closest_point_on_polyline_to_point(
		const godot::Vector2 &p_point,
		const godot::Array &p_polyline_vertices) {
	if (p_polyline_vertices.is_empty())
		return p_point;
	if (p_polyline_vertices.size() == 1)
		return p_polyline_vertices[0];

	Vector2 closest_point_overall = p_polyline_vertices[0];
	double min_dist_sq = p_point.distance_squared_to(closest_point_overall);

	for (int i = 0; i < p_polyline_vertices.size() - 1; ++i) {
		Vector2 p1 = p_polyline_vertices[i];
		Vector2 p2 = p_polyline_vertices[i + 1];
		Vector2 segment_vec = p2 - p1;
		double segment_len_sq = segment_vec.length_squared();
		Vector2 closest_point_on_segment;

		if (segment_len_sq == 0.0) {
			closest_point_on_segment = p1;
		} else {
			double t = ((p_point - p1).dot(segment_vec)) / segment_len_sq;
			t = MAX(0.0, MIN(1.0, t)); // Clamp t to [0, 1]
			closest_point_on_segment = p1 + t * segment_vec;
		}

		double dist_sq = p_point.distance_squared_to(closest_point_on_segment);
		if (dist_sq < min_dist_sq) {
			min_dist_sq = dist_sq;
			closest_point_overall = closest_point_on_segment;
		}
	}
	// Check distance to last vertex as well, if polyline is not closed and last
	// point is distinct
	Vector2 last_v = p_polyline_vertices[p_polyline_vertices.size() - 1];
	double dist_sq_last = p_point.distance_squared_to(last_v);
	if (dist_sq_last < min_dist_sq) {
		closest_point_overall = last_v;
	}
	return closest_point_overall;
}
bool GeometryUtils::are_points_equal_with_epsilon(
		const godot::Vector2 &p_p1,
		const godot::Vector2 &p_p2,
		double p_epsilon) {
	return p_p1.is_equal_approx(p_p2, p_epsilon);
}

godot::String StringUtils::get_vector_string(
		const godot::Vector2 &p_vector,
		int p_precision) {
	return "(" + String::num(p_vector.x, p_precision) + ", " +
			String::num(p_vector.y, p_precision) + ")";
}

godot::String surface_side_to_string(SurfaceSide p_side) {
	switch (p_side) {
		case SurfaceSide::FLOOR:
			return "FLOOR";
		case SurfaceSide::LEFT_WALL:
			return "LEFT_WALL";
		case SurfaceSide::RIGHT_WALL:
			return "RIGHT_WALL";
		case SurfaceSide::CEILING:
			return "CEILING";
		case SurfaceSide::NONE:
			return "NONE";
		default:
			return "UNKNOWN_SIDE";
	}
}

PhysicsDirectSpaceState2D *GlobalAccessors::get_physics_space_state(
		RID p_world_rid) {
	return PhysicsServer2D::get_singleton()->space_get_direct_state(
			p_world_rid);
}
bool GlobalAccessors::are_reachable_surfaces_per_player_tracked() {
	// TODO: Implement this global accessor
	return true; // Placeholder
}
// --- End of Static helper implementations ---

SurfaceFinder::SurfaceFinder() {}
SurfaceFinder::~SurfaceFinder() {}

Ref<Surface> SurfaceFinder::find_closest_surface_in_direction(
		SurfaceStore *p_surface_store,
		RID p_world_rid,
		const Vector2 &p_target,
		const Vector2 &p_direction,
		Ref<CollisionSurfaceResult> p_collision_surface_result,
		double p_max_distance) {
	if (!p_surface_store)
		return nullptr;

	Ref<CollisionSurfaceResult> csr = p_collision_surface_result;
	if (csr.is_null()) {
		// Assuming SurfaceStore has a way to provide a default/cached
		// CollisionSurfaceResult For now, let's instantiate one if not
		// provided. csr = p_surface_store->get_default_collision_result(); //
		// Ideal
		csr.instantiate(); // Fallback
	}

	PhysicsDirectSpaceState2D *space_state =
			GlobalAccessors::get_physics_space_state(p_world_rid);
	if (!space_state) {
		UtilityFunctions::printerr(
				"SurfaceFinder: Physics space state is null.");
		return nullptr;
	}

	PhysicsDirectSpaceState2D::RayParameters ray_params;
	ray_params.from = p_target;
	ray_params.to = p_target + p_direction * p_max_distance;
	// ray_params.exclude = Array(); // Empty by default
	ray_params.collision_mask = SURFACES_TILE_MAPS_COLLISION_LAYER;
	ray_params.collide_with_bodies =
			true; // Corresponds to true in intersect_ray
	ray_params.collide_with_areas =
			false; // Corresponds to false in intersect_ray

	Dictionary collision = space_state->intersect_ray(ray_params);

	if (collision.is_empty()) {
		return nullptr;
	}

	Object *collider_obj = collision["collider"];
	TileMap *tile_map_collider = Object::cast_to<TileMap>(collider_obj);

	// CRASH_COND_MSG(tile_map_collider == nullptr, "Collision collider is not a
	// TileMap.");
	if (tile_map_collider == nullptr) {
		UtilityFunctions::printerr(
				"SurfaceFinder: Collision collider is not a TileMap.");
		return nullptr;
	}

	calculate_collision_surface(
			csr, p_surface_store, collision["position"], collision["normal"],
			tile_map_collider, true, false);

	return csr->get_surface(); // Assuming CollisionSurfaceResult has
							   // get_surface()
}

Ref<PositionAlongSurface> SurfaceFinder::find_closest_position_on_a_surface(
		const Vector2 &p_target,
		Character *p_character,
		SurfaceReachability p_surface_reachability,
		double p_max_distance_squared_threshold,
		const Vector2 &p_max_distance_basis_point) {
	if (!p_character)
		return nullptr;

	Variant surfaces_variant; // Can be Array or Dictionary
	switch (p_surface_reachability) {
		case SurfaceReachability::ANY:
			surfaces_variant =
					p_character
							->get_possible_surfaces_set(); // Assuming this
														   // returns Dictionary
														   // or Array
			break;
		case SurfaceReachability::REACHABLE:
			// CRASH_COND_MSG(!GlobalAccessors::are_reachable_surfaces_per_player_tracked(),
			// "Reachable surfaces not tracked.");
			if (!GlobalAccessors::are_reachable_surfaces_per_player_tracked()) {
				UtilityFunctions::printerr(
						"SurfaceFinder: Reachable surfaces not tracked for "
						"find_closest_position_on_a_surface.");
				return nullptr;
			}
			surfaces_variant = p_character->get_reachable_surfaces();
			break;
		case SurfaceReachability::REVERSIBLY_REACHABLE:
			// CRASH_COND_MSG(!GlobalAccessors::are_reachable_surfaces_per_player_tracked(),
			// "Reversibly reachable surfaces not tracked.");
			if (!GlobalAccessors::are_reachable_surfaces_per_player_tracked()) {
				UtilityFunctions::printerr(
						"SurfaceFinder: Reversibly reachable surfaces not "
						"tracked for find_closest_position_on_a_surface.");
				return nullptr;
			}
			surfaces_variant = p_character->get_reversibly_reachable_surfaces();
			break;
		default:
			UtilityFunctions::printerr(
					"SurfaceFinder.find_closest_position_on_a_surface: Invalid "
					"SurfaceReachability.");
			return nullptr;
	}

	Array positions = find_closest_positions_on_surfaces(
			p_target, p_character,
			7, // position_count from original GDScript
			p_max_distance_squared_threshold, p_max_distance_basis_point,
			surfaces_variant);

	if (positions.is_empty()) {
		return nullptr;
	} else {
		return positions[0]; // Assuming positions[0] is
							 // Ref<PositionAlongSurface>
	}
}

Array SurfaceFinder::find_closest_positions_on_surfaces(
		const Vector2 &p_target,
		Character *p_character,
		int p_position_count,
		double p_max_distance_squared_threshold,
		const Vector2 &p_max_distance_basis_point,
		const Variant &p_surfaces) {
	if (!p_character)
		return Array();

	Variant surfaces_to_check = p_surfaces;
	bool p_surfaces_is_empty = false;
	if (p_surfaces.get_type() == Variant::ARRAY) {
		p_surfaces_is_empty = ((Array)p_surfaces).is_empty();
	} else if (p_surfaces.get_type() == Variant::DICTIONARY) {
		p_surfaces_is_empty = ((Dictionary)p_surfaces).is_empty();
	} else if (p_surfaces.get_type() == Variant::NIL) { // Check if it was
														// default constructed
														// (empty array)
		p_surfaces_is_empty = true;
	}

	if (p_surfaces_is_empty) {
		surfaces_to_check = p_character->get_possible_surfaces_set();
	}

	Array closest_surfaces_refs = get_closest_surfaces(
			p_target, surfaces_to_check, p_position_count,
			p_max_distance_squared_threshold, p_max_distance_basis_point);

	Array closest_positions;
	closest_positions.resize(closest_surfaces_refs.size());

	int valid_position_count = 0;

	for (int i = 0; i < closest_surfaces_refs.size(); ++i) {
		Ref<Surface> current_surface = closest_surfaces_refs[i];
		if (current_surface.is_null())
			continue;

		Ref<PositionAlongSurface> position;
		position.instantiate(); // Or memnew if not RefCounted

		// Assuming PositionAlongSurface::match_surface_target_and_collider
		// exists and Character::get_collider() returns the collider object.
		position->match_surface_target_and_collider(
				current_surface, p_target,
				p_character
						->get_collider(), // Assuming Character::get_collider()
				true, true, true);

		if (position->get_target_point() !=
			Vector2(inf,
					inf)) { // Assuming
							// PositionAlongSurface::get_target_point()
			closest_positions[valid_position_count] = position;
			valid_position_count++;
		}
	}

	closest_positions.resize(valid_position_count);
	return closest_positions;
}

Array SurfaceFinder::get_closest_surfaces(
		const Vector2 &p_target,
		const Variant
				&p_surfaces_variant, // Dictionary or Array of Ref<Surface>
		int p_surface_count,
		double p_max_distance_squared_threshold,
		const Vector2 &p_max_distance_basis_point) {
	Array surfaces_to_iterate;
	if (p_surfaces_variant.get_type() == Variant::DICTIONARY) {
		surfaces_to_iterate = ((Dictionary)p_surfaces_variant)
									  .keys(); // Assuming keys are Ref<Surface>
											   // or convertible
	} else if (p_surfaces_variant.get_type() == Variant::ARRAY) {
		surfaces_to_iterate = p_surfaces_variant;
	}

	// CRASH_COND_MSG(surfaces_to_iterate.is_empty(), "Input surfaces collection
	// is empty in get_closest_surfaces.");
	if (surfaces_to_iterate.is_empty()) {
		UtilityFunctions::print_verbose(
				"SurfaceFinder: Input surfaces collection is empty in "
				"get_closest_surfaces.");
		return Array();
	}

	Vector2 basis_point = (p_max_distance_basis_point == Vector2(inf, inf))
			? p_target
			: p_max_distance_basis_point;
	double next_distance_squared_to_beat = p_max_distance_squared_threshold;
	Array closest_surfaces_and_distances; // Stores Array of [Ref<Surface>,
										  // double distance_sq]

	for (int i = 0; i < surfaces_to_iterate.size(); ++i) {
		Ref<Surface> current_surface = surfaces_to_iterate[i];
		if (current_surface.is_null())
			continue;

		// Assuming Surface has get_bounding_box(), get_vertices(),
		// get_first_point(), get_last_point(), get_side()
		Rect2 current_bbox = current_surface->get_bounding_box();
		double current_target_distance_squared =
				GeometryUtils::distance_squared_from_point_to_rect(
						p_target, current_bbox);
		double current_max_distance_basis_distance_squared =
				GeometryUtils::distance_squared_from_point_to_rect(
						basis_point, current_bbox);

		if (current_target_distance_squared < next_distance_squared_to_beat &&
			current_max_distance_basis_distance_squared <
					p_max_distance_squared_threshold) {
			Vector2 closest_point =
					GeometryUtils::get_closest_point_on_polyline_to_point(
							p_target, current_surface->get_vertices());
			current_target_distance_squared =
					p_target.distance_squared_to(closest_point);
			current_max_distance_basis_distance_squared =
					basis_point.distance_squared_to(closest_point);

			if (current_target_distance_squared <
						next_distance_squared_to_beat &&
				current_max_distance_basis_distance_squared <
						p_max_distance_squared_threshold) {
				bool is_closest_to_first_point =
						GeometryUtils::are_points_equal_with_epsilon(
								closest_point,
								current_surface->get_first_point(), 0.01);
				bool is_closest_to_last_point =
						GeometryUtils::are_points_equal_with_epsilon(
								closest_point,
								current_surface->get_last_point(), 0.01);

				if (is_closest_to_first_point || is_closest_to_last_point) {
					Vector2 first_point_diff =
							p_target - current_surface->get_first_point();
					Vector2 last_point_diff =
							p_target - current_surface->get_last_point();
					bool is_more_than_45_deg_from_normal_from_corner = false;

					SurfaceSide side =
							current_surface
									->get_side(); // Assuming
												  // Surface::get_side() returns
												  // SurfaceSide enum
					switch (side) {
						case SurfaceSide::FLOOR:
							if (is_closest_to_first_point)
								is_more_than_45_deg_from_normal_from_corner =
										first_point_diff.x < 0.0 &&
										-first_point_diff.x >
												-first_point_diff.y;
							else
								is_more_than_45_deg_from_normal_from_corner =
										last_point_diff.x > 0.0 &&
										last_point_diff.x > -last_point_diff.y;
							break;
						case SurfaceSide::LEFT_WALL:
							if (is_closest_to_first_point)
								is_more_than_45_deg_from_normal_from_corner =
										first_point_diff.y < 0.0 &&
										first_point_diff.x <
												-first_point_diff.y;
							else
								is_more_than_45_deg_from_normal_from_corner =
										last_point_diff.y > 0.0 &&
										last_point_diff.x < last_point_diff.y;
							break;
						case SurfaceSide::RIGHT_WALL:
							if (is_closest_to_first_point)
								is_more_than_45_deg_from_normal_from_corner =
										first_point_diff.y > 0.0 &&
										-first_point_diff.x <
												first_point_diff.y;
							else
								is_more_than_45_deg_from_normal_from_corner =
										last_point_diff.y < 0.0 &&
										-first_point_diff.x <
												-last_point_diff.y;
							break;
						case SurfaceSide::CEILING:
							if (is_closest_to_first_point)
								is_more_than_45_deg_from_normal_from_corner =
										first_point_diff.x > 0.0 &&
										first_point_diff.x > first_point_diff.y;
							else
								is_more_than_45_deg_from_normal_from_corner =
										last_point_diff.x < 0.0 &&
										-last_point_diff.x > last_point_diff.y;
							break;
						default:
							UtilityFunctions::printerr(
									"get_closest_surfaces: Invalid "
									"SurfaceSide.");
							break;
					}
					current_target_distance_squared +=
							is_more_than_45_deg_from_normal_from_corner
							? _CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET
							: _CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET;
				}

				Array surface_and_dist_item;
				surface_and_dist_item.push_back(current_surface);
				surface_and_dist_item.push_back(
						current_target_distance_squared);

				bool was_added = maybe_add_surface_to_closest_n_collection(
						closest_surfaces_and_distances, surface_and_dist_item,
						p_surface_count);
				if (was_added) {
					next_distance_squared_to_beat =
							(closest_surfaces_and_distances.size() ==
							 p_surface_count)
							? closest_surfaces_and_distances
									  [p_surface_count - 1]
											  .operator Array()[1]
											  .operator double()
							: p_max_distance_squared_threshold;
				}
			}
		}
	}

	Array result_surfaces;
	result_surfaces.resize(closest_surfaces_and_distances.size());
	for (int i = 0; i < closest_surfaces_and_distances.size(); ++i) {
		result_surfaces[i] =
				closest_surfaces_and_distances[i].operator Array()[0];
	}
	return result_surfaces;
}

bool SurfaceFinder::_surface_and_distance_sort_ascending_comparator(
		const Variant &p_a_variant,
		const Variant &p_b_variant) {
	Array p_a = p_a_variant;
	Array p_b = p_b_variant;
	// Ensure arrays have at least 2 elements and the second is a number
	if (p_a.size() >= 2 && p_b.size() >= 2 &&
		p_a[1].get_type() >= Variant::INT &&
		p_a[1].get_type() <= Variant::FLOAT && // is_num
		p_b[1].get_type() >= Variant::INT &&
		p_b[1].get_type() <= Variant::FLOAT) {
		return p_a[1].operator double() < p_b[1].operator double();
	}
	// Fallback or error handling if types are unexpected
	if (p_a.size() < 2)
		return true; // Sort 'a' first if it's malformed
	if (p_b.size() < 2)
		return false; // Sort 'b' first if it's malformed
	return false; // Default case
}

bool SurfaceFinder::maybe_add_surface_to_closest_n_collection(
		Array &p_collection, // Array of Array[Ref<Surface>, double distance_sq]
		const Array &p_surface_and_distance,
		int p_n) {
	if (p_collection.size() < p_n) {
		p_collection.push_back(p_surface_and_distance);
		p_collection.sort_custom(
				Callable::from_static(
						&SurfaceFinder::
								_surface_and_distance_sort_ascending_comparator));
		return true;
	} else {
		// Check if p_surface_and_distance[1] is smaller than the last element's
		// distance in p_collection
		if (p_surface_and_distance[1].operator double() <
			p_collection[p_n - 1].operator Array()[1].operator double()) {
			p_collection[p_n - 1] = p_surface_and_distance;
			p_collection.sort_custom(
					Callable::from_static(
							&SurfaceFinder::
									_surface_and_distance_sort_ascending_comparator));
			return true;
		}
	}
	return false;
}

void SurfaceFinder::calculate_collision_surface(
		godot::Ref<godot::CollisionSurfaceResult> p_result,
		godot::SurfaceStore *p_surface_store,
		const godot::Vector2 &p_collision_position,
		const godot::Variant &p_collision_normal_or_side,
		godot::TileMap *p_tile_map,
		bool p_tries_adjusted_collision_normal,
		bool p_allows_errors,
		bool p_is_nested_call) {
	if (p_result.is_null()) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: Result object is "
				"null.");
		return;
	}
	if (!p_surface_store) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: SurfaceStore is "
				"null.");
		p_result->set_error_message("SurfaceStore is null.");
		return;
	}
	if (!p_tile_map) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: TileMap is null.");
		p_result->set_error_message("TileMap is null.");
		return;
	}
	if (p_tile_map->get_tileset().is_null()) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: TileMap has no "
				"TileSet.");
		p_result->set_error_message("TileMap has no TileSet.");
		return;
	}

	godot::Vector2i tile_size_i = p_tile_map->get_tileset()->get_tile_size();
	if (tile_size_i.x == 0 || tile_size_i.y == 0) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: TileMap effective "
				"cell size is zero.");
		p_result->set_error_message("TileMap effective cell size is zero.");
		return;
	}
	godot::Vector2 cell_size = godot::Vector2(tile_size_i);
	godot::Vector2 half_cell_size = cell_size / 2.0;

	godot::Rect2i used_rect_i = p_tile_map->get_used_rect();
	godot::Vector2 world_pos_of_used_rect_origin_cell =
			p_tile_map->map_to_world(used_rect_i.position);
	godot::Vector2 position_relative_to_used_rect_origin =
			p_collision_position - world_pos_of_used_rect_origin_cell;

	double cell_width_mod = std::abs(
			std::fmod(position_relative_to_used_rect_origin.x, cell_size.x));
	double cell_height_mod = std::abs(
			std::fmod(position_relative_to_used_rect_origin.y, cell_size.y));

	bool is_between_cells_horizontally =
			cell_width_mod < _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD ||
			cell_size.x - cell_width_mod <
					_COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD;
	bool is_between_cells_vertically =
			cell_height_mod < _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD ||
			cell_size.y - cell_height_mod <
					_COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD;

	if (p_tries_adjusted_collision_normal &&
		p_collision_normal_or_side.get_type() != godot::Variant::VECTOR2) {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder::calculate_collision_surface: "
				"tries_adjusted_collision_normal is true, but "
				"collision_normal_or_side is not a Vector2.");
		p_result->set_error_message(
				"Adjusted normal requires Vector2 input for "
				"p_collision_normal_or_side.");
		return;
	}

	godot::Surface::Side collision_side_enum;
	if (p_collision_normal_or_side.get_type() == godot::Variant::INT ||
		p_collision_normal_or_side.get_type() == godot::Variant::INT64) {
		collision_side_enum = static_cast<godot::Surface::Side>(
				p_collision_normal_or_side.operator int64_t());
	} else if (
			p_collision_normal_or_side.get_type() == godot::Variant::VECTOR2) {
		collision_side_enum =
				godot::SurfacerGeometry::get_surface_side_for_normal(
						p_collision_normal_or_side);
	} else {
		godot::UtilityFunctions::printerr(
				"SurfaceFinder.calculate_collision_surface: Invalid type for "
				"p_collision_normal_or_side.");
		p_result->set_error_message(
				"Invalid type for p_collision_normal_or_side.");
		return;
	}

	bool is_touching_floor = false;
	bool is_touching_ceiling = false;
	bool is_touching_left_wall = false;
	bool is_touching_right_wall = false;

	switch (collision_side_enum) {
		case godot::Surface::Side::FLOOR:
			is_touching_floor = true;
			break;
		case godot::Surface::Side::CEILING:
			is_touching_ceiling = true;
			break;
		case godot::Surface::Side::LEFT_WALL:
			is_touching_left_wall = true;
			break;
		case godot::Surface::Side::RIGHT_WALL:
			is_touching_right_wall = true;
			break;
		default:
			// This case should ideally not be reached if
			// get_surface_side_for_normal is robust or if integer side is
			// always valid.
			godot::UtilityFunctions::print_verbose(
					"SurfaceFinder.calculate_collision_surface: Unknown "
					"initial collision_side_enum.");
			break;
	}

	godot::Surface::Side determined_surface_side =
			godot::Surface::Side::UNKNOWN_SIDE;
	godot::Vector2 determined_tile_coord =
			godot::Vector2(inf, inf); // Using float Vector2 for map coords
	godot::String error_message = "";
	godot::Ref<godot::Surface> found_surface = nullptr;

	auto get_map_coord = [&](godot::Vector2 world_pos) {
		return p_tile_map->local_to_map(p_tile_map->to_local(world_pos));
	};

	if (is_between_cells_horizontally && is_between_cells_vertically) {
		godot::Vector2 top_left_cell_coord = get_map_coord(
				godot::Vector2(
						p_collision_position.x - half_cell_size.x,
						p_collision_position.y - half_cell_size.y));
		godot::Vector2 top_right_cell_coord = get_map_coord(
				godot::Vector2(
						p_collision_position.x + half_cell_size.x,
						p_collision_position.y - half_cell_size.y));
		godot::Vector2 bottom_left_cell_coord = get_map_coord(
				godot::Vector2(
						p_collision_position.x - half_cell_size.x,
						p_collision_position.y + half_cell_size.y));
		godot::Vector2 bottom_right_cell_coord = get_map_coord(
				godot::Vector2(
						p_collision_position.x + half_cell_size.x,
						p_collision_position.y + half_cell_size.y));

		if (is_touching_floor && is_touching_left_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, bottom_right_cell_coord,
						godot::Surface::Side::FLOOR) is_valid()) {
				determined_tile_coord = bottom_right_cell_coord;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_right_cell_coord,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = bottom_right_cell_coord;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_left_cell_coord,
									   godot::Surface::Side::FLOOR)
									   is_valid()) {
				determined_tile_coord = top_left_cell_coord;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_left_cell_coord,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = top_left_cell_coord;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else {
				error_message = "between_hv floor_left_wall";
			}
		} else if (is_touching_floor && is_touching_right_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, bottom_left_cell_coord,
						godot::Surface::Side::FLOOR) is_valid()) {
				determined_tile_coord = bottom_left_cell_coord;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_left_cell_coord,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = bottom_left_cell_coord;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_right_cell_coord,
									   godot::Surface::Side::FLOOR)
									   is_valid()) {
				determined_tile_coord = top_right_cell_coord;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_right_cell_coord,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = top_right_cell_coord;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else {
				error_message = "between_hv floor_right_wall";
			}
		} else if (is_touching_ceiling && is_touching_left_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, top_right_cell_coord,
						godot::Surface::Side::CEILING) is_valid()) {
				determined_tile_coord = top_right_cell_coord;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_right_cell_coord,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = top_right_cell_coord;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_left_cell_coord,
									   godot::Surface::Side::CEILING)
									   is_valid()) {
				determined_tile_coord = bottom_left_cell_coord;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_left_cell_coord,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = bottom_left_cell_coord;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else {
				error_message = "between_hv ceiling_left_wall";
			}
		} else if (is_touching_ceiling && is_touching_right_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, top_left_cell_coord,
						godot::Surface::Side::CEILING) is_valid()) {
				determined_tile_coord = top_left_cell_coord;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, top_left_cell_coord,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = top_left_cell_coord;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_right_cell_coord,
									   godot::Surface::Side::CEILING)
									   is_valid()) {
				determined_tile_coord = bottom_right_cell_coord;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map, bottom_right_cell_coord,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = bottom_right_cell_coord;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else {
				error_message = "between_hv ceiling_right_wall";
			}
		} else {
			error_message = "between_hv fallthrough";
		}
	} else if (is_between_cells_vertically) {
		godot::Vector2 current_cell_coord_plus_one_y = get_map_coord(
				godot::Vector2(
						p_collision_position.x,
						p_collision_position.y + half_cell_size.y));
		godot::Vector2 current_cell_coord_minus_one_y = get_map_coord(
				godot::Vector2(
						p_collision_position.x,
						p_collision_position.y - half_cell_size.y));
		if (is_touching_floor) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_y,
						godot::Surface::Side::FLOOR) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_y;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_y,
									   godot::Surface::Side::FLOOR)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_y;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else {
				error_message = "between_v floor";
			}
		} else if (is_touching_ceiling) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_minus_one_y,
						godot::Surface::Side::CEILING) is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_y;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_plus_one_y,
									   godot::Surface::Side::CEILING)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_y;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else {
				error_message = "between_v ceiling";
			}
		} else if (is_touching_left_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_y,
						godot::Surface::Side::LEFT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_y;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_y,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_y;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else {
				error_message = "between_v left_wall";
			}
		} else if (is_touching_right_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_y,
						godot::Surface::Side::RIGHT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_y;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_y,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_y;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else {
				error_message = "between_v right_wall";
			}
		} else {
			error_message = "between_v fallthrough";
		}
	} else if (is_between_cells_horizontally) {
		godot::Vector2 current_cell_coord_plus_one_x = get_map_coord(
				godot::Vector2(
						p_collision_position.x + half_cell_size.x,
						p_collision_position.y));
		godot::Vector2 current_cell_coord_minus_one_x = get_map_coord(
				godot::Vector2(
						p_collision_position.x - half_cell_size.x,
						p_collision_position.y));
		if (is_touching_floor) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_x,
						godot::Surface::Side::FLOOR) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_x;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_x,
									   godot::Surface::Side::FLOOR)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_x;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else {
				error_message = "between_h floor";
			}
		} else if (is_touching_ceiling) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_x,
						godot::Surface::Side::CEILING) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_x;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_x,
									   godot::Surface::Side::CEILING)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_x;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else {
				error_message = "between_h ceiling";
			}
		} else if (is_touching_left_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_x,
						godot::Surface::Side::LEFT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_x;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_x,
									   godot::Surface::Side::LEFT_WALL)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_x;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else {
				error_message = "between_h left_wall";
			}
		} else if (is_touching_right_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord_plus_one_x,
						godot::Surface::Side::RIGHT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord_plus_one_x;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else if (p_surface_store
							   ->get_surface_for_tile_by_map_coord_and_side(
									   p_tile_map,
									   current_cell_coord_minus_one_x,
									   godot::Surface::Side::RIGHT_WALL)
									   is_valid()) {
				determined_tile_coord = current_cell_coord_minus_one_x;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else {
				error_message = "between_h right_wall";
			}
		} else {
			error_message = "between_h fallthrough";
		}
	} else { // In cell interior
		godot::Vector2 current_cell_coord = get_map_coord(p_collision_position);
		if (is_touching_floor) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord,
						godot::Surface::Side::FLOOR) is_valid()) {
				determined_tile_coord = current_cell_coord;
				determined_surface_side = godot::Surface::Side::FLOOR;
			} else {
				error_message = "interior no_floor_in_cell";
			}
		} else if (is_touching_ceiling) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord,
						godot::Surface::Side::CEILING) is_valid()) {
				determined_tile_coord = current_cell_coord;
				determined_surface_side = godot::Surface::Side::CEILING;
			} else {
				error_message = "interior no_ceiling_in_cell";
			}
		} else if (is_touching_left_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord,
						godot::Surface::Side::LEFT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord;
				determined_surface_side = godot::Surface::Side::LEFT_WALL;
			} else {
				error_message = "interior no_left_wall_in_cell";
			}
		} else if (is_touching_right_wall) {
			if (p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, current_cell_coord,
						godot::Surface::Side::RIGHT_WALL) is_valid()) {
				determined_tile_coord = current_cell_coord;
				determined_surface_side = godot::Surface::Side::RIGHT_WALL;
			} else {
				error_message = "interior no_right_wall_in_cell";
			}
		} else {
			error_message = "interior fallthrough";
		}
	}

	if (determined_tile_coord != godot::Vector2(inf, inf) &&
		determined_surface_side != godot::Surface::Side::UNKNOWN_SIDE) {
		found_surface =
				p_surface_store->get_surface_for_tile_by_map_coord_and_side(
						p_tile_map, determined_tile_coord,
						determined_surface_side);
		if (found_surface.is_null() && error_message.is_empty()) {
			error_message =
					"Determined cell/side but no surface found in store.";
		} else if (is_valid(found_surface)) {
			error_message = ""; // Clear error if surface is successfully found
		}
	} else if (error_message.is_empty()) { // No specific error but also no
										   // determined tile/side
		error_message = "Could not determine a valid tile coordinate or "
						"surface side from initial logic.";
	}

	p_result->set_surface(found_surface);
	p_result->set_surface_side(determined_surface_side);
	p_result->set_tilemap_coord(
			determined_tile_coord); // Assuming CollisionSurfaceResult stores
									// Vector2 for map coord
	p_result->set_flipped_sides_for_nested_call(p_is_nested_call);
	p_result->set_error_message(error_message);

	if (!error_message.is_empty() && !p_is_nested_call) {
		godot::Variant reversed_normal_or_side_variant;
		if (p_collision_normal_or_side.get_type() == godot::Variant::INT ||
			p_collision_normal_or_side.get_type() == godot::Variant::INT64) {
			godot::Surface::Side original_side =
					static_cast<godot::Surface::Side>(
							p_collision_normal_or_side.operator int64_t());
			godot::Surface::Side reversed_side_enum =
					godot::Surface::Side::UNKNOWN_SIDE;
			switch (original_side) {
				case godot::Surface::Side::FLOOR:
					reversed_side_enum = godot::Surface::Side::CEILING;
					break;
				case godot::Surface::Side::LEFT_WALL:
					reversed_side_enum = godot::Surface::Side::RIGHT_WALL;
					break;
				case godot::Surface::Side::RIGHT_WALL:
					reversed_side_enum = godot::Surface::Side::LEFT_WALL;
					break;
				case godot::Surface::Side::CEILING:
					reversed_side_enum = godot::Surface::Side::FLOOR;
					break;
				default:
					break;
			}
			if (reversed_side_enum != godot::Surface::Side::UNKNOWN_SIDE) {
				reversed_normal_or_side_variant =
						static_cast<int64_t>(reversed_side_enum);
			}
		} else if (
				p_collision_normal_or_side.get_type() ==
				godot::Variant::VECTOR2) {
			reversed_normal_or_side_variant =
					-p_collision_normal_or_side.operator godot::Vector2();
		}

		if (reversed_normal_or_side_variant.get_type() != godot::Variant::NIL) {
			calculate_collision_surface(
					p_result, p_surface_store, p_collision_position,
					reversed_normal_or_side_variant, p_tile_map, false,
					p_allows_errors, true);
			if (p_result->get_error_message().is_empty())
				return; // Successfully resolved with reversed normal
		}

		// Restore original error message if reversed normal didn't help, before
		// trying adjusted normal
		p_result->set_error_message(error_message);
		p_result->set_surface(nullptr); // Clear potentially incorrect surface
										// from reversed attempt
		p_result->set_surface_side(godot::Surface::Side::UNKNOWN_SIDE);
		p_result->set_tilemap_coord(godot::Vector2(inf, inf));

		if (p_tries_adjusted_collision_normal &&
			p_collision_normal_or_side.get_type() == godot::Variant::VECTOR2) {
			godot::Vector2 original_normal = p_collision_normal_or_side;
			godot::Vector2 adjusted_collision_normal;
			if ((original_normal.x < 0.0) ==
				(original_normal.y < 0.0)) { // Same sign or both zero
				adjusted_collision_normal =
						godot::Vector2(original_normal.y, original_normal.x);
			} else { // Different signs
				adjusted_collision_normal =
						godot::Vector2(-original_normal.y, -original_normal.x);
			}
			calculate_collision_surface(
					p_result, p_surface_store, p_collision_position,
					adjusted_collision_normal, p_tile_map, false,
					p_allows_errors, false); // is_nested_call is false here
			if (p_result->get_error_message().is_empty())
				return; // Successfully resolved with adjusted normal
		}
	}

	// Final error reporting based on the original error message if retries
	// failed
	if (!p_result->get_error_message().is_empty() && !p_allows_errors &&
		!p_is_nested_call) {
		godot::String normal_or_side_str;
		if (p_collision_normal_or_side.get_type() == godot::Variant::INT ||
			p_collision_normal_or_side.get_type() == godot::Variant::INT64) {
			normal_or_side_str = surface_side_to_string_helper(
					static_cast<godot::Surface::Side>(
							p_collision_normal_or_side.operator int64_t()));
		} else if (
				p_collision_normal_or_side.get_type() ==
				godot::Variant::VECTOR2) {
			normal_or_side_str =
					StringUtils_SurfaceFinderHelper::get_vector_string(
							p_collision_normal_or_side, 3);
		} else {
			normal_or_side_str = "INVALID_TYPE";
		}

		godot::String final_print_message =
				godot::String(
						"ERROR: INVALID COLLISION TILEMAP STATE: {0}; "
						"collision_position={1} collision_normal_or_side={2} "
						"is_touching_floor={3} is_touching_ceiling={4} "
						"is_touching_left_wall={5} is_touching_right_wall={6} "
						"is_between_cells_horizontally={7} "
						"is_between_cells_vertically={8} tile_coord={9}")
						.format(godot::Array::make(
								p_result->get_error_message(), // Use the error
															   // message from
															   // p_result,
															   // which might be
															   // from a retry
								StringUtils_SurfaceFinderHelper::
										get_vector_string(
												p_collision_position, 2),
								normal_or_side_str, is_touching_floor,
								is_touching_ceiling, is_touching_left_wall,
								is_touching_right_wall,
								is_between_cells_horizontally,
								is_between_cells_vertically,
								StringUtils_SurfaceFinderHelper::
										get_vector_string(
												p_result->get_tilemap_coord(),
												2) // Use coord from p_result
								));
		godot::UtilityFunctions::printerr(final_print_message);

	} else if (
			!p_result->get_error_message().is_empty() && p_allows_errors &&
			!p_is_nested_call) {
		godot::UtilityFunctions::print_warning(
				"Warning: Collision Tilemap State (allows_errors=true): " +
				p_result->get_error_message());
	}
}

void SurfaceFinder::_bind_methods() {
	// If you need to expose static methods to GDScript, bind them here.
	// Example: ClassDB::bind_static_method("SurfaceFinder",
	// D_METHOD("find_closest_surface_in_direction", ...),
	// &SurfaceFinder::find_closest_surface_in_direction);
}
