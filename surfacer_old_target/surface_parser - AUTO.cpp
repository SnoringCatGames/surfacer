#include "surface_parser.h"

#include <godot_cpp/classes/convex_polygon_shape2d.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/tile_data.hpp> // For Godot 4 TileSet interactions
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

// Assuming definitions for SurfaceStore, SurfaceMark, SurfacesTilemap, etc. are
// included. For example:
#include "corner_match_inner_tilemap.h" // Assuming this exists
#include "surface.h" // Assuming this exists
#include "surface_mark.h" // Assuming this exists
#include "surface_properties.h" // Assuming this exists
#include "surface_store.h" // Assuming this exists
#include "surfaces_tilemap.h" // Assuming this exists, extending TileMap
#include "surfaces_tileset.h" // Assuming this exists, extending TileSet
#include "tile_shape_data.h" // Assuming this exists

// Placeholder initializations for Sc and Su statics
// These need to be properly defined and initialized in your project.
// Example:
// godot::Vector2 godot::Sc::Levels::Config::cell_size = godot::Vector2(16,16);
// bool godot::Su::are_oddly_shaped_surfaces_used = false;
// godot::Sc::Levels* godot::Sc::Levels::get_singleton() { static Levels
// instance; return &instance; }

// --- Helper struct for Sc and Su placeholders ---
// This should be replaced by your actual implementation of these utilities.
namespace godot {

// Default Sc::Levels::Config::cell_size if not set elsewhere
Vector2 Sc::Levels::Config::cell_size =
		Vector2(16, 16); // Default, adjust as needed
bool Su::are_oddly_shaped_surfaces_used = false; // Default

Sc::Levels *Sc::Levels::get_singleton() {
	static Levels instance;
	// Potentially initialize instance.session.config.cell_size here if needed
	return &instance;
}

// Example implementations for Sc::Geometry (replace with actuals)
bool Sc::Geometry::are_points_collinear(
		Vector2 p_p1,
		Vector2 p_p2,
		Vector2 p_p3,
		double p_epsilon) {
	// Simplified collinearity check
	return Math::is_zero_approx(
			((p_p2.y - p_p1.y) * (p_p3.x - p_p2.x)) -
			((p_p3.y - p_p2.y) * (p_p2.x - p_p1.x)));
}
bool Sc::Geometry::are_points_equal_with_epsilon(
		Vector2 p_p1,
		Vector2 p_p2,
		double p_epsilon) {
	return p_p1.is_equal_approx(p_p2, p_epsilon);
}
bool Sc::Geometry::are_floats_equal_with_epsilon(
		double p_f1,
		double p_f2,
		double p_epsilon) {
	return Math::is_equal_approx(p_f1, p_f2, p_epsilon);
}
bool Sc::Geometry::is_polygon_clockwise(const Array &p_vertices) {
	if (p_vertices.size() < 3)
		return true; // Or false, define behavior for degenerate cases
	double sum = 0.0;
	for (int i = 0; i < p_vertices.size(); ++i) {
		Vector2 v1 = p_vertices[i];
		Vector2 v2 = p_vertices[(i + 1) % p_vertices.size()];
		sum += (v2.x - v1.x) * (v2.y + v1.y);
	}
	return sum > 0.0;
}
Rect2 Sc::Geometry::get_tilemap_bounds_in_world_coordinates(
		const TileMap *p_tile_map) {
	if (!p_tile_map || p_tile_map->get_layers_count() == 0)
		return Rect2();
	// Assuming we use the specified layer or layer 0 if not specified elsewhere
	// Godot 4 TileMap itself doesn't have a single cell_size or position
	// directly. This function might need to iterate layers or take a layer
	// index. For simplicity, let's assume it works on layer 0 or a relevant
	// layer. This is a major simplification. A robust version would handle
	// layers correctly.
	Rect2i used_rect =
			p_tile_map
					->get_used_rect(); // Gets combined used_rect of all layers
	if (p_tile_map->get_layers_count() > 0) {
		Ref<TileSet> ts = p_tile_map->get_tile_set();
		if (ts.is_valid()) {
			Vector2 tile_size = ts->get_tile_size();
			// TileMap position is (0,0) in Godot 4 for the node itself.
			// The GDScript assumes tile_map.position.
			// If tile_map is a TileMapLayer, then get_position() would work.
			// This needs clarification based on what `TileMap* p_tile_map`
			// actually is. Assuming p_tile_map is a Godot 4 TileMap node, its
			// position is its Node2D position.
			return Rect2(
					p_tile_map->get_global_position().x +
							used_rect.position.x * tile_size.x,
					p_tile_map->get_global_position().y +
							used_rect.position.y * tile_size.y,
					used_rect.size.x * tile_size.x,
					used_rect.size.y * tile_size.y);
		}
	}
	return Rect2();
}
int Sc::Geometry::get_tilemap_index_from_grid_coord(
		Vector2i p_grid_coord,
		const TileMap *p_tile_map) {
	// This depends on how tilemap_index is defined (e.g., row-major order
	// within used_rect) The GDScript implies a specific indexing scheme. For
	// Godot 4, direct indexing isn't standard. Usually, you work with Vector2i
	// coords. This is a placeholder.
	if (!p_tile_map || p_tile_map->get_layers_count() == 0)
		return -1;
	Rect2i used_rect = p_tile_map->get_used_rect(); // Combined rect
	if (!used_rect.has_point(p_grid_coord))
		return -1; // Or handle out of bounds
	// Assuming index relative to the start of the used_rect of the first layer
	return (p_grid_coord.y - used_rect.position.y) * used_rect.size.x +
			(p_grid_coord.x - used_rect.position.x);
}
bool Sc::Geometry::do_point_and_segment_intersect(
		Vector2 p_point,
		Vector2 p_seg_start,
		Vector2 p_seg_end,
		double p_epsilon) {
	// Check if point is on the line defined by segment, and within segment
	// bounds
	double dist_sq = GeometryUtils2D::get_closest_point_to_segment(
							 p_point, p_seg_start, p_seg_end)
							 .distance_squared_to(p_point);
	return dist_sq < p_epsilon * p_epsilon;
}
bool Sc::Geometry::is_polygon_convex(
		const PackedVector2Array &p_points,
		double p_epsilon) {
	return Geometry2D::is_polygon_convex(p_points);
}
bool Sc::Geometry::do_surface_and_rectangle_intersect(
		const Ref<Surface> &p_surface,
		Vector2 p_rect_min,
		Vector2 p_rect_max) {
	if (!p_surface.is_valid())
		return false;
	Rect2 rect(p_rect_min, p_rect_max - p_rect_min);
	// This is a simplified check. A real check would involve segment-rectangle
	// intersection tests. Or use Surface's bounding_box vs rect.
	if (p_surface->get_bounding_box().intersects(
				rect)) { // Assuming Surface has get_bounding_box()
		// Further checks might be needed for actual line segment intersection
		PackedVector2Array surface_vertices =
				p_surface->get_vertices(); // Assuming method exists
		if (surface_vertices.size() < 2)
			return false;
		for (int i = 0; i < surface_vertices.size() - 1; ++i) {
			if (Geometry2D::segment_intersects_segment(
						surface_vertices[i], surface_vertices[i + 1],
						p_rect_min, Vector2(p_rect_max.x, p_rect_min.y)) ||
				Geometry2D::segment_intersects_segment(
						surface_vertices[i], surface_vertices[i + 1],
						Vector2(p_rect_max.x, p_rect_min.y), p_rect_max) ||
				Geometry2D::segment_intersects_segment(
						surface_vertices[i], surface_vertices[i + 1],
						p_rect_max, Vector2(p_rect_min.x, p_rect_max.y)) ||
				Geometry2D::segment_intersects_segment(
						surface_vertices[i], surface_vertices[i + 1],
						Vector2(p_rect_min.x, p_rect_max.y), p_rect_min)) {
				return true;
			}
			// Also check if any surface vertex is inside the rect
			if (rect.has_point(surface_vertices[i]))
				return true;
		}
		if (rect.has_point(surface_vertices[surface_vertices.size() - 1]))
			return true;
		// Also check if any rect corner is inside the polygon formed by surface
		// (if surface is closed) For an open polyline, this is more complex.
	}
	return false; // Placeholder
}
Vector2i Sc::Geometry::snap_vector2_to_integers(Vector2 p_vec) {
	return Vector2i(
			static_cast<int>(Math::round(p_vec.x)),
			static_cast<int>(Math::round(p_vec.y)));
}

void Sc::Utils::concat(Array &r_base_array, const Array &p_array_to_add) {
	for (int i = 0; i < p_array_to_add.size(); ++i) {
		r_base_array.push_back(p_array_to_add[i]);
	}
}
void Sc::Profiler::start(
		const StringName &p_name) { /* UtilityFunctions::print("Profiler
									   START: ", p_name); */
}
void Sc::Profiler::stop(
		const StringName &p_name) { /* UtilityFunctions::print("Profiler
									   STOP: ", p_name); */
}

// Constants from Sc.geometry (example values, ensure these match your project)
constexpr double Sc::Geometry::FLOOR_MAX_ANGLE;
constexpr double Sc::Geometry::WALL_ANGLE_EPSILON;

// SurfaceParser Method Implementations
void SurfaceParser::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD(
					"parse", "p_surface_store", "p_tilemaps",
					"p_surface_marks"),
			&SurfaceParser::parse);
}

SurfaceParser::SurfaceParser() {}
SurfaceParser::~SurfaceParser() {}

void SurfaceParser::parse(
		SurfaceStore *p_surface_store,
		const Array &p_tilemaps,
		const Array &p_surface_marks) {
	ERR_FAIL_NULL_MSG(p_surface_store, "SurfaceStore cannot be null.");

	_validate_tilemap_collection(p_tilemaps);

	_calculate_max_tilemap_cell_size(p_surface_store, p_tilemaps);
	_calculate_combined_tilemap_rect(p_surface_store, p_tilemaps);

	for (int i = 0; i < p_tilemaps.size(); ++i) {
		TileMap *tile_map = Object::cast_to<TileMap>(p_tilemaps[i]);
		if (tile_map) {
			_parse_tilemap(p_surface_store, tile_map);
		} else {
			UtilityFunctions::printerr(
					"Item in tilemaps array is not a valid TileMap at index ",
					i);
		}
	}

	Sc::Profiler::start("populate_derivative_collections");
	_populate_derivative_collections(p_surface_store, p_tilemaps);
	Sc::Profiler::stop("populate_derivative_collections");

	if (!p_tilemaps.is_empty()) {
		TileMap *first_tile_map = Object::cast_to<TileMap>(
				p_tilemaps[0]); // Used for surface marks
		if (first_tile_map) {
			for (int i = 0; i < p_surface_marks.size(); ++i) {
				SurfaceMark *mark =
						Object::cast_to<SurfaceMark>(p_surface_marks[i]);
				if (mark) {
					_parse_surface_mark(p_surface_store, mark, first_tile_map);
				} else {
					UtilityFunctions::printerr(
							"Item in surface_marks array is not a valid "
							"SurfaceMark at index ",
							i);
				}
			}
		}
	}
	p_surface_store->set_marks(
			p_surface_marks); // Assuming SurfaceStore has set_marks(Array)
}

void SurfaceParser::_validate_tilemap_collection(
		const Array &p_tilemaps) const {
	ERR_FAIL_COND_MSG(
			p_tilemaps.is_empty(),
			"Collidable TileMap collection must not be empty.");

	TileMap *first_tile_map = Object::cast_to<TileMap>(p_tilemaps[0]);
	ERR_FAIL_NULL_MSG(
			first_tile_map, "First element in tilemaps is not a TileMap.");

	// In Godot 4, TileMap node itself doesn't have cell_size. TileSet does.
	// This logic might need to check TileSet's tile_size.
	// Vector2 cell_size = first_tile_map->get_tileset()->get_tile_size(); //
	// Example for Godot 4 For now, assuming a custom `get_cell_size()` or it's
	// a Godot 3 TileMap. If `first_tile_map` is `SurfacesTilemap`, it might
	// have this method.
	Vector2 cell_size;
	SurfacesTilemap *stm_first =
			Object::cast_to<SurfacesTilemap>(first_tile_map);
	if (stm_first &&
		stm_first->get_tileset().is_valid()) { // Assuming SurfacesTilemap has
											   // get_cell_size or similar
		cell_size = stm_first->get_tileset()->get_tile_size();
	} else {
		UtilityFunctions::printerr(
				"First TileMap is not SurfacesTilemap or has no TileSet, "
				"cannot get cell_size for validation.");
		// ERR_FAIL_MSG("Cannot determine cell_size from first TileMap for
		// validation."); Fallback or default if Sc.Levels is not fully set up
		cell_size = Sc::Levels::get_singleton()
				? Sc::Levels::get_singleton()->session.config.cell_size
				: Vector2(16, 16);
	}

	// ERR_FAIL_COND_MSG(cell_size !=
	// Sc::Levels::get_singleton()->session.config.cell_size,
	//         "TileMap.cell_size does not match level config.");

	for (int i = 0; i < p_tilemaps.size(); ++i) {
		TileMap *tile_map = Object::cast_to<TileMap>(p_tilemaps[i]);
		ERR_FAIL_NULL_MSG(tile_map, "An element in tilemaps is not a TileMap.");

		Vector2 current_tm_cell_size;
		SurfacesTilemap *stm_current =
				Object::cast_to<SurfacesTilemap>(tile_map);
		if (stm_current && stm_current->get_tileset().is_valid()) {
			current_tm_cell_size = stm_current->get_tileset()->get_tile_size();
		} else {
			// UtilityFunctions::printerr("TileMap at index ", i, " is not
			// SurfacesTilemap or has no TileSet."); Continue or fail based on
			// strictness
		}
		// FIXME: Inner tilemaps are half size...
		// if (stm_current) { // Only assert if it's a type we expect to have
		// this property
		//    ERR_FAIL_COND_MSG(current_tm_cell_size != cell_size,
		//       "All collidable Tilemaps must use the same cell size.");
		// }

		ERR_FAIL_COND_MSG(
				tile_map->get_position() != Vector2::ZERO,
				"Tilemaps must be positioned at (0,0). (Node2D position)");

		bool is_valid_type =
				(Object::cast_to<SurfacesTilemap>(tile_map) != nullptr) ||
				(Object::cast_to<CornerMatchInnerTilemap>(tile_map) != nullptr);
		ERR_FAIL_COND_MSG(
				!is_valid_type,
				"TileMap is not of type SurfacesTilemap or "
				"CornerMatchInnerTilemap.");
	}
}

void SurfaceParser::_calculate_max_tilemap_cell_size(
		SurfaceStore *p_surface_store,
		const Array &p_tilemaps) const {
	Vector2 max_tilemap_cell_size = Vector2::ZERO;
	for (int i = 0; i < p_tilemaps.size(); ++i) {
		TileMap *tile_map_node = Object::cast_to<TileMap>(p_tilemaps[i]);
		if (tile_map_node && tile_map_node->get_tileset().is_valid()) {
			Vector2 current_cell_size =
					tile_map_node->get_tileset()->get_tile_size();
			if (current_cell_size.x + current_cell_size.y >
				max_tilemap_cell_size.x + max_tilemap_cell_size.y) {
				max_tilemap_cell_size = current_cell_size;
			}
		}
	}
	p_surface_store->set_max_tilemap_cell_size(
			max_tilemap_cell_size); // Assuming method exists
}

void SurfaceParser::_calculate_combined_tilemap_rect(
		SurfaceStore *p_surface_store,
		const Array &p_tilemaps) const {
	if (p_tilemaps.is_empty())
		return;

	TileMap *first_tile_map = Object::cast_to<TileMap>(p_tilemaps[0]);
	if (!first_tile_map)
		return;

	Rect2 combined_tilemap_rect =
			Sc::Geometry::get_tilemap_bounds_in_world_coordinates(
					first_tile_map);
	for (int i = 1; i < p_tilemaps.size(); ++i) {
		TileMap *tile_map = Object::cast_to<TileMap>(p_tilemaps[i]);
		if (tile_map) {
			combined_tilemap_rect = combined_tilemap_rect.merge(
					Sc::Geometry::get_tilemap_bounds_in_world_coordinates(
							tile_map));
		}
	}
	p_surface_store->set_combined_tilemap_rect(
			combined_tilemap_rect); // Assuming method exists
}

void SurfaceParser::_parse_tilemap(
		SurfaceStore *p_surface_store,
		TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);

	Sc::Profiler::start("validate_tileset");
	_validate_tileset(p_tile_map);
	Sc::Profiler::stop("validate_tileset");

	Sc::Profiler::start("parse_tileset");
	Dictionary tile_id_to_coord_to_shape_data = _parse_tileset(p_tile_map);
	Sc::Profiler::stop("parse_tileset");

	Sc::Profiler::start("parse_tilemap_cells_into_surfaces");
	Dictionary tilemap_index_to_floor;
	Dictionary tilemap_index_to_left_wall;
	Dictionary tilemap_index_to_right_wall;
	Dictionary tilemap_index_to_ceiling;
	_parse_tilemap_cells_into_surfaces(
			tilemap_index_to_floor, tilemap_index_to_left_wall,
			tilemap_index_to_right_wall, tilemap_index_to_ceiling,
			tile_id_to_coord_to_shape_data, p_tile_map);
	Sc::Profiler::stop("parse_tilemap_cells_into_surfaces");

	Sc::Profiler::start("remove_internal_surfaces");
	_remove_internal_surfaces(
			tilemap_index_to_floor, tilemap_index_to_left_wall,
			tilemap_index_to_right_wall, tilemap_index_to_ceiling,
			tile_id_to_coord_to_shape_data, p_tile_map);
	Sc::Profiler::stop("remove_internal_surfaces");

	Sc::Profiler::start("merge_continuous_surfaces");
	_merge_continuous_surfaces(
			tilemap_index_to_floor, tilemap_index_to_left_wall,
			tilemap_index_to_right_wall, tilemap_index_to_ceiling, p_tile_map);
	Sc::Profiler::stop("merge_continuous_surfaces");

	Sc::Profiler::start("get_surface_list_from_map");
	Array floors = _get_surface_list_from_map(tilemap_index_to_floor);
	Array ceilings = _get_surface_list_from_map(tilemap_index_to_ceiling);
	Array left_walls = _get_surface_list_from_map(tilemap_index_to_left_wall);
	Array right_walls = _get_surface_list_from_map(tilemap_index_to_right_wall);
	Sc::Profiler::stop("get_surface_list_from_map");

	Sc::Profiler::start("remove_internal_collinear_vertices_duration");
	_remove_internal_collinear_vertices(floors);
	_remove_internal_collinear_vertices(ceilings);
	_remove_internal_collinear_vertices(left_walls);
	_remove_internal_collinear_vertices(right_walls);
	Sc::Profiler::stop("remove_internal_collinear_vertices_duration");

	Sc::Profiler::start("store_surfaces_duration");
	_store_surfaces(
			p_surface_store, p_tile_map, floors, ceilings, left_walls,
			right_walls);
	Sc::Profiler::stop("store_surfaces_duration");

	Sc::Profiler::start("assign_neighbor_surfaces_duration");
	_assign_neighbor_surfaces(
			p_surface_store->get_floors(), // Assuming getters
			p_surface_store->get_ceilings(), p_surface_store->get_left_walls(),
			p_surface_store->get_right_walls());
	Sc::Profiler::stop("assign_neighbor_surfaces_duration");

	Sc::Profiler::start("_assert_surfaces_have_neighbors");
	_assert_surfaces_have_neighbors(p_surface_store->get_floors());
	_assert_surfaces_have_neighbors(p_surface_store->get_ceilings());
	_assert_surfaces_have_neighbors(p_surface_store->get_left_walls());
	_assert_surfaces_have_neighbors(p_surface_store->get_right_walls());
	Sc::Profiler::stop("_assert_surfaces_have_neighbors");

	Sc::Profiler::start("calculate_shape_bounding_boxes_for_surfaces_duration");
	_calculate_shape_bounding_boxes_for_surfaces(p_surface_store->get_floors());
	Sc::Profiler::stop("calculate_shape_bounding_boxes_for_surfaces_duration");
}

void SurfaceParser::_store_surfaces(
		SurfaceStore *p_surface_store,
		TileMap *p_tile_map,
		const Array &p_floors,
		const Array &p_ceilings,
		const Array &p_left_walls,
		const Array &p_right_walls) {
	_populate_surface_objects(p_floors, Surface::Side::FLOOR);
	_populate_surface_objects(p_ceilings, Surface::Side::CEILING);
	_populate_surface_objects(p_left_walls, Surface::Side::LEFT_WALL);
	_populate_surface_objects(p_right_walls, Surface::Side::RIGHT_WALL);

	// Assuming SurfaceStore has methods like add_floor, add_ceiling, etc.
	// or direct access to Array fields if they are public (not typical for
	// C++). For now, using placeholder `get_..._mut()` for mutable access to
	// internal arrays.
	_copy_surfaces_to_main_collection(
			p_floors, p_surface_store->get_floors_mut());
	_copy_surfaces_to_main_collection(
			p_ceilings, p_surface_store->get_ceilings_mut());
	_copy_surfaces_to_main_collection(
			p_left_walls, p_surface_store->get_left_walls_mut());
	_copy_surfaces_to_main_collection(
			p_right_walls, p_surface_store->get_right_walls_mut());

	_free_objects(p_floors);
	_free_objects(p_ceilings);
	_free_objects(p_left_walls);
	_free_objects(p_right_walls);
}

void SurfaceParser::_populate_derivative_collections(
		SurfaceStore *p_surface_store,
		const Array &p_tilemaps) {
	// Assuming SurfaceStore has clear methods and getters/setters or direct
	// access for these arrays
	p_surface_store->get_all_surfaces_mut().clear();
	p_surface_store->get_non_ceiling_surfaces_mut().clear();
	p_surface_store->get_non_floor_surfaces_mut().clear();
	p_surface_store->get_non_wall_surfaces_mut().clear();
	p_surface_store->get_all_walls_mut().clear();

	Sc::Utils::concat(
			p_surface_store->get_all_surfaces_mut(),
			p_surface_store->get_floors());
	Sc::Utils::concat(
			p_surface_store->get_all_surfaces_mut(),
			p_surface_store->get_right_walls());
	Sc::Utils::concat(
			p_surface_store->get_all_surfaces_mut(),
			p_surface_store->get_left_walls());
	Sc::Utils::concat(
			p_surface_store->get_all_surfaces_mut(),
			p_surface_store->get_ceilings());

	Sc::Utils::concat(
			p_surface_store->get_non_ceiling_surfaces_mut(),
			p_surface_store->get_floors());
	Sc::Utils::concat(
			p_surface_store->get_non_ceiling_surfaces_mut(),
			p_surface_store->get_right_walls());
	Sc::Utils::concat(
			p_surface_store->get_non_ceiling_surfaces_mut(),
			p_surface_store->get_left_walls());

	Sc::Utils::concat(
			p_surface_store->get_non_floor_surfaces_mut(),
			p_surface_store->get_right_walls());
	Sc::Utils::concat(
			p_surface_store->get_non_floor_surfaces_mut(),
			p_surface_store->get_left_walls());
	Sc::Utils::concat(
			p_surface_store->get_non_floor_surfaces_mut(),
			p_surface_store->get_ceilings());

	Sc::Utils::concat(
			p_surface_store->get_non_wall_surfaces_mut(),
			p_surface_store->get_floors());
	Sc::Utils::concat(
			p_surface_store->get_non_wall_surfaces_mut(),
			p_surface_store->get_ceilings());

	Sc::Utils::concat(
			p_surface_store->get_all_walls_mut(),
			p_surface_store->get_right_walls());
	Sc::Utils::concat(
			p_surface_store->get_all_walls_mut(),
			p_surface_store->get_left_walls());

	for (int i = 0; i < p_tilemaps.size(); ++i) {
		TileMap *tile_map = Object::cast_to<TileMap>(p_tilemaps[i]);
		if (!tile_map)
			continue;

		Dictionary floor_mapping = _create_tilemap_mapping_from_surfaces(
				p_surface_store->get_floors(), tile_map);
		Dictionary ceiling_mapping = _create_tilemap_mapping_from_surfaces(
				p_surface_store->get_ceilings(), tile_map);
		Dictionary left_wall_mapping = _create_tilemap_mapping_from_surfaces(
				p_surface_store->get_left_walls(), tile_map);
		Dictionary right_wall_mapping = _create_tilemap_mapping_from_surfaces(
				p_surface_store->get_right_walls(), tile_map);

		Dictionary side_to_mapping;
		side_to_mapping[Surface::Side::FLOOR] = floor_mapping;
		side_to_mapping[Surface::Side::CEILING] = ceiling_mapping;
		side_to_mapping[Surface::Side::LEFT_WALL] = left_wall_mapping;
		side_to_mapping[Surface::Side::RIGHT_WALL] = right_wall_mapping;

		p_surface_store->get_tilemap_index_to_surface_maps_mut()[tile_map] =
				side_to_mapping; // Assuming method/access exists
	}
}

void SurfaceParser::_validate_tileset(TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);
	Ref<TileSet> ts_base = p_tile_map->get_tileset();
	ERR_FAIL_COND_MSG(ts_base.is_null(), "TileMap has no TileSet.");

	SurfacesTileset *surfaces_tileset =
			Object::cast_to<SurfacesTileset>(*ts_base);
	ERR_FAIL_COND_MSG(
			!surfaces_tileset, "Tileset must extend SurfacesTileset.");

	Vector2 cell_size =
			surfaces_tileset
					->get_tile_size(); // Use TileSet's tile_size for Godot 4

	Array ids = surfaces_tileset->get_collidable_tiles_ids(); // Custom method
	ERR_FAIL_COND_MSG(
			ids.is_empty(), "No collidable tile IDs found in SurfacesTileset.");

	for (int i = 0; i < ids.size(); ++i) {
		int tile_source_id = ids[i]; // In Godot 4, this is likely a source_id
		// For each source_id, you'd iterate its tiles.
		// The GDScript `tile_id` might map to `atlas_coords` or
		// `alternative_id` within a source. This part needs careful mapping
		// from Godot 3 TileSet API to Godot 4. Assuming
		// `get_collidable_tiles_ids` returns something that can be used with
		// `tile_get_name` etc. If `tile_id` refers to a Godot 3 style global
		// tile ID:

		// String tile_name = surfaces_tileset->tile_get_name(tile_source_id);
		// // This is for Godot 3 style In Godot 4, TileSetAtlasSource has
		// get_tile_data(atlas_coords, alternative_id) This loop structure is
		// highly dependent on SurfacesTileset's API. For now, let's assume
		// `tile_source_id` is a "tile_id" in the old sense for simplicity of
		// porting the loop.

		// Ref<SurfaceProperties> props =
		// surfaces_tileset->get_tile_properties(tile_name); // Custom method
		// ERR_FAIL_COND_MSG(!props.is_valid(),
		//         ("Tile ID is not recognized by
		//         SurfacesTileset.get_tile_properties: " +
		//         tile_name).utf8().get_data());

		// Godot 4: TileMap uses layers. TileSet has sources.
		// TileSet::tile_get_tile_mode is Godot 3.
		// TileSet::autotile_get_size is Godot 3.
		// This section is very hard to port directly without knowing
		// SurfacesTileset's API. I'll try to map the logic for shapes if we can
		// get them.

		// In Godot 4, to get shapes for a tile in an atlas source:
		// TileSetAtlasSource* atlas_source =
		// Object::cast_to<TileSetAtlasSource>(surfaces_tileset->get_source(source_id_from_tile_id));
		// Vector2i atlas_coords = ... // from tile_id
		// int alternative_id = ... // from tile_id
		// TileData* tile_data = atlas_source->get_tile_data(atlas_coords,
		// alternative_id); int physics_layers_count =
		// tile_data->get_collision_polygons_count(0); // for physics_layer 0
		// for (int k=0; k < physics_layers_count; ++k) {
		//    int polygons_count = tile_data->get_collision_polygons_count(k);
		//    for (int l=0; l < polygons_count; ++l) {
		//        PackedVector2Array points =
		//        tile_data->get_collision_polygon_points(k, l);
		//        // ... validate points ...
		//    }
		// }
		// The GDScript `tile_get_shapes` returns an Array of Dictionaries.
		// This implies a custom structure or Godot 3 API.

		Array shapes_data_array = surfaces_tileset->tile_get_shapes(
				tile_source_id); // Assuming this custom method exists and
								 // mirrors Godot 3
		for (int j = 0; j < shapes_data_array.size(); ++j) {
			Dictionary shape_data_dict = shapes_data_array[j];
			Ref<Shape2D> shape = shape_data_dict["shape"];
			// Transform2D shape_transform = shape_data_dict["shape_transform"];
			// // Not used in validation block

			ERR_FAIL_COND_MSG(shape.is_null(), "Shape in TileSet is null.");
			Ref<ConvexPolygonShape2D> convex_shape = shape; // Try direct cast
			ERR_FAIL_COND_MSG(
					!convex_shape.is_valid(),
					"TileSet collision shapes must be ConvexPolygonShape2D.");

			PackedVector2Array points = convex_shape->get_points();

			for (int k = 0; k < points.size() - 1; ++k) {
				ERR_FAIL_COND_MSG(
						points[k].is_equal_approx(points[k + 1]),
						"TileSet collision shapes must not have duplicated "
						"vertices.");
			}
			if (!points.is_empty()) {
				ERR_FAIL_COND_MSG(
						points[0].is_equal_approx(points[points.size() - 1]),
						"TileSet collision shapes must not have duplicated "
						"start/end vertices for open polygons (implicitly "
						"closed by ConvexPolygonShape2D).");
			}

			if (points.size() >= 3) {
				Vector2 previous_point = points[points.size() - 2];
				Vector2 current_point = points[points.size() - 1];
				for (int k = 0; k < points.size(); ++k) {
					Vector2 next_point = points[k];
					ERR_FAIL_COND_MSG(
							Sc::Geometry::are_points_collinear(
									previous_point, current_point, next_point,
									0.001),
							"TileSet collision-shape vertices must not be "
							"collinear.");
					previous_point = current_point;
					current_point = next_point;
				}
			}

			for (int k = 0; k < points.size(); ++k) {
				ERR_FAIL_COND_MSG(
						!(Math::is_equal_approx(
								  points[k].x,
								  static_cast<double>(
										  static_cast<int>(points[k].x))) &&
						  Math::is_equal_approx(
								  points[k].y,
								  static_cast<double>(
										  static_cast<int>(points[k].y)))),
						"TileSet collision-shape vertices must align with "
						"whole-pixel coordinates.");
			}

			if (!Su::are_oddly_shaped_surfaces_used) {
				for (int k = 0; k < points.size(); ++k) {
					Vector2 point = points[k];
					bool is_corner_point =
							Sc::Geometry::are_points_equal_with_epsilon(
									point, Vector2(0.0, 0.0)) ||
							Sc::Geometry::are_points_equal_with_epsilon(
									point, Vector2(0.0, cell_size.y)) ||
							Sc::Geometry::are_points_equal_with_epsilon(
									point, Vector2(cell_size.x, 0.0)) ||
							Sc::Geometry::are_points_equal_with_epsilon(
									point, cell_size);
					ERR_FAIL_COND_MSG(
							!is_corner_point,
							"Oddly-shaped tiles aren't enabled. Points must be "
							"cell corners.");
				}
			}

			ERR_FAIL_COND_MSG(
					!Sc::Geometry::is_polygon_convex(points, 0.01),
					"TileSet collision shapes must be convex.");

			for (int k = 0; k < points.size(); ++k) {
				Vector2 point = points[k];
				ERR_FAIL_COND_MSG(
						!(point.x >= 0.0 && point.y >= 0.0 &&
						  point.x <= cell_size.x && point.y <= cell_size.y),
						"TileSet collision-shape vertices must not exceed the "
						"cell-size.");
			}
		}
	}
}

Dictionary SurfaceParser::_parse_tileset(TileMap *p_tile_map) {
	Dictionary tile_id_to_coord_to_shape_data;
	ERR_FAIL_NULL_V(p_tile_map, tile_id_to_coord_to_shape_data);
	Ref<TileSet> ts_base = p_tile_map->get_tileset();
	ERR_FAIL_COND_V(ts_base.is_null(), tile_id_to_coord_to_shape_data);

	SurfacesTileset *surfaces_tileset =
			Object::cast_to<SurfacesTileset>(*ts_base);
	ERR_FAIL_COND_V(!surfaces_tileset, tile_id_to_coord_to_shape_data);

	Vector2 cell_size = surfaces_tileset->get_tile_size();
	Array ids = surfaces_tileset->get_collidable_tiles_ids(); // Custom method

	for (int i = 0; i < ids.size(); ++i) {
		int tile_id = ids[i]; // Assuming this is a Godot 3 style tile_id or a
							  // compatible key
		Dictionary tile_coord_to_shape =
				_parse_tile(tile_id, surfaces_tileset, cell_size);
		tile_id_to_coord_to_shape_data[tile_id] = tile_coord_to_shape;
	}
	return tile_id_to_coord_to_shape_data;
}

Dictionary SurfaceParser::_parse_tile(
		int p_tile_id, // Godot 3 style tile_id or equivalent key
		SurfacesTileset
				*p_surfaces_tileset, // Changed from TileSet to SurfacesTileset
		Vector2 p_cell_size) {
	Dictionary tile_coord_to_shape;
	ERR_FAIL_NULL_V(p_surfaces_tileset, tile_coord_to_shape);

	// This relies on a Godot 3 style tile_get_shapes or a custom equivalent on
	// SurfacesTileset
	Array shapes_data_array = p_surfaces_tileset->tile_get_shapes(p_tile_id);
	for (int i = 0; i < shapes_data_array.size(); ++i) {
		Dictionary shape_data_dict = shapes_data_array[i];
		Ref<Shape2D> shape = shape_data_dict["shape"];
		Transform2D shape_transform = shape_data_dict["shape_transform"];
		bool one_way = shape_data_dict.has("one_way")
				? (bool)shape_data_dict["one_way"]
				: false;

		// 'autotile_coord' is specific to Godot 3 autotiles.
		// In Godot 4, this would be atlas_coords (Vector2i).
		// Assuming shape_data_dict["autotile_coord"] returns a Variant
		// convertible to Vector2i.
		Vector2i autotile_coord = shape_data_dict["autotile_coord"];

		Ref<TileShapeData> parsed_shape_data = _parse_tile_shape(
				*shape, shape_transform, one_way, p_cell_size);
		tile_coord_to_shape[autotile_coord] = parsed_shape_data;
	}
	return tile_coord_to_shape;
}

Ref<TileShapeData> SurfaceParser::_parse_tile_shape(
		Shape2D *p_shape,
		Transform2D p_shape_transform,
		bool p_is_one_way, // p_is_one_way is not used in the GDScript body of
						   // this function
		Vector2 p_cell_size) {
	Ref<TileShapeData> tile_shape_data = memnew(TileShapeData);
	ERR_FAIL_NULL_V(p_shape, tile_shape_data);
	Ref<ConvexPolygonShape2D> convex_shape =
			Object::cast_to<ConvexPolygonShape2D>(p_shape);
	ERR_FAIL_NULL_V(
			convex_shape.ptr(),
			tile_shape_data); // Check pointer for Ref<ConvexPolygonShape2D>

	PackedVector2Array shape_points = convex_shape->get_points();
	int vertex_count = shape_points.size();
	Array vertices_world_array; // Array of Vector2
	vertices_world_array.resize(vertex_count);
	for (int i = 0; i < vertex_count; ++i) {
		vertices_world_array[i] = p_shape_transform.xform(shape_points[i]);
	}

	bool is_clockwise =
			Sc::Geometry::is_polygon_clockwise(vertices_world_array);

	double left_most_vertex_x = static_cast<Vector2>(vertices_world_array[0]).x;
	double right_most_vertex_x =
			static_cast<Vector2>(vertices_world_array[0]).x;
	double bottom_most_vertex_y =
			static_cast<Vector2>(vertices_world_array[0]).y;
	double top_most_vertex_y = static_cast<Vector2>(vertices_world_array[0]).y;
	int left_most_vertex_index = 0;
	int right_most_vertex_index = 0;
	int bottom_most_vertex_index = 0;
	int top_most_vertex_index = 0;

	for (int i = 1; i < vertex_count; ++i) {
		Vector2 vertex = vertices_world_array[i];
		if (vertex.x < left_most_vertex_x) {
			left_most_vertex_x = vertex.x;
			left_most_vertex_index = i;
		}
		if (vertex.x > right_most_vertex_x) {
			right_most_vertex_x = vertex.x;
			right_most_vertex_index = i;
		}
		if (vertex.y > bottom_most_vertex_y) {
			bottom_most_vertex_y = vertex.y;
			bottom_most_vertex_index = i;
		}
		if (vertex.y < top_most_vertex_y) {
			top_most_vertex_y = vertex.y;
			top_most_vertex_index = i;
		}
	}

	int step = is_clockwise
			? 1
			: vertex_count - 1; // step can be negative if vertex_count-1,
								// ensure modulo works
	if (!is_clockwise && vertex_count > 0)
		step = -1; // Simpler step for reverse iteration with positive modulo
	else if (is_clockwise)
		step = 1;

	int i1, i2;
	Vector2 v1, v2;
	double pos_angle;
	bool is_wall_segment;

	int top_side_start_index;
	int top_side_end_index;
	int left_side_start_index; // Used for bottom_side_vertices end
	int right_side_end_index; // Used for bottom_side_vertices start &
							  // right_side_vertices end

	const double FLOOR_MAX_ANGLE_BELOW_90 =
			Sc::Geometry::FLOOR_MAX_ANGLE + Sc::Geometry::WALL_ANGLE_EPSILON;
	const double FLOOR_MIN_ANGLE_ABOVE_90 = Math_PI -
			Sc::Geometry::FLOOR_MAX_ANGLE - Sc::Geometry::WALL_ANGLE_EPSILON;

	// Find the start of the top-side.
	i1 = left_most_vertex_index;
	auto get_next_idx = [&](int current_idx) {
		int next = current_idx + step;
		if (vertex_count == 0)
			return 0;
		while (next < 0)
			next += vertex_count;
		return next % vertex_count;
	};

	i2 = get_next_idx(i1);
	v1 = vertices_world_array[i1];
	v2 = vertices_world_array[i2];
	pos_angle = Math::abs(v1.angle_to_point(v2));
	is_wall_segment = pos_angle > FLOOR_MAX_ANGLE_BELOW_90 &&
			pos_angle < FLOOR_MIN_ANGLE_ABOVE_90;

	while (is_wall_segment && i1 != top_most_vertex_index) {
		i1 = i2;
		i2 = get_next_idx(i1);
		v1 = vertices_world_array[i1];
		v2 = vertices_world_array[i2];
		pos_angle = Math::abs(v1.angle_to_point(v2));
		is_wall_segment = pos_angle > FLOOR_MAX_ANGLE_BELOW_90 &&
				pos_angle < FLOOR_MIN_ANGLE_ABOVE_90;
	}
	top_side_start_index = i1;

	// Find the end of the top-side.
	while (!is_wall_segment && i1 != right_most_vertex_index) {
		i1 = i2;
		i2 = get_next_idx(i1);
		v1 = vertices_world_array[i1];
		v2 = vertices_world_array[i2];
		pos_angle = Math::abs(v1.angle_to_point(v2));
		is_wall_segment = pos_angle > FLOOR_MAX_ANGLE_BELOW_90 &&
				pos_angle < FLOOR_MIN_ANGLE_ABOVE_90;
	}
	top_side_end_index = i1;

	// Find the end of the right-side.
	while (is_wall_segment && i1 != bottom_most_vertex_index) {
		i1 = i2;
		i2 = get_next_idx(i1);
		v1 = vertices_world_array[i1];
		v2 = vertices_world_array[i2];
		pos_angle = Math::abs(v1.angle_to_point(v2));
		is_wall_segment = pos_angle > FLOOR_MAX_ANGLE_BELOW_90 &&
				pos_angle < FLOOR_MIN_ANGLE_ABOVE_90;
	}
	right_side_end_index = i1;

	// Find the start of the left-side. (This is the end of the bottom side)
	while (!is_wall_segment && i1 != left_most_vertex_index) {
		i1 = i2;
		i2 = get_next_idx(i1);
		v1 = vertices_world_array[i1];
		v2 = vertices_world_array[i2];
		pos_angle = Math::abs(v1.angle_to_point(v2));
		is_wall_segment = pos_angle > FLOOR_MAX_ANGLE_BELOW_90 &&
				pos_angle < FLOOR_MIN_ANGLE_ABOVE_90;
	}
	left_side_start_index = i1;

	Array top_side_vertices, bottom_side_vertices, left_side_vertices,
			right_side_vertices;
	int current_idx;

	current_idx = top_side_start_index;
	while (true) {
		top_side_vertices.push_back(vertices_world_array[current_idx]);
		if (current_idx == top_side_end_index)
			break;
		current_idx = get_next_idx(current_idx);
	}

	current_idx = right_side_end_index; // Start of bottom side
	while (true) {
		bottom_side_vertices.push_back(vertices_world_array[current_idx]);
		if (current_idx == left_side_start_index)
			break; // End of bottom side
		current_idx = get_next_idx(current_idx);
	}

	current_idx = left_side_start_index; // Start of left side
	while (true) {
		left_side_vertices.push_back(vertices_world_array[current_idx]);
		if (current_idx == top_side_start_index)
			break; // End of left side (connects to top_side_start)
		current_idx = get_next_idx(current_idx);
	}

	current_idx = top_side_end_index; // Start of right side
	while (true) {
		right_side_vertices.push_back(vertices_world_array[current_idx]);
		if (current_idx == right_side_end_index)
			break; // End of right side
		current_idx = get_next_idx(current_idx);
	}

	tile_shape_data->set_top_vertices(top_side_vertices);
	tile_shape_data->set_right_vertices(right_side_vertices);
	tile_shape_data->set_bottom_vertices(bottom_side_vertices);
	tile_shape_data->set_left_vertices(left_side_vertices);

	tile_shape_data->set_is_top_axially_aligned(
			_get_is_side_axially_aligned(top_side_vertices, true));
	tile_shape_data->set_is_right_axially_aligned(_get_is_side_axially_aligned(
			right_side_vertices, false)); // Right wall is vertical
	tile_shape_data->set_is_bottom_axially_aligned(
			_get_is_side_axially_aligned(bottom_side_vertices, true));
	tile_shape_data->set_is_left_axially_aligned(_get_is_side_axially_aligned(
			left_side_vertices, false)); // Left wall is vertical

	tile_shape_data->set_is_top_along_cell_boundary(
			_get_is_side_along_cell_boundary(
					top_side_vertices, true, p_cell_size));
	tile_shape_data->set_is_right_along_cell_boundary(
			_get_is_side_along_cell_boundary(
					right_side_vertices, false, p_cell_size));
	tile_shape_data->set_is_bottom_along_cell_boundary(
			_get_is_side_along_cell_boundary(
					bottom_side_vertices, true, p_cell_size));
	tile_shape_data->set_is_left_along_cell_boundary(
			_get_is_side_along_cell_boundary(
					left_side_vertices, false, p_cell_size));

	return tile_shape_data;
}

bool SurfaceParser::_get_is_side_axially_aligned(
		const Array &p_vertices, // Array of Vector2
		bool p_is_horizontal) {
	if (p_vertices.size() == 1) {
		return true;
	} else if (p_vertices.size() == 2) {
		Vector2 v0 = p_vertices[0];
		Vector2 v1 = p_vertices[1];
		if (p_is_horizontal) { // Floor/Ceiling like
			return Sc::Geometry::are_floats_equal_with_epsilon(v0.y, v1.y);
		} else { // Wall like
			return Sc::Geometry::are_floats_equal_with_epsilon(v0.x, v1.x);
		}
	}
	// For more than 2 vertices, all must share the same relevant coordinate
	if (p_vertices.size() > 2) {
		Vector2 v_first = p_vertices[0];
		for (int i = 1; i < p_vertices.size(); ++i) {
			Vector2 v_current = p_vertices[i];
			if (p_is_horizontal) {
				if (!Sc::Geometry::are_floats_equal_with_epsilon(
							v_first.y, v_current.y))
					return false;
			} else {
				if (!Sc::Geometry::are_floats_equal_with_epsilon(
							v_first.x, v_current.x))
					return false;
			}
		}
		return true;
	}
	return false;
}

bool SurfaceParser::_get_is_side_along_cell_boundary(
		const Array &p_vertices, // Array of Vector2
		bool p_is_horizontal,
		Vector2 p_cell_size) {
	if (!_get_is_side_axially_aligned(p_vertices, p_is_horizontal) ||
		p_vertices.is_empty()) {
		return false;
	}
	Vector2 vertex = p_vertices[0]; // Check first point of the aligned side
	if (p_is_horizontal) { // Top or Bottom boundary
		return Sc::Geometry::are_floats_equal_with_epsilon(vertex.y, 0.0) ||
				Sc::Geometry::are_floats_equal_with_epsilon(
						vertex.y, p_cell_size.y);
	} else { // Left or Right boundary
		return Sc::Geometry::are_floats_equal_with_epsilon(vertex.x, 0.0) ||
				Sc::Geometry::are_floats_equal_with_epsilon(
						vertex.x, p_cell_size.x);
	}
}

void SurfaceParser::_parse_tilemap_cells_into_surfaces(
		Dictionary &r_tilemap_index_to_floor,
		Dictionary &r_tilemap_index_to_left_wall,
		Dictionary &r_tilemap_index_to_right_wall,
		Dictionary &r_tilemap_index_to_ceiling,
		const Dictionary &p_tile_id_to_coord_to_shape_data,
		TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);
	Ref<TileSet> ts_base = p_tile_map->get_tileset();
	ERR_FAIL_COND(ts_base.is_null());
	SurfacesTileset *surfaces_tileset =
			Object::cast_to<SurfacesTileset>(*ts_base);
	ERR_FAIL_NULL(surfaces_tileset);
	Vector2 cell_size = surfaces_tileset->get_tile_size();

	// Godot 4: get_used_cells takes a layer index.
	// Assuming SURFACES_TILE_MAPS_COLLISION_LAYER is the target.
	TypedArray<Vector2i> used_cells =
			p_tile_map->get_used_cells(SURFACES_TILE_MAPS_COLLISION_LAYER);

	for (int i = 0; i < used_cells.size(); ++i) {
		Vector2i tilemap_pos_grid = used_cells[i];
		Vector2 cell_pos_world_coords =
				tilemap_pos_grid.operator Vector2() * cell_size +
				p_tile_map->get_global_position();
		int tilemap_index = Sc::Geometry::get_tilemap_index_from_grid_coord(
				tilemap_pos_grid, p_tile_map);

		// Godot 4: get cell data
		int source_id = p_tile_map->get_cell_source_id(
				SURFACES_TILE_MAPS_COLLISION_LAYER, tilemap_pos_grid);
		if (source_id == -1)
			continue; // No tile here or invalid source
		Vector2i atlas_coords = p_tile_map->get_cell_atlas_coords(
				SURFACES_TILE_MAPS_COLLISION_LAYER, tilemap_pos_grid);
		int alternative_tile = p_tile_map->get_cell_alternative_tile(
				SURFACES_TILE_MAPS_COLLISION_LAYER, tilemap_pos_grid);

		// The GDScript uses a global `tile_id` and `tile_coord`
		// (autotile_coord). This needs to map to source_id, atlas_coords,
		// alternative_tile in Godot 4. For simplicity, I'll construct a key or
		// use a placeholder for `tile_id_key` and `tile_coord_key`. This is a
		// major point of divergence from Godot 3. Let's assume
		// `p_tile_id_to_coord_to_shape_data` is structured to handle this.
		// E.g., key could be source_id, and inner dict key could be
		// atlas_coords.
		Variant tile_id_key = source_id; // Or a combined key if needed
		Variant tile_coord_key =
				atlas_coords; // Or alternative_tile or combined

		if (!surfaces_tileset->get_is_tile_collidable(
					source_id, atlas_coords,
					alternative_tile)) { // Custom method
			continue;
		}

		String tile_name = surfaces_tileset->tile_get_name_from_data(
				source_id, atlas_coords, alternative_tile); // Custom method

		if (!p_tile_id_to_coord_to_shape_data.has(tile_id_key) ||
			!((Dictionary)p_tile_id_to_coord_to_shape_data[tile_id_key])
					 .has(tile_coord_key)) {
			continue;
		}
		Ref<TileShapeData> tile_shape_data =
				((Dictionary)p_tile_id_to_coord_to_shape_data[tile_id_key])
						[tile_coord_key];
		Ref<SurfaceProperties> surface_properties =
				surfaces_tileset->get_tile_properties(
						tile_name); // Custom method
		ERR_FAIL_COND(tile_shape_data.is_null());
		ERR_FAIL_COND(surface_properties.is_null());

		auto create_tmp_surface =
				[&](const Array &shape_vertices_local) -> Ref<_TmpSurface> {
			Ref<_TmpSurface> tmp_surface = memnew(_TmpSurface);
			Array world_vertices;
			world_vertices.resize(shape_vertices_local.size());
			for (int v_idx = 0; v_idx < shape_vertices_local.size(); ++v_idx) {
				world_vertices[v_idx] = Vector2(shape_vertices_local[v_idx]) +
						cell_pos_world_coords;
			}
			tmp_surface->vertices_array = world_vertices;
			tmp_surface->tile_map = p_tile_map;
			tmp_surface->tilemap_indices.push_back(tilemap_index);
			tmp_surface->properties = surface_properties;
			return tmp_surface;
		};

		if (!tile_shape_data->get_top_vertices().is_empty())
			r_tilemap_index_to_floor[tilemap_index] =
					create_tmp_surface(tile_shape_data->get_top_vertices());
		if (!tile_shape_data->get_bottom_vertices().is_empty())
			r_tilemap_index_to_ceiling[tilemap_index] =
					create_tmp_surface(tile_shape_data->get_bottom_vertices());
		if (!tile_shape_data->get_right_vertices()
					 .is_empty()) // GDScript used right_vertices for left_wall
			r_tilemap_index_to_left_wall[tilemap_index] =
					create_tmp_surface(tile_shape_data->get_right_vertices());
		if (!tile_shape_data->get_left_vertices()
					 .is_empty()) // GDScript used left_vertices for right_wall
			r_tilemap_index_to_right_wall[tilemap_index] =
					create_tmp_surface(tile_shape_data->get_left_vertices());
	}
}

void SurfaceParser::_remove_internal_surfaces(
		Dictionary &r_tilemap_index_to_floor,
		Dictionary &r_tilemap_index_to_left_wall,
		Dictionary &r_tilemap_index_to_right_wall,
		Dictionary &r_tilemap_index_to_ceiling,
		const Dictionary &p_tile_id_to_coord_to_shape_data,
		TileMap *p_tile_map) {
	_remove_internal_single_vertex_surfaces(
			r_tilemap_index_to_floor, r_tilemap_index_to_left_wall,
			r_tilemap_index_to_right_wall, r_tilemap_index_to_ceiling,
			p_tile_id_to_coord_to_shape_data, p_tile_map);
	_remove_internal_multi_vertex_surfaces(
			r_tilemap_index_to_floor, r_tilemap_index_to_left_wall,
			r_tilemap_index_to_right_wall, r_tilemap_index_to_ceiling,
			p_tile_id_to_coord_to_shape_data, p_tile_map);
}

// The logic for _remove_internal_single_vertex_surfaces and
// _remove_internal_multi_vertex_surfaces is extensive and highly dependent on
// the indexing scheme and neighbor lookups. A full, robust port requires
// careful handling of these details. The following are simplified stubs or
// partial implementations.

// ...existing code...

void SurfaceParser::_merge_continuous_surfaces(
		Dictionary &r_tilemap_index_to_floor,
		Dictionary &r_tilemap_index_to_left_wall,
		Dictionary &r_tilemap_index_to_right_wall,
		Dictionary &r_tilemap_index_to_ceiling,
		TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);
	// In Godot 4, get_used_rect() is for all layers. If parsing is
	// layer-specific, this might need to be TileMap::get_used_cells(layer_idx)
	// and then derive bounds, or get_used_rect() from a specific TileMapLayer.
	// For this port, we follow the GDScript's direct use of get_used_rect().
	Rect2i used_rect = p_tile_map->get_used_rect();
	int tilemap_row_count = used_rect.size.y;
	int tilemap_column_count = used_rect.size.x;

	// Iterate through each cell in the tilemap based on its used_rect
	// dimensions
	for (int r = 0; r < tilemap_row_count; ++r) {
		for (int c = 0; c < tilemap_column_count; ++c) {
			// Calculate linear tilemap_index, assuming 0-based from
			// used_rect.position This must match how indices were stored in the
			// dictionaries.
			int tilemap_index = r * tilemap_column_count + c;

			// Calculate neighbor indices
			int right_neighbor_index = tilemap_index + 1;
			// Ensure right_neighbor_index is valid for the current row if
			// tilemap_column_count is > 0
			bool is_valid_right_neighbor = (c < tilemap_column_count - 1);

			int bottom_neighbor_index = tilemap_index + tilemap_column_count;
			// Ensure bottom_neighbor_index is valid if tilemap_row_count is > 0
			bool is_valid_bottom_neighbor = (r < tilemap_row_count - 1);

			int bottom_left_neighbor_index = bottom_neighbor_index - 1;
			bool is_valid_bottom_left_neighbor =
					is_valid_bottom_neighbor && (c > 0);

			int bottom_right_neighbor_index = bottom_neighbor_index + 1;
			bool is_valid_bottom_right_neighbor =
					is_valid_bottom_neighbor && (c < tilemap_column_count - 1);

			// --- Merge Floors ---
			if (r_tilemap_index_to_floor.has(tilemap_index)) {
				Ref<_TmpSurface> current_floor =
						r_tilemap_index_to_floor[tilemap_index];

				// Floor with Right Neighbor
				if (is_valid_right_neighbor &&
					r_tilemap_index_to_floor.has(right_neighbor_index)) {
					Ref<_TmpSurface> right_floor =
							r_tilemap_index_to_floor[right_neighbor_index];
					if (current_floor != right_floor &&
						!current_floor->vertices_array.is_empty() &&
						!right_floor->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_floor->vertices_array
													[current_floor
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(right_floor->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_floor->properties ==
								right_floor->properties) {
								current_floor->vertices_array.pop_back();
								Sc::Utils::concat(
										current_floor->vertices_array,
										right_floor->vertices_array);
								Sc::Utils::concat(
										current_floor->tilemap_indices,
										right_floor->tilemap_indices);
								_replace_surface(
										right_floor, current_floor,
										r_tilemap_index_to_floor);
							} else {
								if (current_floor->vertices_array.size() == 1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (right_floor->vertices_array.size() == 1) {
									r_tilemap_index_to_floor.erase(
											right_neighbor_index);
								}
							}
						}
					}
				}
				// Floor with Bottom-Left Neighbor (current_floor might have
				// changed if merged with right)
				current_floor = r_tilemap_index_to_floor.has(tilemap_index)
						? r_tilemap_index_to_floor[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_floor.is_valid() && is_valid_bottom_left_neighbor &&
					r_tilemap_index_to_floor.has(bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bottom_left_floor =
							r_tilemap_index_to_floor
									[bottom_left_neighbor_index];
					if (current_floor != bottom_left_floor &&
						!current_floor->vertices_array.is_empty() &&
						!bottom_left_floor->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(bottom_left_floor->vertices_array
													[bottom_left_floor
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_floor->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_floor->properties ==
								bottom_left_floor->properties) {
								bottom_left_floor->vertices_array.pop_back();
								Sc::Utils::concat(
										bottom_left_floor->vertices_array,
										current_floor->vertices_array);
								current_floor->vertices_array =
										bottom_left_floor
												->vertices_array; // current
																  // takes
																  // merged
																  // vertices
								Sc::Utils::concat(
										current_floor->tilemap_indices,
										bottom_left_floor
												->tilemap_indices); // current
																	// takes
																	// merged
																	// indices
								_replace_surface(
										bottom_left_floor, current_floor,
										r_tilemap_index_to_floor);
							} else {
								if (current_floor->vertices_array.size() == 1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (bottom_left_floor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_floor.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				// Floor with Bottom-Right Neighbor
				current_floor = r_tilemap_index_to_floor.has(tilemap_index)
						? r_tilemap_index_to_floor[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_floor.is_valid() &&
					is_valid_bottom_right_neighbor &&
					r_tilemap_index_to_floor.has(bottom_right_neighbor_index)) {
					Ref<_TmpSurface> bottom_right_floor =
							r_tilemap_index_to_floor
									[bottom_right_neighbor_index];
					if (current_floor != bottom_right_floor &&
						!current_floor->vertices_array.is_empty() &&
						!bottom_right_floor->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_floor->vertices_array
													[current_floor
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(bottom_right_floor
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_floor->properties ==
								bottom_right_floor->properties) {
								current_floor->vertices_array.pop_back();
								Sc::Utils::concat(
										current_floor->vertices_array,
										bottom_right_floor->vertices_array);
								Sc::Utils::concat(
										current_floor->tilemap_indices,
										bottom_right_floor->tilemap_indices);
								_replace_surface(
										bottom_right_floor, current_floor,
										r_tilemap_index_to_floor);
							} else {
								if (current_floor->vertices_array.size() == 1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (bottom_right_floor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_floor.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			}

			// --- Merge Ceilings --- (similar logic to floors, but connection
			// points might be reversed for "clockwise" definition)
			if (r_tilemap_index_to_ceiling.has(tilemap_index)) {
				Ref<_TmpSurface> current_ceiling =
						r_tilemap_index_to_ceiling[tilemap_index];

				// Ceiling with Right Neighbor
				if (is_valid_right_neighbor &&
					r_tilemap_index_to_ceiling.has(right_neighbor_index)) {
					Ref<_TmpSurface> right_ceiling =
							r_tilemap_index_to_ceiling[right_neighbor_index];
					if (current_ceiling != right_ceiling &&
						!current_ceiling->vertices_array.is_empty() &&
						!right_ceiling->vertices_array.is_empty()) {
						// GDScript: right_surface.vertices_array.back() to
						// current_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(right_ceiling->vertices_array
													[right_ceiling
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_ceiling->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_ceiling->properties ==
								right_ceiling->properties) {
								right_ceiling->vertices_array.pop_back();
								Sc::Utils::concat(
										right_ceiling->vertices_array,
										current_ceiling->vertices_array);
								current_ceiling->vertices_array =
										right_ceiling->vertices_array;
								Sc::Utils::concat(
										current_ceiling->tilemap_indices,
										right_ceiling->tilemap_indices);
								_replace_surface(
										right_ceiling, current_ceiling,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_ceiling->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (right_ceiling->vertices_array.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											right_neighbor_index);
								}
							}
						}
					}
				}
				// Ceiling with Bottom-Left Neighbor
				current_ceiling = r_tilemap_index_to_ceiling.has(tilemap_index)
						? r_tilemap_index_to_ceiling[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_ceiling.is_valid() &&
					is_valid_bottom_left_neighbor &&
					r_tilemap_index_to_ceiling.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bottom_left_ceiling =
							r_tilemap_index_to_ceiling
									[bottom_left_neighbor_index];
					if (current_ceiling != bottom_left_ceiling &&
						!current_ceiling->vertices_array.is_empty() &&
						!bottom_left_ceiling->vertices_array.is_empty()) {
						// GDScript: current_surface.vertices_array.back() to
						// bottom_left_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_ceiling->vertices_array
													[current_ceiling
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(bottom_left_ceiling
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_ceiling->properties ==
								bottom_left_ceiling->properties) {
								current_ceiling->vertices_array.pop_back();
								Sc::Utils::concat(
										current_ceiling->vertices_array,
										bottom_left_ceiling->vertices_array);
								Sc::Utils::concat(
										current_ceiling->tilemap_indices,
										bottom_left_ceiling->tilemap_indices);
								_replace_surface(
										bottom_left_ceiling, current_ceiling,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_ceiling->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (bottom_left_ceiling->vertices_array
											.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				// Ceiling with Bottom-Right Neighbor
				current_ceiling = r_tilemap_index_to_ceiling.has(tilemap_index)
						? r_tilemap_index_to_ceiling[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_ceiling.is_valid() &&
					is_valid_bottom_right_neighbor &&
					r_tilemap_index_to_ceiling.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> bottom_right_ceiling =
							r_tilemap_index_to_ceiling
									[bottom_right_neighbor_index];
					if (current_ceiling != bottom_right_ceiling &&
						!current_ceiling->vertices_array.is_empty() &&
						!bottom_right_ceiling->vertices_array.is_empty()) {
						// GDScript: bottom_right_surface.vertices_array.back()
						// to current_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(bottom_right_ceiling->vertices_array
													[bottom_right_ceiling
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_ceiling->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_ceiling->properties ==
								bottom_right_ceiling->properties) {
								bottom_right_ceiling->vertices_array.pop_back();
								Sc::Utils::concat(
										bottom_right_ceiling->vertices_array,
										current_ceiling->vertices_array);
								current_ceiling->vertices_array =
										bottom_right_ceiling->vertices_array;
								Sc::Utils::concat(
										current_ceiling->tilemap_indices,
										bottom_right_ceiling->tilemap_indices);
								_replace_surface(
										bottom_right_ceiling, current_ceiling,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_ceiling->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (bottom_right_ceiling->vertices_array
											.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			}

			// --- Merge Left Walls ---
			if (r_tilemap_index_to_left_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_left_wall =
						r_tilemap_index_to_left_wall[tilemap_index];

				// Left Wall with Bottom Neighbor
				if (is_valid_bottom_neighbor &&
					r_tilemap_index_to_left_wall.has(bottom_neighbor_index)) {
					Ref<_TmpSurface> bottom_left_wall =
							r_tilemap_index_to_left_wall[bottom_neighbor_index];
					if (current_left_wall != bottom_left_wall &&
						!current_left_wall->vertices_array.is_empty() &&
						!bottom_left_wall->vertices_array.is_empty()) {
						// GDScript: current_surface.vertices_array.back() to
						// bottom_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_left_wall->vertices_array
													[current_left_wall
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(bottom_left_wall
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_left_wall->properties ==
								bottom_left_wall->properties) {
								current_left_wall->vertices_array.pop_back();
								Sc::Utils::concat(
										current_left_wall->vertices_array,
										bottom_left_wall->vertices_array);
								Sc::Utils::concat(
										current_left_wall->tilemap_indices,
										bottom_left_wall->tilemap_indices);
								_replace_surface(
										bottom_left_wall, current_left_wall,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_left_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (bottom_left_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_neighbor_index);
								}
							}
						}
					}
				}
				// Left Wall with Bottom-Left Neighbor
				current_left_wall =
						r_tilemap_index_to_left_wall.has(tilemap_index)
						? r_tilemap_index_to_left_wall[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_left_wall.is_valid() &&
					is_valid_bottom_left_neighbor &&
					r_tilemap_index_to_left_wall.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_lw_neighbor =
							r_tilemap_index_to_left_wall
									[bottom_left_neighbor_index];
					if (current_left_wall != bl_lw_neighbor &&
						!current_left_wall->vertices_array.is_empty() &&
						!bl_lw_neighbor->vertices_array.is_empty()) {
						// GDScript: current_surface.vertices_array.back() to
						// bottom_left_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_left_wall->vertices_array
													[current_left_wall
															 ->vertices_array
															 .size() -
													 1]), // This seems to be an
														  // error in GDScript,
														  // should be neighbor
														  // leading? Let's
														  // assume GDScript
														  // meant current leads
														  // to diagonal
														  // neighbor.
									Vector2(bl_lw_neighbor->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_left_wall->properties ==
								bl_lw_neighbor->properties) {
								current_left_wall->vertices_array.pop_back();
								Sc::Utils::concat(
										current_left_wall->vertices_array,
										bl_lw_neighbor->vertices_array);
								Sc::Utils::concat(
										current_left_wall->tilemap_indices,
										bl_lw_neighbor->tilemap_indices);
								_replace_surface(
										bl_lw_neighbor, current_left_wall,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_left_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (bl_lw_neighbor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				// Left Wall with Bottom-Right Neighbor
				current_left_wall =
						r_tilemap_index_to_left_wall.has(tilemap_index)
						? r_tilemap_index_to_left_wall[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_left_wall.is_valid() &&
					is_valid_bottom_right_neighbor &&
					r_tilemap_index_to_left_wall.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_lw_neighbor =
							r_tilemap_index_to_left_wall
									[bottom_right_neighbor_index];
					if (current_left_wall != br_lw_neighbor &&
						!current_left_wall->vertices_array.is_empty() &&
						!br_lw_neighbor->vertices_array.is_empty()) {
						// GDScript: current_surface.vertices_array.back() to
						// bottom_right_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_left_wall->vertices_array
													[current_left_wall
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(br_lw_neighbor->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_left_wall->properties ==
								br_lw_neighbor->properties) {
								current_left_wall->vertices_array.pop_back();
								Sc::Utils::concat(
										current_left_wall->vertices_array,
										br_lw_neighbor->vertices_array);
								Sc::Utils::concat(
										current_left_wall->tilemap_indices,
										br_lw_neighbor->tilemap_indices);
								_replace_surface(
										br_lw_neighbor, current_left_wall,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_left_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (br_lw_neighbor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			}

			// --- Merge Right Walls ---
			if (r_tilemap_index_to_right_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_right_wall =
						r_tilemap_index_to_right_wall[tilemap_index];

				// Right Wall with Bottom Neighbor
				if (is_valid_bottom_neighbor &&
					r_tilemap_index_to_right_wall.has(bottom_neighbor_index)) {
					Ref<_TmpSurface> bottom_right_wall =
							r_tilemap_index_to_right_wall
									[bottom_neighbor_index];
					if (current_right_wall != bottom_right_wall &&
						!current_right_wall->vertices_array.is_empty() &&
						!bottom_right_wall->vertices_array.is_empty()) {
						// GDScript: bottom_surface.vertices_array.back() to
						// current_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(bottom_right_wall->vertices_array
													[bottom_right_wall
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_right_wall
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_right_wall->properties ==
								bottom_right_wall->properties) {
								bottom_right_wall->vertices_array.pop_back();
								Sc::Utils::concat(
										bottom_right_wall->vertices_array,
										current_right_wall->vertices_array);
								current_right_wall->vertices_array =
										bottom_right_wall->vertices_array;
								Sc::Utils::concat(
										current_right_wall->tilemap_indices,
										bottom_right_wall->tilemap_indices);
								_replace_surface(
										bottom_right_wall, current_right_wall,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_right_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (bottom_right_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_neighbor_index);
								}
							}
						}
					}
				}
				// Right Wall with Bottom-Left Neighbor
				current_right_wall =
						r_tilemap_index_to_right_wall.has(tilemap_index)
						? r_tilemap_index_to_right_wall[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_right_wall.is_valid() &&
					is_valid_bottom_left_neighbor &&
					r_tilemap_index_to_right_wall.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_rw_neighbor =
							r_tilemap_index_to_right_wall
									[bottom_left_neighbor_index];
					if (current_right_wall != bl_rw_neighbor &&
						!current_right_wall->vertices_array.is_empty() &&
						!bl_rw_neighbor->vertices_array.is_empty()) {
						// GDScript: bottom_left_surface.vertices_array.back()
						// to current_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(bl_rw_neighbor->vertices_array
													[bl_rw_neighbor
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_right_wall
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_right_wall->properties ==
								bl_rw_neighbor->properties) {
								bl_rw_neighbor->vertices_array.pop_back();
								Sc::Utils::concat(
										bl_rw_neighbor->vertices_array,
										current_right_wall->vertices_array);
								current_right_wall->vertices_array =
										bl_rw_neighbor->vertices_array;
								Sc::Utils::concat(
										current_right_wall->tilemap_indices,
										bl_rw_neighbor->tilemap_indices);
								_replace_surface(
										bl_rw_neighbor, current_right_wall,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_right_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (bl_rw_neighbor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				// Right Wall with Bottom-Right Neighbor
				current_right_wall =
						r_tilemap_index_to_right_wall.has(tilemap_index)
						? r_tilemap_index_to_right_wall[tilemap_index]
						: Ref<_TmpSurface>();
				if (current_right_wall.is_valid() &&
					is_valid_bottom_right_neighbor &&
					r_tilemap_index_to_right_wall.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_rw_neighbor =
							r_tilemap_index_to_right_wall
									[bottom_right_neighbor_index];
					if (current_right_wall != br_rw_neighbor &&
						!current_right_wall->vertices_array.is_empty() &&
						!br_rw_neighbor->vertices_array.is_empty()) {
						// GDScript: bottom_right_surface.vertices_array.back()
						// to current_surface.vertices_array.front()
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(br_rw_neighbor->vertices_array
													[br_rw_neighbor
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_right_wall
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_right_wall->properties ==
								br_rw_neighbor->properties) {
								br_rw_neighbor->vertices_array.pop_back();
								Sc::Utils::concat(
										br_rw_neighbor->vertices_array,
										current_right_wall->vertices_array);
								current_right_wall->vertices_array =
										br_rw_neighbor->vertices_array;
								Sc::Utils::concat(
										current_right_wall->tilemap_indices,
										br_rw_neighbor->tilemap_indices);
								_replace_surface(
										br_rw_neighbor, current_right_wall,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_right_wall->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (br_rw_neighbor->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			}
		}
	}
}

// ...existing code...

// Helper function to get TileShapeData for a given cell
// This could be a static private method of SurfaceParser or a local lambda if
// preferred. For simplicity here, defined as if it's a static helper within the
// class or accessible.
static Ref<TileShapeData> _get_tile_shape_data_for_cell_static(
		TileMap *p_tile_map,
		const Vector2i &p_grid_coord,
		const Dictionary &p_tile_id_to_coord_to_shape_data,
		int p_layer_index = SurfaceParser::SURFACES_TILE_MAPS_COLLISION_LAYER) {
	if (!p_tile_map) {
		return Ref<TileShapeData>();
	}
	int source_id = p_tile_map->get_cell_source_id(p_layer_index, p_grid_coord);
	if (source_id ==
		TileSet::INVALID_SOURCE) { // Check against TileSet::INVALID_SOURCE for
								   // Godot 4
		return Ref<TileShapeData>();
	}

	Vector2i atlas_coords =
			p_tile_map->get_cell_atlas_coords(p_layer_index, p_grid_coord);
	// int alternative_tile =
	// p_tile_map->get_cell_alternative_tile(p_layer_index, p_grid_coord); // If
	// alternative_tile is part of your key

	Variant tile_id_key = source_id;
	Variant tile_coord_key =
			atlas_coords; // Assuming Vector2i is usable as a Dictionary key
						  // directly or via Variant conversion

	if (p_tile_id_to_coord_to_shape_data.has(tile_id_key)) {
		const Variant &coord_map_var =
				p_tile_id_to_coord_to_shape_data[tile_id_key];
		if (coord_map_var.get_type() == Variant::DICTIONARY) {
			const Dictionary &coord_to_shape_map = coord_map_var;
			if (coord_to_shape_map.has(tile_coord_key)) {
				Ref<TileShapeData> tsd = coord_to_shape_map[tile_coord_key];
				return tsd;
			}
		}
	}
	return Ref<TileShapeData>();
}

void SurfaceParser::_remove_internal_multi_vertex_surfaces(
		Dictionary &r_tilemap_index_to_floor,
		Dictionary &r_tilemap_index_to_left_wall,
		Dictionary &r_tilemap_index_to_right_wall,
		Dictionary &r_tilemap_index_to_ceiling,
		const Dictionary &p_tile_id_to_coord_to_shape_data,
		TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);

	Rect2i used_rect = p_tile_map->get_used_rect();
	int tilemap_row_count = used_rect.size.y;
	int tilemap_column_count = used_rect.size.x;

	for (int r = 0; r < tilemap_row_count; ++r) {
		for (int c = 0; c < tilemap_column_count; ++c) {
			int tilemap_index =
					r * tilemap_column_count + c; // Current cell's linear index
			Vector2i current_grid_coord(
					used_rect.position.x + c, used_rect.position.y + r);

			Ref<TileShapeData> tile_shape_data_current =
					_get_tile_shape_data_for_cell_static(
							p_tile_map, current_grid_coord,
							p_tile_id_to_coord_to_shape_data);

			// Neighbor indices and grid coordinates
			int right_neighbor_index = tilemap_index + 1;
			Vector2i right_grid_coord(
					current_grid_coord.x + 1, current_grid_coord.y);
			bool is_valid_right_neighbor = (c < tilemap_column_count - 1);

			int left_neighbor_index = tilemap_index - 1;
			Vector2i left_grid_coord(
					current_grid_coord.x - 1, current_grid_coord.y);
			bool is_valid_left_neighbor = (c > 0);

			int bottom_neighbor_index = tilemap_index + tilemap_column_count;
			Vector2i bottom_grid_coord(
					current_grid_coord.x, current_grid_coord.y + 1);
			bool is_valid_bottom_neighbor = (r < tilemap_row_count - 1);

			int top_neighbor_index = tilemap_index - tilemap_column_count;
			Vector2i top_grid_coord(
					current_grid_coord.x, current_grid_coord.y - 1);
			bool is_valid_top_neighbor = (r > 0);

			// --- Process Floors ---
			if (r_tilemap_index_to_floor.has(tilemap_index)) {
				Ref<_TmpSurface> current_floor =
						r_tilemap_index_to_floor[tilemap_index];
				if (current_floor.is_valid() &&
					current_floor->vertices_array.size() > 1) {
					// Check with Bottom Neighbor
					if (is_valid_bottom_neighbor &&
						r_tilemap_index_to_floor.has(bottom_neighbor_index)) {
						Ref<_TmpSurface> bottom_floor =
								r_tilemap_index_to_floor[bottom_neighbor_index];
						if (bottom_floor.is_valid() &&
							current_floor->properties ==
									bottom_floor->properties) {
							Ref<TileShapeData> tile_shape_data_bottom =
									_get_tile_shape_data_for_cell_static(
											p_tile_map, bottom_grid_coord,
											p_tile_id_to_coord_to_shape_data);
							if (tile_shape_data_current.is_valid() &&
								tile_shape_data_bottom.is_valid() &&
								tile_shape_data_current
										->get_is_bottom_along_cell_boundary() &&
								tile_shape_data_bottom
										->get_is_top_along_cell_boundary()) {
								r_tilemap_index_to_floor.erase(tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
					// Check with Right Neighbor (only if not already removed)
					if (r_tilemap_index_to_floor.has(
								tilemap_index) && // Re-check existence
						is_valid_right_neighbor &&
						r_tilemap_index_to_floor.has(right_neighbor_index)) {
						Ref<_TmpSurface> right_floor =
								r_tilemap_index_to_floor[right_neighbor_index];
						// Re-fetch current_floor in case it was modified by
						// other logic (though not in this function directly)
						current_floor = r_tilemap_index_to_floor[tilemap_index];
						if (current_floor.is_valid() &&
							right_floor.is_valid() &&
							current_floor->properties ==
									right_floor->properties &&
							!current_floor->vertices_array.is_empty() &&
							!right_floor->vertices_array.is_empty()) {
							if (Sc::Geometry::are_points_equal_with_epsilon(
										Vector2(current_floor->vertices_array
														[current_floor
																 ->vertices_array
																 .size() -
														 1]),
										Vector2(right_floor->vertices_array[0]),
										_EQUAL_POINT_EPSILON)) {
								r_tilemap_index_to_floor.erase(tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
				}
			}

			// --- Process Ceilings ---
			if (r_tilemap_index_to_ceiling.has(tilemap_index)) {
				Ref<_TmpSurface> current_ceiling =
						r_tilemap_index_to_ceiling[tilemap_index];
				if (current_ceiling.is_valid() &&
					current_ceiling->vertices_array.size() > 1) {
					// Check with Top Neighbor
					if (is_valid_top_neighbor &&
						r_tilemap_index_to_ceiling.has(top_neighbor_index)) {
						Ref<_TmpSurface> top_ceiling =
								r_tilemap_index_to_ceiling[top_neighbor_index];
						if (top_ceiling.is_valid() &&
							current_ceiling->properties ==
									top_ceiling->properties) {
							Ref<TileShapeData> tile_shape_data_top =
									_get_tile_shape_data_for_cell_static(
											p_tile_map, top_grid_coord,
											p_tile_id_to_coord_to_shape_data);
							if (tile_shape_data_current.is_valid() &&
								tile_shape_data_top.is_valid() &&
								tile_shape_data_current
										->get_is_top_along_cell_boundary() &&
								tile_shape_data_top
										->get_is_bottom_along_cell_boundary()) {
								r_tilemap_index_to_ceiling.erase(tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
					// Check with Right Neighbor (only if not already removed)
					if (r_tilemap_index_to_ceiling.has(
								tilemap_index) && // Re-check existence
						is_valid_right_neighbor &&
						r_tilemap_index_to_ceiling.has(right_neighbor_index)) {
						Ref<_TmpSurface> right_ceiling =
								r_tilemap_index_to_ceiling
										[right_neighbor_index];
						current_ceiling =
								r_tilemap_index_to_ceiling[tilemap_index];
						if (current_ceiling.is_valid() &&
							right_ceiling.is_valid() &&
							current_ceiling->properties ==
									right_ceiling->properties &&
							!current_ceiling->vertices_array.is_empty() &&
							!right_ceiling->vertices_array.is_empty()) {
							// GDScript logic:
							// right_surface.vertices_array.back() ==
							// current_surface.vertices_array.front()
							if (Sc::Geometry::are_points_equal_with_epsilon(
										Vector2(right_ceiling->vertices_array
														[right_ceiling
																 ->vertices_array
																 .size() -
														 1]),
										Vector2(current_ceiling
														->vertices_array[0]),
										_EQUAL_POINT_EPSILON)) {
								r_tilemap_index_to_ceiling.erase(tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
				}
			}

			// --- Process Left Walls ---
			if (r_tilemap_index_to_left_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_left_wall =
						r_tilemap_index_to_left_wall[tilemap_index];
				if (current_left_wall.is_valid() &&
					current_left_wall->vertices_array.size() > 1) {
					// Check with Right Neighbor (of type LeftWall)
					if (is_valid_right_neighbor &&
						r_tilemap_index_to_left_wall.has(
								right_neighbor_index)) {
						Ref<_TmpSurface> right_lw_neighbor =
								r_tilemap_index_to_left_wall
										[right_neighbor_index];
						if (right_lw_neighbor.is_valid() &&
							current_left_wall->properties ==
									right_lw_neighbor->properties) {
							Ref<TileShapeData> tile_shape_data_right =
									_get_tile_shape_data_for_cell_static(
											p_tile_map, right_grid_coord,
											p_tile_id_to_coord_to_shape_data);
							if (tile_shape_data_current.is_valid() &&
								tile_shape_data_right.is_valid() &&
								tile_shape_data_current
										->get_is_right_along_cell_boundary() &&
								tile_shape_data_right
										->get_is_left_along_cell_boundary()) {
								r_tilemap_index_to_left_wall.erase(
										tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
					// Check with Bottom Neighbor (of type LeftWall, only if not
					// already removed)
					if (r_tilemap_index_to_left_wall.has(
								tilemap_index) && // Re-check
						is_valid_bottom_neighbor &&
						r_tilemap_index_to_left_wall.has(
								bottom_neighbor_index)) {
						Ref<_TmpSurface> bottom_lw_neighbor =
								r_tilemap_index_to_left_wall
										[bottom_neighbor_index];
						current_left_wall =
								r_tilemap_index_to_left_wall[tilemap_index];
						if (current_left_wall.is_valid() &&
							bottom_lw_neighbor.is_valid() &&
							current_left_wall->properties ==
									bottom_lw_neighbor->properties &&
							!current_left_wall->vertices_array.is_empty() &&
							!bottom_lw_neighbor->vertices_array.is_empty()) {
							if (Sc::Geometry::are_points_equal_with_epsilon(
										Vector2(current_left_wall->vertices_array
														[current_left_wall
																 ->vertices_array
																 .size() -
														 1]),
										Vector2(bottom_lw_neighbor
														->vertices_array[0]),
										_EQUAL_POINT_EPSILON)) {
								r_tilemap_index_to_left_wall.erase(
										tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
				}
			}

			// --- Process Right Walls ---
			if (r_tilemap_index_to_right_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_right_wall =
						r_tilemap_index_to_right_wall[tilemap_index];
				if (current_right_wall.is_valid() &&
					current_right_wall->vertices_array.size() > 1) {
					// Check with Left Neighbor (of type RightWall)
					if (is_valid_left_neighbor &&
						r_tilemap_index_to_right_wall.has(
								left_neighbor_index)) {
						Ref<_TmpSurface> left_rw_neighbor =
								r_tilemap_index_to_right_wall
										[left_neighbor_index];
						if (left_rw_neighbor.is_valid() &&
							current_right_wall->properties ==
									left_rw_neighbor->properties) {
							Ref<TileShapeData> tile_shape_data_left =
									_get_tile_shape_data_for_cell_static(
											p_tile_map, left_grid_coord,
											p_tile_id_to_coord_to_shape_data);
							if (tile_shape_data_current.is_valid() &&
								tile_shape_data_left.is_valid() &&
								tile_shape_data_current
										->get_is_left_along_cell_boundary() &&
								tile_shape_data_left
										->get_is_right_along_cell_boundary()) {
								r_tilemap_index_to_right_wall.erase(
										tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
					// Check with Bottom Neighbor (of type RightWall, only if
					// not already removed)
					if (r_tilemap_index_to_right_wall.has(
								tilemap_index) && // Re-check
						is_valid_bottom_neighbor &&
						r_tilemap_index_to_right_wall.has(
								bottom_neighbor_index)) {
						Ref<_TmpSurface> bottom_rw_neighbor =
								r_tilemap_index_to_right_wall
										[bottom_neighbor_index];
						current_right_wall =
								r_tilemap_index_to_right_wall[tilemap_index];
						if (current_right_wall.is_valid() &&
							bottom_rw_neighbor.is_valid() &&
							current_right_wall->properties ==
									bottom_rw_neighbor->properties &&
							!current_right_wall->vertices_array.is_empty() &&
							!bottom_rw_neighbor->vertices_array.is_empty()) {
							// GDScript logic:
							// bottom_surface.vertices_array.back() ==
							// current_surface.vertices_array.front()
							if (Sc::Geometry::are_points_equal_with_epsilon(
										Vector2(bottom_rw_neighbor->vertices_array
														[bottom_rw_neighbor
																 ->vertices_array
																 .size() -
														 1]),
										Vector2(current_right_wall
														->vertices_array[0]),
										_EQUAL_POINT_EPSILON)) {
								r_tilemap_index_to_right_wall.erase(
										tilemap_index);
								goto next_cell_iteration_multi_vertex;
							}
						}
					}
				}
			}

		next_cell_iteration_multi_vertex:; // Label for goto, effectively
										   // 'continue' for the outer 'c' loop
										   // iteration
		}
	}
}

// ...existing code...

void SurfaceParser::_replace_surface(
		Ref<_TmpSurface> p_old_surface,
		Ref<_TmpSurface> p_new_surface,
		Dictionary &r_collection) {
	if (p_old_surface.is_null() || p_new_surface.is_null())
		return;
	for (int i = 0; i < p_old_surface->tilemap_indices.size(); ++i) {
		r_collection[p_old_surface->tilemap_indices[i]] = p_new_surface;
	}
	// p_old_surface->free(); // In C++, Ref<> handles this if p_old_surface is
	// no longer referenced. If _TmpSurface is not RefCounted, then
	// memdelete(p_old_surface.ptr()) would be needed. Assuming _TmpSurface is
	// RefCounted, so this explicit free is not needed if refs are managed.
}
// ...existing code...

void SurfaceParser::_merge_continuous_surfaces(
		Dictionary &r_tilemap_index_to_floor,
		Dictionary &r_tilemap_index_to_left_wall,
		Dictionary &r_tilemap_index_to_right_wall,
		Dictionary &r_tilemap_index_to_ceiling,
		TileMap *p_tile_map) {
	ERR_FAIL_NULL(p_tile_map);
	// In Godot 4, get_used_rect() is for all layers.
	// If parsing is layer-specific, this might need to be
	// TileMap::get_used_cells(layer_idx) and then derive bounds, or
	// get_used_rect() from a specific TileMapLayer. This port follows the
	// GDScript's direct use of get_used_rect().
	Rect2i used_rect = p_tile_map->get_used_rect();
	int tilemap_row_count = used_rect.size.y;
	int tilemap_column_count = used_rect.size.x;

	if (tilemap_row_count == 0 || tilemap_column_count == 0) {
		return; // Nothing to process if the used_rect is empty.
	}

	for (int r = 0; r < tilemap_row_count; ++r) {
		for (int c = 0; c < tilemap_column_count; ++c) {
			int tilemap_index = r * tilemap_column_count + c;

			// Neighbor indices
			int right_neighbor_index =
					(c < tilemap_column_count - 1) ? (tilemap_index + 1) : -1;
			int bottom_neighbor_index = (r < tilemap_row_count - 1)
					? (tilemap_index + tilemap_column_count)
					: -1;
			int bottom_left_neighbor_index =
					(r < tilemap_row_count - 1 && c > 0)
					? (bottom_neighbor_index - 1)
					: -1;
			int bottom_right_neighbor_index =
					(r < tilemap_row_count - 1 && c < tilemap_column_count - 1)
					? (bottom_neighbor_index + 1)
					: -1;

			// --- Merge Floors ---
			if (r_tilemap_index_to_floor.has(tilemap_index)) {
				Ref<_TmpSurface> current_surface =
						r_tilemap_index_to_floor[tilemap_index];

				// Floor with Right Neighbor
				if (right_neighbor_index != -1 &&
					r_tilemap_index_to_floor.has(right_neighbor_index)) {
					Ref<_TmpSurface> right_neighbor_surface =
							r_tilemap_index_to_floor[right_neighbor_index];
					if (current_surface.is_valid() &&
						right_neighbor_surface.is_valid() &&
						current_surface != right_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!right_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(right_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								right_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										right_neighbor_surface->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										right_neighbor_surface
												->tilemap_indices);
								_replace_surface(
										right_neighbor_surface, current_surface,
										r_tilemap_index_to_floor);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (right_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_floor.erase(
											right_neighbor_index);
								}
							}
						}
					}
				}
				// Re-fetch current_surface as it might have been merged and its
				// Ref updated by _replace_surface if it was the 'old_surface'
				// (though in the right-neighbor case, it's the 'new_surface',
				// so its Ref should be fine). More critically, its internal
				// arrays could have changed.
				if (!r_tilemap_index_to_floor.has(tilemap_index))
					continue; // Current surface was removed
				current_surface = r_tilemap_index_to_floor[tilemap_index];

				// Floor with Bottom-Left Neighbor
				if (bottom_left_neighbor_index != -1 &&
					r_tilemap_index_to_floor.has(bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_neighbor_surface =
							r_tilemap_index_to_floor
									[bottom_left_neighbor_index];
					if (current_surface.is_valid() &&
						bl_neighbor_surface.is_valid() &&
						current_surface != bl_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bl_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(bl_neighbor_surface->vertices_array
													[bl_neighbor_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_surface->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bl_neighbor_surface->properties) {
								Array temp_vertices =
										bl_neighbor_surface->vertices_array
												.duplicate(); // Work on a copy
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array =
										temp_vertices; // current_surface gets
													   // the merged vertices

								// current_surface.tilemap_indices should
								// accumulate
								// bl_neighbor_surface.tilemap_indices The
								// original GDScript was:
								// Sc.utils.concat(current_surface.tilemap_indices,
								// bottom_left_surface.tilemap_indices) This
								// means current_surface's indices are
								// preserved, and bottom_left's are added.
								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										bl_neighbor_surface->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										bl_neighbor_surface, current_surface,
										r_tilemap_index_to_floor);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (bl_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_floor.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_floor.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_floor[tilemap_index];

				// Floor with Bottom-Right Neighbor
				if (bottom_right_neighbor_index != -1 &&
					r_tilemap_index_to_floor.has(bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_neighbor_surface =
							r_tilemap_index_to_floor
									[bottom_right_neighbor_index];
					if (current_surface.is_valid() &&
						br_neighbor_surface.is_valid() &&
						current_surface != br_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!br_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(br_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								br_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										br_neighbor_surface->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										br_neighbor_surface->tilemap_indices);
								_replace_surface(
										br_neighbor_surface, current_surface,
										r_tilemap_index_to_floor);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_floor.erase(
											tilemap_index);
								}
								if (br_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_floor.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			} // End of Floor Merges

			// --- Merge Ceilings ---
			if (r_tilemap_index_to_ceiling.has(tilemap_index)) {
				Ref<_TmpSurface> current_surface =
						r_tilemap_index_to_ceiling[tilemap_index];

				// Ceiling with Right Neighbor
				if (right_neighbor_index != -1 &&
					r_tilemap_index_to_ceiling.has(right_neighbor_index)) {
					Ref<_TmpSurface> right_neighbor_surface =
							r_tilemap_index_to_ceiling[right_neighbor_index];
					if (current_surface.is_valid() &&
						right_neighbor_surface.is_valid() &&
						current_surface != right_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!right_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(right_neighbor_surface->vertices_array
													[right_neighbor_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_surface->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								right_neighbor_surface->properties) {
								Array temp_vertices =
										right_neighbor_surface->vertices_array
												.duplicate();
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array = temp_vertices;

								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										right_neighbor_surface
												->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										right_neighbor_surface, current_surface,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (right_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											right_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_ceiling.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_ceiling[tilemap_index];

				// Ceiling with Bottom-Left Neighbor
				if (bottom_left_neighbor_index != -1 &&
					r_tilemap_index_to_ceiling.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_neighbor_surface =
							r_tilemap_index_to_ceiling
									[bottom_left_neighbor_index];
					if (current_surface.is_valid() &&
						bl_neighbor_surface.is_valid() &&
						current_surface != bl_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bl_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(bl_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bl_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										bl_neighbor_surface->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										bl_neighbor_surface->tilemap_indices);
								_replace_surface(
										bl_neighbor_surface, current_surface,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (bl_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_ceiling.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_ceiling[tilemap_index];

				// Ceiling with Bottom-Right Neighbor
				if (bottom_right_neighbor_index != -1 &&
					r_tilemap_index_to_ceiling.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_neighbor_surface =
							r_tilemap_index_to_ceiling
									[bottom_right_neighbor_index];
					if (current_surface.is_valid() &&
						br_neighbor_surface.is_valid() &&
						current_surface != br_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!br_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(br_neighbor_surface->vertices_array
													[br_neighbor_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(current_surface->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								br_neighbor_surface->properties) {
								Array temp_vertices =
										br_neighbor_surface->vertices_array
												.duplicate();
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array = temp_vertices;

								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										br_neighbor_surface->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										br_neighbor_surface, current_surface,
										r_tilemap_index_to_ceiling);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_ceiling.erase(
											tilemap_index);
								}
								if (br_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_ceiling.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			} // End of Ceiling Merges

			// --- Merge Left Walls ---
			if (r_tilemap_index_to_left_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_surface =
						r_tilemap_index_to_left_wall[tilemap_index];

				// Left Wall with Bottom Neighbor
				if (bottom_neighbor_index != -1 &&
					r_tilemap_index_to_left_wall.has(bottom_neighbor_index)) {
					Ref<_TmpSurface> bottom_neighbor_surface =
							r_tilemap_index_to_left_wall[bottom_neighbor_index];
					if (current_surface.is_valid() &&
						bottom_neighbor_surface.is_valid() &&
						current_surface != bottom_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bottom_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]),
									Vector2(bottom_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bottom_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										bottom_neighbor_surface
												->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										bottom_neighbor_surface
												->tilemap_indices);
								_replace_surface(
										bottom_neighbor_surface,
										current_surface,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (bottom_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_left_wall.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_left_wall[tilemap_index];

				// Left Wall with Bottom-Left Neighbor
				if (bottom_left_neighbor_index != -1 &&
					r_tilemap_index_to_left_wall.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_neighbor_surface =
							r_tilemap_index_to_left_wall
									[bottom_left_neighbor_index];
					if (current_surface.is_valid() &&
						bl_neighbor_surface.is_valid() &&
						current_surface != bl_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bl_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]), // GDScript:
														  // current.back() to
														  // bottom_left.front()
									Vector2(bl_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bl_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										bl_neighbor_surface->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										bl_neighbor_surface->tilemap_indices);
								_replace_surface(
										bl_neighbor_surface, current_surface,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (bl_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_left_wall.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_left_wall[tilemap_index];

				// Left Wall with Bottom-Right Neighbor
				if (bottom_right_neighbor_index != -1 &&
					r_tilemap_index_to_left_wall.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_neighbor_surface =
							r_tilemap_index_to_left_wall
									[bottom_right_neighbor_index];
					if (current_surface.is_valid() &&
						br_neighbor_surface.is_valid() &&
						current_surface != br_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!br_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon(
									Vector2(current_surface->vertices_array
													[current_surface
															 ->vertices_array
															 .size() -
													 1]), // GDScript:
														  // current.back() to
														  // bottom_right.front()
									Vector2(br_neighbor_surface
													->vertices_array[0]),
									_EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								br_neighbor_surface->properties) {
								current_surface->vertices_array.pop_back();
								Sc::Utils::concat(
										current_surface->vertices_array,
										br_neighbor_surface->vertices_array);
								Sc::Utils::concat(
										current_surface->tilemap_indices,
										br_neighbor_surface->tilemap_indices);
								_replace_surface(
										br_neighbor_surface, current_surface,
										r_tilemap_index_to_left_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_left_wall.erase(
											tilemap_index);
								}
								if (br_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_left_wall.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			} // End of Left Wall Merges

			// --- Merge Right Walls ---
			if (r_tilemap_index_to_right_wall.has(tilemap_index)) {
				Ref<_TmpSurface> current_surface =
						r_tilemap_index_to_right_wall[tilemap_index];

				// Right Wall with Bottom Neighbor
				if (bottom_neighbor_index != -1 &&
					r_tilemap_index_to_right_wall.has(bottom_neighbor_index)) {
					Ref<_TmpSurface> bottom_neighbor_surface =
							r_tilemap_index_to_right_wall
									[bottom_neighbor_index];
					if (current_surface.is_valid() &&
						bottom_neighbor_surface.is_valid() &&
						current_surface != bottom_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bottom_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon( // GDScript: bottom.back() to current.front()
                            Vector2(bottom_neighbor_surface->vertices_array[bottom_neighbor_surface->vertices_array.size() - 1]),
                            Vector2(current_surface->vertices_array[0]),
                            _EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bottom_neighbor_surface->properties) {
								Array temp_vertices =
										bottom_neighbor_surface->vertices_array
												.duplicate();
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array = temp_vertices;

								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										bottom_neighbor_surface
												->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										bottom_neighbor_surface,
										current_surface,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (bottom_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_right_wall.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_right_wall[tilemap_index];

				// Right Wall with Bottom-Left Neighbor
				if (bottom_left_neighbor_index != -1 &&
					r_tilemap_index_to_right_wall.has(
							bottom_left_neighbor_index)) {
					Ref<_TmpSurface> bl_neighbor_surface =
							r_tilemap_index_to_right_wall
									[bottom_left_neighbor_index];
					if (current_surface.is_valid() &&
						bl_neighbor_surface.is_valid() &&
						current_surface != bl_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!bl_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon( // GDScript: bottom_left.back() to current.front()
                            Vector2(bl_neighbor_surface->vertices_array[bl_neighbor_surface->vertices_array.size() - 1]),
                            Vector2(current_surface->vertices_array[0]),
                            _EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								bl_neighbor_surface->properties) {
								Array temp_vertices =
										bl_neighbor_surface->vertices_array
												.duplicate();
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array = temp_vertices;

								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										bl_neighbor_surface->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										bl_neighbor_surface, current_surface,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (bl_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_left_neighbor_index);
								}
							}
						}
					}
				}
				if (!r_tilemap_index_to_right_wall.has(tilemap_index))
					continue;
				current_surface = r_tilemap_index_to_right_wall[tilemap_index];

				// Right Wall with Bottom-Right Neighbor
				if (bottom_right_neighbor_index != -1 &&
					r_tilemap_index_to_right_wall.has(
							bottom_right_neighbor_index)) {
					Ref<_TmpSurface> br_neighbor_surface =
							r_tilemap_index_to_right_wall
									[bottom_right_neighbor_index];
					if (current_surface.is_valid() &&
						br_neighbor_surface.is_valid() &&
						current_surface != br_neighbor_surface &&
						!current_surface->vertices_array.is_empty() &&
						!br_neighbor_surface->vertices_array.is_empty()) {
						if (Sc::Geometry::are_points_equal_with_epsilon( // GDScript: bottom_right.back() to current.front()
                            Vector2(br_neighbor_surface->vertices_array[br_neighbor_surface->vertices_array.size() - 1]),
                            Vector2(current_surface->vertices_array[0]),
                            _EQUAL_POINT_EPSILON)) {
							if (current_surface->properties ==
								br_neighbor_surface->properties) {
								Array temp_vertices =
										br_neighbor_surface->vertices_array
												.duplicate();
								temp_vertices.pop_back();
								Sc::Utils::concat(
										temp_vertices,
										current_surface->vertices_array);
								current_surface->vertices_array = temp_vertices;

								Array new_indices =
										current_surface->tilemap_indices
												.duplicate();
								Sc::Utils::concat(
										new_indices,
										br_neighbor_surface->tilemap_indices);
								current_surface->tilemap_indices = new_indices;

								_replace_surface(
										br_neighbor_surface, current_surface,
										r_tilemap_index_to_right_wall);
							} else {
								if (current_surface->vertices_array.size() ==
									1) {
									r_tilemap_index_to_right_wall.erase(
											tilemap_index);
								}
								if (br_neighbor_surface->vertices_array
											.size() == 1) {
									r_tilemap_index_to_right_wall.erase(
											bottom_right_neighbor_index);
								}
							}
						}
					}
				}
			} // End of Right Wall Merges
		}
	}
}

// ...existing code...

Array SurfaceParser::_get_surface_list_from_map(
		const Dictionary &p_tilemap_index_to_surface) {
	Array surface_list;
	// To get unique surfaces like GDScript's `surface_set[surface] = true`
	Dictionary unique_surfaces_dict;
	Array keys = p_tilemap_index_to_surface.keys();
	for (int i = 0; i < keys.size(); ++i) {
		Ref<_TmpSurface> surface = p_tilemap_index_to_surface[keys[i]];
		if (surface.is_valid()) {
			unique_surfaces_dict[surface] =
					true; // Using Ref as key relies on its Variant conversion
		}
	}
	return unique_surfaces_dict
			.keys(); // Returns an array of the unique _TmpSurface Refs
}

void SurfaceParser::_remove_internal_collinear_vertices(
		const Array &p_surfaces) {
	for (int s_idx = 0; s_idx < p_surfaces.size(); ++s_idx) {
		Ref<_TmpSurface> tmp_surface = p_surfaces[s_idx];
		if (tmp_surface.is_null() || tmp_surface->vertices_array.size() < 3) {
			continue;
		}

		Array new_vertices_array;
		if (!tmp_surface->vertices_array.is_empty()) {
			new_vertices_array.push_back(
					tmp_surface
							->vertices_array[0]); // Always keep the first point
		}

		for (int i = 0; (i + 2) < tmp_surface->vertices_array.size();) {
			Vector2 p1 = tmp_surface->vertices_array[i];
			Vector2 p2 = tmp_surface->vertices_array[i + 1];
			Vector2 p3 = tmp_surface->vertices_array[i + 2];

			if (Sc::Geometry::are_points_collinear(p1, p2, p3)) {
				// p2 is collinear, keep p1, skip p2, next check will involve
				// p1, p3, p4... The GDScript removes vertices[i+1] and
				// decrements i and count. A simpler way is to build a new list.
				// If p1,p2,p3 are collinear, p2 is removed. The new segment is
				// p1-p3. The loop in GDScript `vertices.remove(i+1); i-=1;
				// count-=1; i+=1` effectively means the next iteration starts
				// with `i` pointing to the original `p1`, and `i+1` is original
				// `p3`. Let's rebuild the array: Add p1 (already added or will
				// be current_vertex in new_vertices_array) If p1,p2,p3
				// collinear, skip p2. Next iteration will consider p1,p3,p4.
				// This logic is tricky to replicate exactly with remove in
				// loop. Rebuilding is safer: Add current point (p1). If
				// p1,p2,p3 are NOT collinear, add p2. Then p2 becomes current.
				// This is not what GDScript does. GDScript modifies in place.
			}
			// This part needs careful translation of the in-place removal
			// logic. For now, let's try a direct translation attempt (less safe
			// in C++): This is highly problematic with Array::remove in a loop.
		}
		// Safer: Rebuild the vertices_array
		Array current_vertices = tmp_surface->vertices_array;
		if (current_vertices.size() < 3)
			continue;

		Array final_vertices;
		final_vertices.push_back(
				current_vertices[0]); // Start with the first point

		for (int i = 0; i < current_vertices.size() - 2; ++i) {
			Vector2 p1 =
					final_vertices[final_vertices.size() - 1]; // Last added
															   // point
			Vector2 p2 = current_vertices[i + 1];
			Vector2 p3 = current_vertices[i + 2];
			if (!Sc::Geometry::are_points_collinear(p1, p2, p3)) {
				final_vertices.push_back(p2);
			}
		}
		final_vertices.push_back(
				current_vertices[current_vertices.size() - 1]); // Always add
																// the last
																// point
		tmp_surface->vertices_array = final_vertices;
	}
}

// ...existing code...

// Assuming _EQUAL_POINT_EPSILON is a static const member or accessible globally
// const double SurfaceParser::_EQUAL_POINT_EPSILON = 0.1; // Example definition

bool SurfaceParser::_are_points_equal_componentwise(
		godot::Vector2 p1,
		godot::Vector2 p2,
		double epsilon) {
	double diff_x = p1.x - p2.x;
	double diff_y = p1.y - p2.y;
	return (diff_x < epsilon && diff_x > -epsilon && diff_y < epsilon &&
			diff_y > -epsilon);
}

void SurfaceParser::_assign_neighbor_surfaces(
		const Array &p_floors,
		const Array &p_ceilings,
		const Array &p_left_walls,
		const Array &p_right_walls) {
	// Assign convex and concave neighbors
	for (int i = 0; i < p_floors.size(); ++i) {
		Ref<Surface> floor_surface = p_floors[i];
		Vector2 floor_left_edge = floor_surface->get_first_point();
		Vector2 floor_right_edge = floor_surface->get_last_point();

		for (int j = 0; j < p_right_walls.size(); ++j) {
			Ref<Surface> right_wall = p_right_walls[j];
			// Check for a convex neighbor: floor's left edge to right wall's
			// top edge (last_point of right_wall)
			if (_are_points_equal_componentwise(
						floor_left_edge, right_wall->get_last_point(),
						_EQUAL_POINT_EPSILON)) {
				floor_surface->set_counter_clockwise_convex_neighbor(
						right_wall);
				right_wall->set_clockwise_convex_neighbor(floor_surface);
				if (floor_surface->get_clockwise_neighbor().is_valid() &&
					floor_surface->get_counter_clockwise_neighbor()
							.is_valid()) { // Adjusted break condition
					break;
				}
			}
			// Check for a concave neighbor: floor's right edge to right wall's
			// bottom edge (first_point of right_wall)
			if (_are_points_equal_componentwise(
						floor_right_edge, right_wall->get_first_point(),
						_EQUAL_POINT_EPSILON)) {
				floor_surface->set_clockwise_concave_neighbor(right_wall);
				right_wall->set_counter_clockwise_concave_neighbor(
						floor_surface);
				if (floor_surface->get_clockwise_neighbor().is_valid() &&
					floor_surface->get_counter_clockwise_neighbor()
							.is_valid()) { // Adjusted break condition
					break;
				}
			}
		}
		if (floor_surface->get_clockwise_neighbor().is_valid() &&
			floor_surface->get_counter_clockwise_neighbor().is_valid())
			continue;

		for (int j = 0; j < p_left_walls.size(); ++j) {
			Ref<Surface> left_wall = p_left_walls[j];
			// Check for a convex neighbor: floor's right edge to left wall's
			// top edge (first_point of left_wall)
			if (_are_points_equal_componentwise(
						floor_right_edge, left_wall->get_first_point(),
						_EQUAL_POINT_EPSILON)) {
				floor_surface->set_clockwise_convex_neighbor(left_wall);
				left_wall->set_counter_clockwise_convex_neighbor(floor_surface);
				if (floor_surface->get_clockwise_neighbor().is_valid() &&
					floor_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
			// Check for a concave neighbor: floor's left edge to left wall's
			// bottom edge (last_point of left_wall)
			if (_are_points_equal_componentwise(
						floor_left_edge, left_wall->get_last_point(),
						_EQUAL_POINT_EPSILON)) {
				floor_surface->set_counter_clockwise_concave_neighbor(
						left_wall);
				left_wall->set_clockwise_concave_neighbor(floor_surface);
				if (floor_surface->get_clockwise_neighbor().is_valid() &&
					floor_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
		}
	}

	for (int i = 0; i < p_ceilings.size(); ++i) {
		Ref<Surface> ceiling_surface = p_ceilings[i];
		Vector2 ceiling_right_edge =
				ceiling_surface->get_first_point(); // Ceilings are defined
													// right-to-left in GDScript
													// example
		Vector2 ceiling_left_edge = ceiling_surface->get_last_point();

		for (int j = 0; j < p_left_walls.size(); ++j) {
			Ref<Surface> left_wall = p_left_walls[j];
			// Check for a convex neighbor: ceiling's right edge to left wall's
			// bottom edge (last_point of left_wall)
			if (_are_points_equal_componentwise(
						ceiling_right_edge, left_wall->get_last_point(),
						_EQUAL_POINT_EPSILON)) {
				ceiling_surface->set_counter_clockwise_convex_neighbor(
						left_wall);
				left_wall->set_clockwise_convex_neighbor(ceiling_surface);
				if (ceiling_surface->get_clockwise_neighbor().is_valid() &&
					ceiling_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
			// Check for a concave neighbor: ceiling's left edge to left wall's
			// top edge (first_point of left_wall)
			if (_are_points_equal_componentwise(
						ceiling_left_edge, left_wall->get_first_point(),
						_EQUAL_POINT_EPSILON)) {
				ceiling_surface->set_clockwise_concave_neighbor(left_wall);
				left_wall->set_counter_clockwise_concave_neighbor(
						ceiling_surface);
				if (ceiling_surface->get_clockwise_neighbor().is_valid() &&
					ceiling_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
		}
		if (ceiling_surface->get_clockwise_neighbor().is_valid() &&
			ceiling_surface->get_counter_clockwise_neighbor().is_valid())
			continue;

		for (int j = 0; j < p_right_walls.size(); ++j) {
			Ref<Surface> right_wall = p_right_walls[j];
			// Check for a convex neighbor: ceiling's left edge to right wall's
			// bottom edge (first_point of right_wall)
			if (_are_points_equal_componentwise(
						ceiling_left_edge, right_wall->get_first_point(),
						_EQUAL_POINT_EPSILON)) {
				ceiling_surface->set_clockwise_convex_neighbor(right_wall);
				right_wall->set_counter_clockwise_convex_neighbor(
						ceiling_surface);
				if (ceiling_surface->get_clockwise_neighbor().is_valid() &&
					ceiling_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
			// Check for a concave neighbor: ceiling's right edge to right
			// wall's top edge (last_point of right_wall)
			if (_are_points_equal_componentwise(
						ceiling_right_edge, right_wall->get_last_point(),
						_EQUAL_POINT_EPSILON)) {
				ceiling_surface->set_counter_clockwise_concave_neighbor(
						right_wall);
				right_wall->set_clockwise_concave_neighbor(ceiling_surface);
				if (ceiling_surface->get_clockwise_neighbor().is_valid() &&
					ceiling_surface->get_counter_clockwise_neighbor()
							.is_valid()) {
					break;
				}
			}
		}
	}

	// Check for collinear neighbors
	for (int i = 0; i < p_floors.size(); ++i) {
		Ref<Surface> floor_surface = p_floors[i];
		if (floor_surface->get_counter_clockwise_neighbor().is_valid() &&
			floor_surface->get_clockwise_neighbor().is_valid()) {
			continue;
		}
		Vector2 floor_left_edge = floor_surface->get_first_point();
		Vector2 floor_right_edge = floor_surface->get_last_point();

		for (int j = 0; j < p_floors.size(); ++j) {
			if (i == j)
				continue;
			Ref<Surface> other_floor = p_floors[j];

			if (!floor_surface->get_clockwise_neighbor().is_valid()) {
				if (_are_points_equal_componentwise(
							floor_right_edge, other_floor->get_first_point(),
							_EQUAL_POINT_EPSILON)) {
					floor_surface->set_clockwise_collinear_neighbor(
							other_floor);
					other_floor->set_counter_clockwise_collinear_neighbor(
							floor_surface);
				}
			}
			if (!floor_surface->get_counter_clockwise_neighbor().is_valid()) {
				if (_are_points_equal_componentwise(
							floor_left_edge, other_floor->get_last_point(),
							_EQUAL_POINT_EPSILON)) {
					floor_surface->set_counter_clockwise_collinear_neighbor(
							other_floor);
					other_floor->set_clockwise_collinear_neighbor(
							floor_surface);
				}
			}
			if (floor_surface->get_counter_clockwise_neighbor().is_valid() &&
				floor_surface->get_clockwise_neighbor().is_valid()) {
				break;
			}
		}
	}

	for (int i = 0; i < p_ceilings.size(); ++i) {
		Ref<Surface> ceiling_surface = p_ceilings[i];
		if (ceiling_surface->get_counter_clockwise_neighbor().is_valid() &&
			ceiling_surface->get_clockwise_neighbor().is_valid()) {
			continue;
		}
		Vector2 ceiling_right_edge = ceiling_surface->get_first_point();
		Vector2 ceiling_left_edge = ceiling_surface->get_last_point();

		for (int j = 0; j < p_ceilings.size(); ++j) {
			if (i == j)
				continue;
			Ref<Surface> other_ceiling = p_ceilings[j];

			if (!ceiling_surface->get_clockwise_neighbor()
						 .is_valid()) { // Clockwise for ceiling is its left
										// edge connecting to other's right
				if (_are_points_equal_componentwise(
							ceiling_left_edge, other_ceiling->get_first_point(),
							_EQUAL_POINT_EPSILON)) {
					ceiling_surface->set_clockwise_collinear_neighbor(
							other_ceiling);
					other_ceiling->set_counter_clockwise_collinear_neighbor(
							ceiling_surface);
				}
			}
			if (!ceiling_surface->get_counter_clockwise_neighbor()
						 .is_valid()) { // Counter-clockwise for ceiling is its
										// right edge connecting to other's left
				if (_are_points_equal_componentwise(
							ceiling_right_edge, other_ceiling->get_last_point(),
							_EQUAL_POINT_EPSILON)) {
					ceiling_surface->set_counter_clockwise_collinear_neighbor(
							other_ceiling);
					other_ceiling->set_clockwise_collinear_neighbor(
							ceiling_surface);
				}
			}
			if (ceiling_surface->get_counter_clockwise_neighbor().is_valid() &&
				ceiling_surface->get_clockwise_neighbor().is_valid()) {
				break;
			}
		}
	}

	for (int i = 0; i < p_left_walls.size(); ++i) {
		Ref<Surface> left_wall = p_left_walls[i];
		if (left_wall->get_counter_clockwise_neighbor().is_valid() &&
			left_wall->get_clockwise_neighbor().is_valid()) {
			continue;
		}
		Vector2 lw_top_edge = left_wall->get_first_point();
		Vector2 lw_bottom_edge = left_wall->get_last_point();

		for (int j = 0; j < p_left_walls.size(); ++j) {
			if (i == j)
				continue;
			Ref<Surface> other_lw = p_left_walls[j];

			if (!left_wall->get_clockwise_neighbor()
						 .is_valid()) { // Clockwise for left_wall is its bottom
										// edge connecting to other's top
				if (_are_points_equal_componentwise(
							lw_bottom_edge, other_lw->get_first_point(),
							_EQUAL_POINT_EPSILON)) {
					left_wall->set_clockwise_collinear_neighbor(other_lw);
					other_lw->set_counter_clockwise_collinear_neighbor(
							left_wall);
				}
			}
			if (!left_wall->get_counter_clockwise_neighbor()
						 .is_valid()) { // Counter-clockwise for left_wall is
										// its top edge connecting to other's
										// bottom
				if (_are_points_equal_componentwise(
							lw_top_edge, other_lw->get_last_point(),
							_EQUAL_POINT_EPSILON)) {
					left_wall->set_counter_clockwise_collinear_neighbor(
							other_lw);
					other_lw->set_clockwise_collinear_neighbor(left_wall);
				}
			}
			if (left_wall->get_counter_clockwise_neighbor().is_valid() &&
				left_wall->get_clockwise_neighbor().is_valid()) {
				break;
			}
		}
	}

	for (int i = 0; i < p_right_walls.size(); ++i) {
		Ref<Surface> right_wall = p_right_walls[i];
		if (right_wall->get_counter_clockwise_neighbor().is_valid() &&
			right_wall->get_clockwise_neighbor().is_valid()) {
			continue;
		}
		Vector2 rw_bottom_edge =
				right_wall->get_first_point(); // Right walls are defined
											   // bottom-to-top in GDScript
											   // example
		Vector2 rw_top_edge = right_wall->get_last_point();

		for (int j = 0; j < p_right_walls.size(); ++j) {
			if (i == j)
				continue;
			Ref<Surface> other_rw = p_right_walls[j];

			if (!right_wall->get_clockwise_neighbor()
						 .is_valid()) { // Clockwise for right_wall is its top
										// edge connecting to other's bottom
				if (_are_points_equal_componentwise(
							rw_top_edge, other_rw->get_first_point(),
							_EQUAL_POINT_EPSILON)) {
					right_wall->set_clockwise_collinear_neighbor(other_rw);
					other_rw->set_counter_clockwise_collinear_neighbor(
							right_wall);
				}
			}
			if (!right_wall->get_counter_clockwise_neighbor()
						 .is_valid()) { // Counter-clockwise for right_wall is
										// its bottom edge connecting to other's
										// top
				if (_are_points_equal_componentwise(
							rw_bottom_edge, other_rw->get_last_point(),
							_EQUAL_POINT_EPSILON)) {
					right_wall->set_counter_clockwise_collinear_neighbor(
							other_rw);
					other_rw->set_clockwise_collinear_neighbor(right_wall);
				}
			}
			if (right_wall->get_counter_clockwise_neighbor().is_valid() &&
				right_wall->get_clockwise_neighbor().is_valid()) {
				break;
			}
		}
	}

	// Final pass for unassigned neighbors (concave floor-ceiling, wall-wall)
	for (int i = 0; i < p_floors.size(); ++i) {
		Ref<Surface> floor_surface = p_floors[i];
		if (!floor_surface->get_counter_clockwise_neighbor().is_valid()) {
			Vector2 floor_left_edge = floor_surface->get_first_point();
			for (int j = 0; j < p_ceilings.size(); ++j) {
				Ref<Surface> ceiling_surface = p_ceilings[j];
				if (_are_points_equal_componentwise(
							floor_left_edge, ceiling_surface->get_last_point(),
							_EQUAL_POINT_EPSILON)) { // ceiling's left edge
					floor_surface->set_counter_clockwise_concave_neighbor(
							ceiling_surface);
					ceiling_surface->set_clockwise_concave_neighbor(
							floor_surface);
					break;
				}
			}
		}
		if (!floor_surface->get_clockwise_neighbor().is_valid()) {
			Vector2 floor_right_edge = floor_surface->get_last_point();
			for (int j = 0; j < p_ceilings.size(); ++j) {
				Ref<Surface> ceiling_surface = p_ceilings[j];
				if (_are_points_equal_componentwise(
							floor_right_edge,
							ceiling_surface->get_first_point(),
							_EQUAL_POINT_EPSILON)) { // ceiling's right edge
					floor_surface->set_clockwise_concave_neighbor(
							ceiling_surface);
					ceiling_surface->set_counter_clockwise_concave_neighbor(
							floor_surface);
					break;
				}
			}
		}
	}

	for (int i = 0; i < p_right_walls.size(); ++i) {
		Ref<Surface> right_wall = p_right_walls[i];
		if (!right_wall->get_counter_clockwise_neighbor().is_valid()) {
			Vector2 rw_bottom_edge = right_wall->get_first_point();
			for (int j = 0; j < p_left_walls.size(); ++j) {
				Ref<Surface> left_wall = p_left_walls[j];
				if (_are_points_equal_componentwise(
							rw_bottom_edge, left_wall->get_last_point(),
							_EQUAL_POINT_EPSILON)) { // left_wall's bottom edge
					right_wall->set_counter_clockwise_concave_neighbor(
							left_wall);
					left_wall->set_clockwise_concave_neighbor(right_wall);
					break;
				}
			}
		}
		if (!right_wall->get_clockwise_neighbor().is_valid()) {
			Vector2 rw_top_edge = right_wall->get_last_point();
			for (int j = 0; j < p_left_walls.size(); ++j) {
				Ref<Surface> left_wall = p_left_walls[j];
				if (_are_points_equal_componentwise(
							rw_top_edge, left_wall->get_first_point(),
							_EQUAL_POINT_EPSILON)) { // left_wall's top edge
					right_wall->set_clockwise_concave_neighbor(left_wall);
					left_wall->set_counter_clockwise_concave_neighbor(
							right_wall);
					break;
				}
			}
		}
	}
}

void SurfaceParser::_calculate_shape_bounding_boxes_for_surfaces(
		const Array &p_surfaces) { // Array of Ref<Surface>
	for (int i = 0; i < p_surfaces.size(); ++i) {
		Ref<Surface> surface = p_surfaces[i];
		if (surface.is_null() ||
			surface->get_connected_region_bounding_box_calculated()) { // Add a
																	   // flag
																	   // to
																	   // Surface
			continue;
		}

		Rect2 connected_region_bounding_box =
				surface->get_bounding_box(); // Assuming Surface has
											 // get_bounding_box()

		Array q;
		q.push_back(surface);
		Dictionary visited;
		visited[surface] = true;
		Array component_surfaces;
		component_surfaces.push_back(surface);

		int head = 0;
		while (head < q.size()) {
			Ref<Surface> current_s = q[head++];

			Ref<Surface> cw_neighbor =
					current_s->get_clockwise_neighbor(); // Assuming method
														 // exists
			Ref<Surface> ccw_neighbor =
					current_s
							->get_counter_clockwise_neighbor(); // Assuming
																// method exists

			if (cw_neighbor.is_valid() && !visited.has(cw_neighbor)) {
				visited[cw_neighbor] = true;
				q.push_back(cw_neighbor);
				component_surfaces.push_back(cw_neighbor);
				connected_region_bounding_box =
						connected_region_bounding_box.merge(
								cw_neighbor->get_bounding_box());
			}
			if (ccw_neighbor.is_valid() && !visited.has(ccw_neighbor)) {
				visited[ccw_neighbor] = true;
				q.push_back(ccw_neighbor);
				component_surfaces.push_back(ccw_neighbor);
				connected_region_bounding_box =
						connected_region_bounding_box.merge(
								ccw_neighbor->get_bounding_box());
			}
		}

		for (int j = 0; j < component_surfaces.size(); ++j) {
			Ref<Surface> s_in_component = component_surfaces[j];
			s_in_component->set_connected_region_bounding_box(
					connected_region_bounding_box); // Assuming method exists
			s_in_component->set_connected_region_bounding_box_calculated(
					true); // Assuming method exists
		}
	}
}

void SurfaceParser::_assert_surfaces_have_neighbors(
		const Array &p_surfaces) { // Array of Ref<Surface>
	if (Engine::get_singleton()->is_editor_hint())
		return; // Skip in editor if it's too slow or noisy

	for (int i = 0; i < p_surfaces.size(); ++i) {
		Ref<Surface> surface = p_surfaces[i];
		ERR_FAIL_COND_MSG(surface.is_null(), "Null surface in collection.");
		// ERR_FAIL_COND_MSG(surface->get_clockwise_neighbor().is_null(),
		// "Surface missing clockwise neighbor. ID: " +
		// surface->get_id_string());
		// ERR_FAIL_COND_MSG(surface->get_counter_clockwise_neighbor().is_null(),
		// "Surface missing counter-clockwise neighbor. ID: " +
		// surface->get_id_string());
	}
}

void SurfaceParser::_populate_surface_objects(
		const Array &p_tmp_surfaces, // Array of Ref<_TmpSurface>
		Surface::Side p_side) {
	for (int i = 0; i < p_tmp_surfaces.size(); ++i) {
		Ref<_TmpSurface> tmp_surface = p_tmp_surfaces[i];
		if (tmp_surface.is_valid()) {
			Ref<Surface> final_surface = memnew(
					Surface(tmp_surface->vertices_array, // This should be
														 // PackedVector2Array
							p_side, tmp_surface->tile_map,
							tmp_surface->tilemap_indices, // This should be
														  // PackedInt32Array
							tmp_surface->properties));
			tmp_surface->surface = final_surface; // Store the created Surface
												  // back in _TmpSurface
		}
	}
}

void SurfaceParser::_copy_surfaces_to_main_collection(
		const Array &p_tmp_surfaces, // Array of Ref<_TmpSurface>
		Array &r_main_collection) { // Array of Ref<Surface>
	for (int i = 0; i < p_tmp_surfaces.size(); ++i) {
		Ref<_TmpSurface> tmp_surface = p_tmp_surfaces[i];
		if (tmp_surface.is_valid() && tmp_surface->surface.is_valid()) {
			r_main_collection.push_back(tmp_surface->surface);
		}
	}
}

Dictionary SurfaceParser::_create_tilemap_mapping_from_surfaces(
		const Array &p_surfaces, // Array of Ref<Surface>
		TileMap *p_tile_map) {
	Dictionary result;
	for (int i = 0; i < p_surfaces.size(); ++i) {
		Ref<Surface> surface = p_surfaces[i];
		if (surface.is_valid() &&
			surface->get_tile_map() ==
					p_tile_map) { // Assuming Surface has get_tile_map()
			PackedInt32Array tilemap_indices =
					surface->get_tilemap_indices(); // Assuming Surface has
													// get_tilemap_indices()
			for (int j = 0; j < tilemap_indices.size(); ++j) {
				result[tilemap_indices[j]] = surface;
			}
		}
	}
	return result;
}

void SurfaceParser::_free_objects(
		const Array &p_objects) { // Array of Ref<_TmpSurface>
	// If _TmpSurface is RefCounted and p_objects holds Ref<_TmpSurface>,
	// explicit freeing is not necessary as Ref<> handles it.
	// The GDScript `object.free()` is more general.
	// If these were raw pointers to Godot Objects not RefCounted, then
	// memdelete would be used. Assuming RefCounted, this function might be a
	// no-op or just clear the array if it's the owner.
}

void SurfaceParser::_parse_surface_mark(
		SurfaceStore *p_surface_store,
		SurfaceMark
				*p_surface_mark, // Custom class extending TileMap or similar
		TileMap *p_tile_map) { // The main TileMap for surface lookup
	ERR_FAIL_NULL(p_surface_store);
	ERR_FAIL_NULL(p_surface_mark);
	ERR_FAIL_NULL(p_tile_map);

	// Assuming SurfaceMark has get_tileset() and it returns a TileSet with
	// get_tile_size()
	Ref<TileSet> mark_ts = p_surface_mark->get_tileset();
	ERR_FAIL_COND(mark_ts.is_null());
	Vector2 mark_cell_size = mark_ts->get_tile_size();
	// Vector2 tilemap_cell_size = mark_cell_size * 2.0; // From GDScript, seems
	// odd. Let's use the main p_tile_map's cell size for consistency if needed.
	// Ref<TileSet> main_ts = p_tile_map->get_tileset();
	// ERR_FAIL_COND(main_ts.is_null());
	// Vector2 tilemap_cell_size = main_ts->get_tile_size();

	// Assuming SurfaceMark has get_used_cells(layer_idx) like TileMap
	TypedArray<Vector2i> used_mark_cells =
			p_surface_mark->get_used_cells(0); // Assuming layer 0 for marks

	for (int i = 0; i < used_mark_cells.size(); ++i) {
		Vector2i mark_position_grid = used_mark_cells[i];

		// Logic from GDScript to map mark_position to tilemap_positions
		int mark_position_x = mark_position_grid.x;
		int mark_position_y = mark_position_grid.y;
		int tilemap_position_x_base =
				static_cast<int>(Math::floor((mark_position_x - 1) / 2.0));
		int tilemap_position_y_base =
				static_cast<int>(Math::floor((mark_position_y - 1) / 2.0));
		bool is_between_tilemap_cells_horizontally = (mark_position_x % 2 == 0);
		bool is_between_tilemap_cells_vertically = (mark_position_y % 2 == 0);

		Array tilemap_positions_grid_array; // Array of Vector2i
		if (is_between_tilemap_cells_horizontally &&
			is_between_tilemap_cells_vertically) {
			tilemap_positions_grid_array.push_back(
					Vector2i(tilemap_position_x_base, tilemap_position_y_base));
			tilemap_positions_grid_array.push_back(Vector2i(
					tilemap_position_x_base + 1, tilemap_position_y_base));
			tilemap_positions_grid_array.push_back(Vector2i(
					tilemap_position_x_base, tilemap_position_y_base + 1));
			tilemap_positions_grid_array.push_back(Vector2i(
					tilemap_position_x_base + 1, tilemap_position_y_base + 1));
		} else if (is_between_tilemap_cells_horizontally) {
			tilemap_positions_grid_array.push_back(
					Vector2i(tilemap_position_x_base, tilemap_position_y_base));
			tilemap_positions_grid_array.push_back(Vector2i(
					tilemap_position_x_base + 1, tilemap_position_y_base));
		} else if (is_between_tilemap_cells_vertically) {
			tilemap_positions_grid_array.push_back(
					Vector2i(tilemap_position_x_base, tilemap_position_y_base));
			tilemap_positions_grid_array.push_back(Vector2i(
					tilemap_position_x_base, tilemap_position_y_base + 1));
		} else {
			tilemap_positions_grid_array.push_back(
					Vector2i(tilemap_position_x_base, tilemap_position_y_base));
		}

		Vector2 mark_cell_min_world_coords =
				mark_position_grid.operator Vector2() * mark_cell_size +
				p_surface_mark->get_global_position();
		Vector2 mark_cell_max_world_coords =
				mark_cell_min_world_coords + mark_cell_size;

		for (int j = 0; j < tilemap_positions_grid_array.size(); ++j) {
			Vector2i tilemap_pos_grid_to_check =
					tilemap_positions_grid_array[j];
			int tilemap_index = Sc::Geometry::get_tilemap_index_from_grid_coord(
					tilemap_pos_grid_to_check, p_tile_map);

			Ref<Surface> floor_surface = p_surface_store->get_surface_for_tile(
					p_tile_map, tilemap_index, Surface::Side::FLOOR);
			Ref<Surface> ceiling_surface =
					p_surface_store->get_surface_for_tile(
							p_tile_map, tilemap_index, Surface::Side::CEILING);
			Ref<Surface> left_wall_surface =
					p_surface_store->get_surface_for_tile(
							p_tile_map, tilemap_index,
							Surface::Side::LEFT_WALL);
			Ref<Surface> right_wall_surface =
					p_surface_store->get_surface_for_tile(
							p_tile_map, tilemap_index,
							Surface::Side::RIGHT_WALL);

			if (floor_surface.is_valid() &&
				Sc::Geometry::do_surface_and_rectangle_intersect(
						floor_surface, mark_cell_min_world_coords,
						mark_cell_max_world_coords)) {
				p_surface_mark->add_surface(
						floor_surface); // Assuming SurfaceMark has
										// add_surface(Ref<Surface>)
			}
			if (ceiling_surface.is_valid() &&
				Sc::Geometry::do_surface_and_rectangle_intersect(
						ceiling_surface, mark_cell_min_world_coords,
						mark_cell_max_world_coords)) {
				p_surface_mark->add_surface(ceiling_surface);
			}
			if (left_wall_surface.is_valid() &&
				Sc::Geometry::do_surface_and_rectangle_intersect(
						left_wall_surface, mark_cell_min_world_coords,
						mark_cell_max_world_coords)) {
				p_surface_mark->add_surface(left_wall_surface);
			}
			if (right_wall_surface.is_valid() &&
				Sc::Geometry::do_surface_and_rectangle_intersect(
						right_wall_surface, mark_cell_min_world_coords,
						mark_cell_max_world_coords)) {
				p_surface_mark->add_surface(right_wall_surface);
			}
		}
	}
}

} // namespace godot
