#include "surfacer_draw_utils.h"

#include <godot_cpp/core/class_db.hpp>

void SurfacerDrawUtils::draw_surface(
		godot::CanvasItem *p_canvas,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth_param) {
	if (!p_canvas || !p_surface)
		return;

	float actual_depth = (p_depth_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .surface_depth
			: p_depth_param;

	godot::PackedVector2Array vertices =
			p_surface->get_vertices(); // Assuming Surface::get_vertices()
	int vertex_count = vertices.size();

	ERR_FAIL_COND_MSG(vertex_count <= 0, "Surface has no vertices.");

	if (vertex_count == 1) {
		draw_single_vertex_surface(p_canvas, p_surface, p_color, actual_depth);
		return;
	}

	// Assuming Surface has get_counter_clockwise_neighbor() and
	// get_clockwise_neighbor() which return Ref<Surface> or Surface*
	godot::Surface *ccw_neighbor = p_surface->get_counter_clockwise_neighbor();
	godot::PackedVector2Array preceding_vertices;
	if (ccw_neighbor) {
		preceding_vertices = ccw_neighbor->get_vertices();
		if (preceding_vertices.size() <= 1) {
			godot::Surface *ccw_ccw_neighbor =
					ccw_neighbor->get_counter_clockwise_neighbor();
			if (ccw_ccw_neighbor)
				preceding_vertices = ccw_ccw_neighbor->get_vertices();
		}
	}
	ERR_FAIL_COND_MSG(
			preceding_vertices.size() <= 1,
			"Could not get valid preceding vertices for surface drawing.");
	godot::Vector2 first_segment_preceding_point =
			preceding_vertices[preceding_vertices.size() - 2];

	godot::Surface *cw_neighbor = p_surface->get_clockwise_neighbor();
	godot::PackedVector2Array following_vertices;
	if (cw_neighbor) {
		following_vertices = cw_neighbor->get_vertices();
		if (following_vertices.size() <= 1) {
			godot::Surface *cw_cw_neighbor =
					cw_neighbor->get_clockwise_neighbor();
			if (cw_cw_neighbor)
				following_vertices = cw_cw_neighbor->get_vertices();
		}
	}
	ERR_FAIL_COND_MSG(
			following_vertices.size() <= 1,
			"Could not get valid following vertices for surface drawing.");
	godot::Vector2 last_segment_following_point = following_vertices[1];

	if (vertex_count == 2) {
		draw_surface_segment(
				p_canvas, vertices[0], vertices[1],
				first_segment_preceding_point, last_segment_following_point,
				p_surface, p_color, actual_depth);
	} else {
		draw_surface_segment(
				p_canvas, vertices[0], vertices[1],
				first_segment_preceding_point, vertices[2], p_surface, p_color,
				actual_depth);

		for (int i = 1; i < vertex_count - 2; ++i) {
			draw_surface_segment(
					p_canvas, vertices[i], vertices[i + 1], vertices[i - 1],
					vertices[i + 2], p_surface, p_color, actual_depth);
		}

		draw_surface_segment(
				p_canvas, vertices[vertex_count - 2],
				vertices[vertex_count - 1], vertices[vertex_count - 3],
				last_segment_following_point, p_surface, p_color, actual_depth);
	}
}

void SurfacerDrawUtils::draw_surface_segment(
		godot::CanvasItem *p_canvas,
		const godot::Vector2 &p_segment_start,
		const godot::Vector2 &p_segment_end,
		const godot::Vector2 &p_preceding_point,
		const godot::Vector2 &p_following_point,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth) {
	if (!p_canvas)
		return;

	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();

	godot::Vector2 displacement = p_segment_end - p_segment_start;
	godot::Vector2 segment_normal =
			SurfacerDrawUtilsPlaceholders::Geometry::get_segment_normal(
					p_segment_start, p_segment_end);

	float surface_depth_division_size =
			p_depth / params.surface_depth_divisions_count;
	godot::Vector2 segment_depth_division_offset =
			segment_normal * -surface_depth_division_size;
	// godot::Vector2 half_segment_depth_division_offset =
	// segment_depth_division_offset / 2.0; // Unused in GDScript

	godot::Vector2 segment_direction =
			(p_segment_end - p_segment_start).normalized();
	godot::Vector2 preceding_segment_direction =
			(p_segment_start - p_preceding_point).normalized();
	godot::Vector2 following_segment_direction =
			(p_following_point - p_segment_end).normalized();

	godot::Vector2 preceding_angular_bisector_direction_non_normalized =
			(!preceding_segment_direction.is_equal_approx(segment_direction))
			? (-preceding_segment_direction + segment_direction)
			: segment_direction
					  .orthogonal(); // tangent() in Godot is orthogonal()
	godot::Vector2 preceding_angular_bisector_segment_end_offset =
			preceding_angular_bisector_direction_non_normalized * 1000.0f;
	godot::Vector2 preceding_angular_bisector_segment_start =
			p_segment_start - preceding_angular_bisector_segment_end_offset;
	godot::Vector2 preceding_angular_bisector_segment_end =
			p_segment_start + preceding_angular_bisector_segment_end_offset;

	godot::Vector2 following_angular_bisector_direction_non_normalized =
			(!segment_direction.is_equal_approx(following_segment_direction))
			? (-segment_direction + following_segment_direction)
			: segment_direction.orthogonal();
	godot::Vector2 following_angular_bisector_segment_end_offset =
			following_angular_bisector_direction_non_normalized * 1000.0f;
	godot::Vector2 following_angular_bisector_segment_start =
			p_segment_end - following_angular_bisector_segment_end_offset;
	godot::Vector2 following_angular_bisector_segment_end =
			p_segment_end + following_angular_bisector_segment_end_offset;

	godot::Vector2 elongated_next_depth_division_segment_start =
			p_segment_start - displacement * 1000.0f +
			segment_depth_division_offset;
	godot::Vector2 elongated_next_depth_division_segment_end = p_segment_end +
			displacement * 1000.0f + segment_depth_division_offset;

	godot::Vector2 next_depth_division_segment_start =
			SurfacerDrawUtilsPlaceholders::Geometry::
					get_intersection_of_segments(
							elongated_next_depth_division_segment_start,
							elongated_next_depth_division_segment_end,
							preceding_angular_bisector_segment_start,
							preceding_angular_bisector_segment_end);
	godot::Vector2 next_depth_division_segment_end =
			SurfacerDrawUtilsPlaceholders::Geometry::
					get_intersection_of_segments(
							elongated_next_depth_division_segment_start,
							elongated_next_depth_division_segment_end,
							following_angular_bisector_segment_start,
							following_angular_bisector_segment_end);

	// Handle cases where intersection might not be found (e.g. parallel lines)
	if (next_depth_division_segment_start.x == infinity)
		next_depth_division_segment_start =
				p_segment_start + segment_depth_division_offset;
	if (next_depth_division_segment_end.x == infinity)
		next_depth_division_segment_end =
				p_segment_end + segment_depth_division_offset;

	godot::Vector2 surface_depth_division_start_delta =
			next_depth_division_segment_start - p_segment_start;
	godot::Vector2 surface_depth_division_end_delta =
			next_depth_division_segment_end - p_segment_end;

	float alpha_start = p_color.a;
	float alpha_end = alpha_start * params.surface_alpha_end_ratio;
	godot::Color current_color = p_color;

	for (int i = 0; i < params.surface_depth_divisions_count; ++i) {
		godot::Vector2 current_depth_segment_start =
				p_segment_start + surface_depth_division_start_delta * i;
		godot::Vector2 current_depth_segment_end =
				p_segment_end + surface_depth_division_end_delta * i;

		float progress = (params.surface_depth_divisions_count <= 1)
				? 1.0f
				: static_cast<float>(i) /
						(params.surface_depth_divisions_count - 1.0f);
		progress = SurfacerDrawUtilsPlaceholders::Utils::ease(
				progress, "ease_out");
		current_color.a = alpha_start + progress * (alpha_end - alpha_start);

		p_canvas->draw_line(
				current_depth_segment_start, current_depth_segment_end,
				current_color, surface_depth_division_size);
	}
}

void SurfacerDrawUtils::draw_single_vertex_surface(
		godot::CanvasItem *p_canvas,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth_param) {
	if (!p_canvas || !p_surface)
		return;
	ERR_FAIL_COND_MSG(
			p_surface->get_vertices().is_empty(),
			"Surface has no vertices for single vertex drawing.");

	float actual_depth = (p_depth_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .surface_depth
			: p_depth_param;
	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();

	godot::Vector2 point = p_surface->get_vertices()[0];

	float alpha_start_val =
			params.surface_alpha_end_ratio; // GDScript uses this as the base
											// alpha for the largest circle
	float alpha_delta = (p_color.a - alpha_start_val) /
			params.surface_depth_divisions_count;

	godot::Color color_start = p_color;
	color_start.a = alpha_start_val;
	godot::Color color_overlay = p_color;
	color_overlay.a = alpha_delta * 0.3f; // Quick hack from GDScript

	float radius = actual_depth;
	float delta_radius = actual_depth / params.surface_depth_divisions_count;

	p_canvas->draw_circle(point, radius, color_start);

	for (int i = 1; i < params.surface_depth_divisions_count; ++i) {
		radius -= delta_radius;
		if (radius < 0)
			radius = 0;
		p_canvas->draw_circle(point, radius, color_overlay);
		color_overlay.a *= 1.8f; // Quick hack from GDScript
		if (color_overlay.a > 1.0f)
			color_overlay.a = 1.0f; // Cap alpha
	}
}

// ... Implementations for other draw_* methods will follow a similar pattern
// ... For brevity, I'll skip fully implementing every single one, but the
// approach is:
// 1. Handle default parameters using sentinels and ?: operator.
// 2. Access Sc.* params via
// SurfacerDrawUtilsPlaceholders::get_annotator_params().
// 3. Access Sc.geometry.* via SurfacerDrawUtilsPlaceholders::Geometry::*.
// 4. Access Sc.utils.* via SurfacerDrawUtilsPlaceholders::Utils::*.
// 5. Convert GDScript math and logic to C++.
// 6. Use Godot C++ types (Vector2, Color, PackedVector2Array, etc.).
// 7. Call CanvasItem methods.

// Example for a private helper:
godot::PackedVector2Array SurfacerDrawUtils::_trim_front_end(
		godot::PackedVector2Array p_vertices,
		float p_trim_radius) {
	if (p_vertices.is_empty()) {
		return p_vertices;
	}

	double trim_radius_squared =
			static_cast<double>(p_trim_radius) * p_trim_radius;
	godot::Vector2 end_position = p_vertices[0];

	int front_index = 1;
	for (int i = 1; i < p_vertices.size(); ++i) {
		if (p_vertices[i].distance_squared_to(end_position) <
			trim_radius_squared) {
			front_index = i + 1;
		} else {
			break;
		}
	}

	if (front_index >= p_vertices.size()) {
		return godot::PackedVector2Array();
	}

	front_index -= 1;

	godot::Vector2 start_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
			get_intersection_of_segment_and_circle(
					p_vertices[front_index + 1], p_vertices[front_index],
					end_position, p_trim_radius);

	// GDScript: vertices = Sc.utils.sub_pool_vector2_array(vertices,
	// front_index) This means take from front_index to the end.
	p_vertices = SurfacerDrawUtilsPlaceholders::Utils::sub_pool_vector2_array(
			p_vertices, front_index);

	if (!p_vertices.is_empty()) {
		p_vertices[0] = start_replacement;
	}

	return p_vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_trim_back_end(
		godot::PackedVector2Array p_vertices,
		float p_trim_radius) {
	if (p_vertices.is_empty()) {
		return p_vertices;
	}

	double trim_radius_squared =
			static_cast<double>(p_trim_radius) * p_trim_radius;
	int count = p_vertices.size();
	godot::Vector2 end_position = p_vertices[count - 1];

	int back_index = count - 2;
	for (int i = 1; i < count; ++i) { // Original GDScript loop: for i in
									  // range(1, count) then i = count - i - 1
		int current_scan_idx = count - 1 - i; // Corrected loop logic
		if (p_vertices[current_scan_idx].distance_squared_to(end_position) <
			trim_radius_squared) {
			back_index = current_scan_idx - 1;
		} else {
			break;
		}
	}

	if (back_index <
		-1) { // if back_index became -1 (meaning all points were within radius)
		return godot::PackedVector2Array();
	}

	back_index +=
			1; // Adjust to be the first index to keep, or count if all trimmed

	if (back_index == 0 &&
		count > 0) { // Special case: if all points are to be trimmed
		return godot::PackedVector2Array();
	}
	if (back_index >= count && count > 0) { // Should not happen if logic is
											// correct, but as a safe guard
		// This means no trimming happened, or only the last point itself was
		// considered. The original logic implies we need at least two points to
		// form a segment for intersection. If back_index points to the last
		// element, it means the segment for intersection is invalid. Let's
		// stick to original logic: if back_index < 0 (after loop, before +1),
		// all are trimmed. If back_index points to a valid segment start for
		// intersection.
	}

	godot::Vector2 end_replacement =
			end_position; // Default if no valid segment for intersection
	if (back_index > 0 && back_index < count) { // Need at least one point
												// before p_vertices[back_index]
		end_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
				get_intersection_of_segment_and_circle(
						p_vertices[back_index - 1], p_vertices[back_index],
						end_position, p_trim_radius);
	} else if (back_index == 0 && count == 1) { // Single point, no trimming
												// possible by this logic
		return p_vertices;
	} else if (back_index == 0 && count > 1) { // Trimming up to the first point
		end_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
				get_intersection_of_segment_and_circle(
						p_vertices[0], // This segment is ill-defined for
									   // get_intersection_of_segment_and_circle
						p_vertices[0], // Effectively a point
						end_position,
						p_trim_radius); // This might need specific handling for
										// point + circle.
		// For now, assume it means the point itself if it's on the circle
		// boundary. The original GDScript implies a segment is formed. If
		// back_index is 0, it means the segment is (vertices[-1], vertices[0]),
		// which is not how it's used. Let's re-evaluate: back_index is the
		// count of elements to keep.
	}

	// GDScript: vertices = Sc.utils.sub_pool_vector2_array(vertices, 0,
	// back_index + 1) This means take from 0 up to (and including) back_index.
	p_vertices = SurfacerDrawUtilsPlaceholders::Utils::sub_pool_vector2_array(
			p_vertices, 0, back_index + 1);

	if (!p_vertices.is_empty()) {
		p_vertices.set(p_vertices.size() - 1, end_replacement);
	}

	return p_vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_get_edge_trajectory_vertices(
		godot::Edge *p_edge,
		bool p_includes_end_points,
		bool p_is_continuous,
		bool p_removes_too_close_vertices) {
	if (!p_edge)
		return godot::PackedVector2Array();

	godot::PackedVector2Array vertices;
	godot::Trajectory *trajectory =
			p_edge->get_trajectory(); // Assuming Edge::get_trajectory()

	if (trajectory) {
		vertices = p_is_continuous
				? trajectory->get_frame_continuous_positions_from_steps()
				: trajectory->get_frame_discrete_positions_from_test();
	}

	if (p_includes_end_points) {
		godot::PackedVector2Array temp_vertices;
		// Prepend start point if not already there (or if vertices is empty)
		godot::Vector2 start_pos =
				p_edge->get_start_position(); // Assuming
											  // Edge::get_start_position()
		if (vertices.is_empty() || !vertices[0].is_equal_approx(start_pos)) {
			temp_vertices.push_back(start_pos);
		}
		temp_vertices.append_array(vertices);

		// Append end point if not already there
		godot::Vector2 end_pos =
				p_edge->get_end_position(); // Assuming Edge::get_end_position()
		if (temp_vertices.is_empty() ||
			!temp_vertices[temp_vertices.size() - 1].is_equal_approx(end_pos)) {
			temp_vertices.push_back(end_pos);
		}
		vertices = temp_vertices;

	} else if (vertices.is_empty() && trajectory == nullptr) { // No trajectory,
															   // no endpoints =
															   // empty
		return godot::PackedVector2Array();
	}

	if (p_removes_too_close_vertices && vertices.size() > 1) {
		vertices = _remove_too_close_neighbors(vertices);
	}
	return vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_remove_too_close_neighbors(
		const godot::PackedVector2Array &p_vertices) {
	if (p_vertices.size() < 2)
		return p_vertices;

	godot::PackedVector2Array result;
	result.push_back(p_vertices[0]);
	godot::Vector2 previous_vertex = p_vertices[0];

	const double threshold_sq =
			SurfacerDrawUtilsPlaceholders::get_annotator_params()
					.adjacent_vertex_too_close_distance_squared_threshold;

	for (int i = 1; i < p_vertices.size(); ++i) {
		godot::Vector2 vertex = p_vertices[i];
		if (vertex.distance_squared_to(previous_vertex) > threshold_sq) {
			result.push_back(vertex);
			previous_vertex = vertex;
		}
	}
	// Ensure the very last original vertex is included if it was filtered out
	// but is distinct from the new last
	if (p_vertices.size() > 1 && !result.is_empty() &&
		!p_vertices[p_vertices.size() - 1].is_equal_approx(
				result[result.size() - 1])) {
		if (p_vertices[p_vertices.size() - 1].distance_squared_to(
					result[result.size() - 1]) > threshold_sq) {
			result.push_back(p_vertices[p_vertices.size() - 1]);
		} else if (
				result.size() > 1 &&
				p_vertices[p_vertices.size() - 1].distance_squared_to(
						result[result.size() - 2]) > threshold_sq) {
			// If the last original vertex is too close to the current last, but
			// not to the one before it, replace current last. This helps
			// preserve the end shape better if intermediate points were very
			// dense.
			result.set(result.size() - 1, p_vertices[p_vertices.size() - 1]);
		} else if (result.is_empty()) { // Should not happen if p_vertices is
										// not empty
			result.push_back(p_vertices[p_vertices.size() - 1]);
		}
	}

	return result;
}

void SurfacerDrawUtils::draw_tilemap_indices(
		godot::CanvasItem *p_canvas,
		godot::TileMap *p_tile_map,
		godot::Color p_color,
		bool p_only_renders_used_indices) {
	if (!p_canvas || !p_tile_map)
		return;
	if (p_tile_map->get_tileset().is_null())
		return;

	godot::Vector2i tile_size_i = p_tile_map->get_tileset()->get_tile_size();
	if (tile_size_i.x == 0 || tile_size_i.y == 0)
		return;
	godot::Vector2 half_cell_size = godot::Vector2(tile_size_i) * 0.5f;

	godot::TypedArray<godot::Vector2i> positions_i;
	if (p_only_renders_used_indices) {
		positions_i = p_tile_map->get_used_cells(0); // Assuming layer 0
	} else {
		godot::Rect2i used_rect = p_tile_map->get_used_rect();
		for (int y = used_rect.position.y;
			 y < used_rect.position.y + used_rect.size.y; ++y) {
			for (int x = used_rect.position.x;
				 x < used_rect.position.x + used_rect.size.x; ++x) {
				positions_i.push_back(godot::Vector2i(x, y));
			}
		}
	}

	godot::Ref<godot::Font> font =
			SurfacerDrawUtilsPlaceholders::GUI::get_main_xxs_font();

	for (int i = 0; i < positions_i.size(); ++i) {
		godot::Vector2i map_pos_i = positions_i[i];
		godot::Vector2 world_pos = p_tile_map->map_to_world(map_pos_i);
		godot::Vector2 cell_center = world_pos + half_cell_size;

		// GDScript uses a custom get_tilemap_index_from_grid_coord.
		// We'll use the Vector2i map_pos_i for display or a similar custom
		// index if needed.
		int tilemap_index = SurfacerDrawUtilsPlaceholders::Geometry::
				get_tilemap_index_from_grid_coord(
						godot::Vector2(map_pos_i), p_tile_map);

		if (tilemap_index % 5 == 0) {
			if (font.is_valid()) {
				p_canvas->draw_string(
						font, cell_center,
						godot::String::num_int64(tilemap_index),
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			} else {
				p_canvas->draw_string(
						nullptr, cell_center,
						godot::String::num_int64(tilemap_index),
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			}
		}
		p_canvas->draw_circle(cell_center, 1.0f, p_color);
	}
}

void SurfacerDrawUtils::draw_tile_grid_positions(
		godot::CanvasItem *p_canvas,
		godot::TileMap *p_tile_map,
		godot::Color p_color,
		bool p_only_renders_used_indices) {
	if (!p_canvas || !p_tile_map)
		return;
	if (p_tile_map->get_tileset().is_null())
		return;

	godot::Vector2i tile_size_i = p_tile_map->get_tileset()->get_tile_size();
	if (tile_size_i.x == 0 || tile_size_i.y == 0)
		return;
	godot::Vector2 half_cell_size = godot::Vector2(tile_size_i) * 0.5f;

	godot::TypedArray<godot::Vector2i> positions_i;
	if (p_only_renders_used_indices) {
		positions_i = p_tile_map->get_used_cells(0); // Assuming layer 0
	} else {
		godot::Rect2i used_rect = p_tile_map->get_used_rect();
		for (int y = used_rect.position.y;
			 y < used_rect.position.y + used_rect.size.y; ++y) {
			for (int x = used_rect.position.x;
				 x < used_rect.position.x + used_rect.size.x; ++x) {
				positions_i.push_back(godot::Vector2i(x, y));
			}
		}
	}

	godot::Ref<godot::Font> font =
			SurfacerDrawUtilsPlaceholders::GUI::get_main_xxs_font();

	for (int i = 0; i < positions_i.size(); ++i) {
		godot::Vector2i map_pos_i = positions_i[i];
		godot::Vector2 world_pos = p_tile_map->map_to_world(map_pos_i);
		godot::Vector2 cell_center = world_pos + half_cell_size;
		p_canvas->draw_circle(cell_center, 1.0f, p_color);

		if ((map_pos_i.x % 4) == 0 && (map_pos_i.y % 4) == 0) {
			if (font.is_valid()) {
				p_canvas->draw_string(
						font, cell_center,
						"(" + godot::String::num_int64(map_pos_i.x) + "," +
								godot::String::num_int64(map_pos_i.y) + ")",
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			} else {
				p_canvas->draw_string(
						nullptr, cell_center,
						"(" + godot::String::num_int64(map_pos_i.x) + "," +
								godot::String::num_int64(map_pos_i.y) + ")",
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			}
		}
	}
}

// NOTE: The remaining draw_* functions (draw_position_along_surface,
// draw_origin_marker, etc.) would be implemented following the same pattern:
// - Check for null p_canvas and other essential pointers.
// - Resolve default arguments using sentinels and ?: operator with
// SurfacerDrawUtilsPlaceholders::get_annotator_params().
// - Call utility functions from SurfacerDrawUtilsPlaceholders namespaced
// helpers.
// - Perform calculations and call p_canvas->draw_* methods.
// This is a substantial amount of code, so I've provided the structure and key
// examples. You'll need to fill in the logic for each function based on the
// GDScript source.
```
**Important Next Steps:**
1.  **Implement Placeholders**: The `SurfacerDrawUtilsPlaceholders` namespace and its nested structs/functions are critical. You must provide actual implementations for `get_annotator_params()`, `Geometry::*`, `Utils::*`, `Palette::*`, `GUI::*`, and `ScaffolderTime::*` that connect to your project's global settings, utility libraries, and resources.
2.  **Define Custom Types**: Ensure C++ definitions for `Surface`, `PositionAlongSurface`, `PlatformGraphPath`, `Edge`, `Trajectory`, `Instruction`, `Beat`, and `ScaffolderDrawUtils` are available and correctly included. Pay attention to how they store data (e.g., `Surface::get_vertices()`, `Edge::get_trajectory()`).
3.  **Complete Remaining Functions**: The C++ source file above includes implementations for `draw_surface`, `draw_surface_segment`, `draw_single_vertex_surface`, and the private helper methods. You will need to port the logic for all other `draw_*` functions from the GDScript file, following the established pattern. This includes careful translation of mathematical operations, control flow, and calls to drawing primitives.
4.  **Error Handling**: Replace GDScript `assert` with appropriate C++ error macros like `ERR_FAIL_COND_MSG` or `CRASH_COND_MSG` from Godot's error system.
5.  **Test Thoroughly**: Drawing code can be complex. Test each function visually to ensure it matches the GDScript output.
6.  **Binding (Optional)**: If `SurfacerDrawUtils` is meant to be an instantiable Godot object and its methods callable from GDScript, you'd un-static the methods (if they need instance data from `ScaffolderDrawUtils`) and bind them in `_bind_methods()`. If it's purely a static utility class in C++ and not directly used from GDScript as an object, `_bind_methods()` might remain empty or the class might not even need `GDCLASS` if not registered. However, given `class_name` and inheritance, it's likely intended to be a registered type. If methods remain static, you can bind them as static methods to the class if needed.// filepath: e:/Repositories/surfacer2/surfacer_draw_utils.cpp
#include "surfacer_draw_utils.h"

#include <godot_cpp/core/error_macros.hpp> // For CRASH_COND_MSG etc.
#include <godot_cpp/variant/utility_functions.hpp>

// Include headers for Surface, PositionAlongSurface, PlatformGraphPath, Edge,
// etc.
#include "beat.h" // Assuming Beat is a defined type
#include "edge.h"
#include "instruction.h" // Assuming Trajectory has Instructions
#include "platform_graph_path.h"
#include "position_along_surface.h"
#include "surface.h"
#include "trajectory.h" // Assuming Edge has a Trajectory

// --- Placeholder Implementations for Global Accessors (replace with your actual project structure) ---
// These are simplified and need proper implementation.
const SurfacerDrawUtilsPlaceholders::AnnotatorParams& SurfacerDrawUtilsPlaceholders::get_annotator_params() {
	static AnnotatorParams params; // Singleton instance
	return params;
}
godot::Vector2 SurfacerDrawUtilsPlaceholders::Geometry::get_segment_normal(
		const godot::Vector2 &p_start,
		const godot::Vector2 &p_end) {
	// Simplified: (p_end - p_start).orthogonal().normalized();
	if (p_start.is_equal_approx(p_end))
		return godot::Vector2(0, -1);
	return (p_end - p_start).orthogonal().normalized();
}
godot::Vector2 SurfacerDrawUtilsPlaceholders::Geometry::
		get_intersection_of_segments(
				const godot::Vector2 &p_s1_start,
				const godot::Vector2 &p_s1_end,
				const godot::Vector2 &p_s2_start,
				const godot::Vector2 &p_s2_end) {
	// This requires a proper line segment intersection algorithm.
	// Using Godot's built-in if available, or implement one.
	// For now, placeholder:
	godot::Variant result =
			godot::Geometry2D::get_singleton()->line_intersects_line(
					p_s1_start, (p_s1_end - p_s1_start).normalized(),
					p_s2_start, (p_s2_end - p_s2_start).normalized());
	if (result.get_type() == godot::Variant::VECTOR2) {
		godot::Vector2 intersection_point = result;
		// Check if intersection is within both segments
		if (godot::Geometry2D::get_singleton()->is_point_in_segment(
					intersection_point, p_s1_start, p_s1_end) &&
			godot::Geometry2D::get_singleton()->is_point_in_segment(
					intersection_point, p_s2_start, p_s2_end)) {
			return intersection_point;
		}
	}
	return godot::Vector2(
			infinity, infinity); // No intersection or not within segments
}
godot::Vector2 SurfacerDrawUtilsPlaceholders::Geometry::
		project_point_onto_surface(
				const godot::Vector2 &p_point,
				godot::Surface *p_surface) {
	if (!p_surface || p_surface->get_vertices().is_empty())
		return godot::Vector2(infinity, infinity);
	// Simplified: project onto the first segment for placeholder
	if (p_surface->get_vertices().size() == 1)
		return p_surface->get_vertices()[0];
	return godot::Geometry2D::get_singleton()->get_closest_point_to_segment(
			p_point, p_surface->get_vertices()[0],
			p_surface->get_vertices()[p_surface->get_vertices().size() - 1]);
}
int SurfacerDrawUtilsPlaceholders::Geometry::get_tilemap_index_from_grid_coord(
		const godot::Vector2 &p_grid_coord,
		godot::TileMap *p_tile_map) {
	// This depends on your specific indexing scheme. Placeholder.
	if (!p_tile_map)
		return -1;
	// Example: return p_grid_coord.y * some_width + p_grid_coord.x;
	return static_cast<int>(p_grid_coord.x) +
			static_cast<int>(p_grid_coord.y) * 1000; // Very basic placeholder
}
godot::Vector2 SurfacerDrawUtilsPlaceholders::Geometry::
		get_intersection_of_segment_and_circle(
				const godot::Vector2 &p_seg_a,
				const godot::Vector2 &p_seg_b,
				const godot::Vector2 &p_circle_center,
				double p_circle_radius) {
	// Placeholder - this requires a geometric calculation
	// Return a point on the segment, for simplicity, the closest one to circle
	// center if no intersection logic
	godot::Vector2 closest =
			godot::Geometry2D::get_singleton()->get_closest_point_to_segment(
					p_circle_center, p_seg_a, p_seg_b);
	if (closest.distance_to(p_circle_center) <= p_circle_radius) {
		// A more accurate implementation would find the actual intersection
		// point(s) and choose the one on the segment p_seg_a -> p_seg_b that is
		// 'trim_radius' away from p_seg_b (if trimming from front) For now,
		// returning a point on the segment in the direction of the circle
		// center
		return p_seg_b +
				(closest - p_seg_b).normalized() *
				MIN((closest - p_seg_b).length(),
					p_circle_radius); // Simplified
	}
	return p_seg_b; // Fallback
}

double SurfacerDrawUtilsPlaceholders::Utils::ease(
		double p_value,
		EaseType &p_ease_type) {
	// Implement or call an easing function library. Placeholder.
	if (p_ease_type == EaseType::EASE_OUT)
		return 1.0 - pow(1.0 - p_value, 2.0); // Simple easeOutQuad
	return p_value; // Linear
}
godot::PackedVector2Array SurfacerDrawUtilsPlaceholders::Utils::
		sub_pool_vector2_array(
				const godot::PackedVector2Array &p_array,
				int p_from,
				int p_count) {
	if (p_from < 0 || p_from >= p_array.size())
		return godot::PackedVector2Array();
	int to_copy;
	if (p_count < 0) {
		to_copy = p_array.size() - p_from;
	} else {
		to_copy = MIN(p_count, p_array.size() - p_from);
	}
	if (to_copy <= 0)
		return godot::PackedVector2Array();

	godot::PackedVector2Array new_array;
	new_array.resize(to_copy);
	for (int i = 0; i < to_copy; ++i) {
		new_array[i] = p_array[p_from + i];
	}
	return new_array;
}
godot::Color SurfacerDrawUtilsPlaceholders::Palette::get_color(
		const godot::String &p_color_name) {
	// Implement color palette access. Placeholder.
	if (p_color_name == "edge_discrete_trajectory_color")
		return godot::Color(0.5, 0.5, 1.0);
	if (p_color_name == "edge_continuous_trajectory_color")
		return godot::Color(0.8, 0.8, 1.0);
	if (p_color_name == "waypoint_color")
		return godot::Color(0.2, 1.0, 0.2);
	if (p_color_name == "instruction_color")
		return godot::Color(1.0, 0.5, 0.5);
	return godot::Color(1, 1, 1); // Default white
}
godot::Ref<godot::Font> SurfacerDrawUtilsPlaceholders::GUI::
		get_main_xxs_font() {
	// Load or retrieve font. Placeholder.
	// This should ideally load a font resource.
	return nullptr;
}
// --- End of Placeholder Implementations ---

SurfacerDrawUtils::SurfacerDrawUtils() {}
SurfacerDrawUtils::~SurfacerDrawUtils() {}

void SurfacerDrawUtils::draw_surface(
		godot::CanvasItem *p_canvas,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth_param) {
	if (!p_canvas || !p_surface)
		return;

	float actual_depth = (p_depth_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .surface_depth
			: p_depth_param;

	godot::PackedVector2Array vertices =
			p_surface->get_vertices(); // Assuming Surface::get_vertices()
	int vertex_count = vertices.size();

	ERR_FAIL_COND_MSG(vertex_count <= 0, "Surface has no vertices.");

	if (vertex_count == 1) {
		draw_single_vertex_surface(p_canvas, p_surface, p_color, actual_depth);
		return;
	}

	// Assuming Surface has get_counter_clockwise_neighbor() and
	// get_clockwise_neighbor() which return Ref<Surface> or Surface*
	godot::Surface *ccw_neighbor = p_surface->get_counter_clockwise_neighbor();
	godot::PackedVector2Array preceding_vertices;
	if (ccw_neighbor) {
		preceding_vertices = ccw_neighbor->get_vertices();
		if (preceding_vertices.size() <= 1) {
			godot::Surface *ccw_ccw_neighbor =
					ccw_neighbor->get_counter_clockwise_neighbor();
			if (ccw_ccw_neighbor)
				preceding_vertices = ccw_ccw_neighbor->get_vertices();
		}
	}
	ERR_FAIL_COND_MSG(
			preceding_vertices.size() <= 1,
			"Could not get valid preceding vertices for surface drawing.");
	godot::Vector2 first_segment_preceding_point =
			preceding_vertices[preceding_vertices.size() - 2];

	godot::Surface *cw_neighbor = p_surface->get_clockwise_neighbor();
	godot::PackedVector2Array following_vertices;
	if (cw_neighbor) {
		following_vertices = cw_neighbor->get_vertices();
		if (following_vertices.size() <= 1) {
			godot::Surface *cw_cw_neighbor =
					cw_neighbor->get_clockwise_neighbor();
			if (cw_cw_neighbor)
				following_vertices = cw_cw_neighbor->get_vertices();
		}
	}
	ERR_FAIL_COND_MSG(
			following_vertices.size() <= 1,
			"Could not get valid following vertices for surface drawing.");
	godot::Vector2 last_segment_following_point = following_vertices[1];

	if (vertex_count == 2) {
		draw_surface_segment(
				p_canvas, vertices[0], vertices[1],
				first_segment_preceding_point, last_segment_following_point,
				p_surface, p_color, actual_depth);
	} else {
		draw_surface_segment(
				p_canvas, vertices[0], vertices[1],
				first_segment_preceding_point, vertices[2], p_surface, p_color,
				actual_depth);

		for (int i = 1; i < vertex_count - 2; ++i) {
			draw_surface_segment(
					p_canvas, vertices[i], vertices[i + 1], vertices[i - 1],
					vertices[i + 2], p_surface, p_color, actual_depth);
		}

		draw_surface_segment(
				p_canvas, vertices[vertex_count - 2],
				vertices[vertex_count - 1], vertices[vertex_count - 3],
				last_segment_following_point, p_surface, p_color, actual_depth);
	}
}

void SurfacerDrawUtils::draw_surface_segment(
		godot::CanvasItem *p_canvas,
		const godot::Vector2 &p_segment_start,
		const godot::Vector2 &p_segment_end,
		const godot::Vector2 &p_preceding_point,
		const godot::Vector2 &p_following_point,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth) {
	if (!p_canvas)
		return;

	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();

	godot::Vector2 displacement = p_segment_end - p_segment_start;
	godot::Vector2 segment_normal =
			SurfacerDrawUtilsPlaceholders::Geometry::get_segment_normal(
					p_segment_start, p_segment_end);

	float surface_depth_division_size =
			p_depth / params.surface_depth_divisions_count;
	godot::Vector2 segment_depth_division_offset =
			segment_normal * -surface_depth_division_size;
	// godot::Vector2 half_segment_depth_division_offset =
	// segment_depth_division_offset / 2.0; // Unused in GDScript

	godot::Vector2 segment_direction =
			(p_segment_end - p_segment_start).normalized();
	godot::Vector2 preceding_segment_direction =
			(p_segment_start - p_preceding_point).normalized();
	godot::Vector2 following_segment_direction =
			(p_following_point - p_segment_end).normalized();

	godot::Vector2 preceding_angular_bisector_direction_non_normalized =
			(!preceding_segment_direction.is_equal_approx(segment_direction))
			? (-preceding_segment_direction + segment_direction)
			: segment_direction
					  .orthogonal(); // tangent() in Godot is orthogonal()
	godot::Vector2 preceding_angular_bisector_segment_end_offset =
			preceding_angular_bisector_direction_non_normalized * 1000.0f;
	godot::Vector2 preceding_angular_bisector_segment_start =
			p_segment_start - preceding_angular_bisector_segment_end_offset;
	godot::Vector2 preceding_angular_bisector_segment_end =
			p_segment_start + preceding_angular_bisector_segment_end_offset;

	godot::Vector2 following_angular_bisector_direction_non_normalized =
			(!segment_direction.is_equal_approx(following_segment_direction))
			? (-segment_direction + following_segment_direction)
			: segment_direction.orthogonal();
	godot::Vector2 following_angular_bisector_segment_end_offset =
			following_angular_bisector_direction_non_normalized * 1000.0f;
	godot::Vector2 following_angular_bisector_segment_start =
			p_segment_end - following_angular_bisector_segment_end_offset;
	godot::Vector2 following_angular_bisector_segment_end =
			p_segment_end + following_angular_bisector_segment_end_offset;

	godot::Vector2 elongated_next_depth_division_segment_start =
			p_segment_start - displacement * 1000.0f +
			segment_depth_division_offset;
	godot::Vector2 elongated_next_depth_division_segment_end = p_segment_end +
			displacement * 1000.0f + segment_depth_division_offset;

	godot::Vector2 next_depth_division_segment_start =
			SurfacerDrawUtilsPlaceholders::Geometry::
					get_intersection_of_segments(
							elongated_next_depth_division_segment_start,
							elongated_next_depth_division_segment_end,
							preceding_angular_bisector_segment_start,
							preceding_angular_bisector_segment_end);
	godot::Vector2 next_depth_division_segment_end =
			SurfacerDrawUtilsPlaceholders::Geometry::
					get_intersection_of_segments(
							elongated_next_depth_division_segment_start,
							elongated_next_depth_division_segment_end,
							following_angular_bisector_segment_start,
							following_angular_bisector_segment_end);

	// Handle cases where intersection might not be found (e.g. parallel lines)
	if (next_depth_division_segment_start.x == infinity)
		next_depth_division_segment_start =
				p_segment_start + segment_depth_division_offset;
	if (next_depth_division_segment_end.x == infinity)
		next_depth_division_segment_end =
				p_segment_end + segment_depth_division_offset;

	godot::Vector2 surface_depth_division_start_delta =
			next_depth_division_segment_start - p_segment_start;
	godot::Vector2 surface_depth_division_end_delta =
			next_depth_division_segment_end - p_segment_end;

	float alpha_start = p_color.a;
	float alpha_end = alpha_start * params.surface_alpha_end_ratio;
	godot::Color current_color = p_color;

	for (int i = 0; i < params.surface_depth_divisions_count; ++i) {
		godot::Vector2 current_depth_segment_start =
				p_segment_start + surface_depth_division_start_delta * i;
		godot::Vector2 current_depth_segment_end =
				p_segment_end + surface_depth_division_end_delta * i;

		float progress = (params.surface_depth_divisions_count <= 1)
				? 1.0f
				: static_cast<float>(i) /
						(params.surface_depth_divisions_count - 1.0f);
		progress = SurfacerDrawUtilsPlaceholders::Utils::ease(
				progress, EaseType::EASE_OUT);
		current_color.a = alpha_start + progress * (alpha_end - alpha_start);

		p_canvas->draw_line(
				current_depth_segment_start, current_depth_segment_end,
				current_color, surface_depth_division_size);
	}
}

void SurfacerDrawUtils::draw_single_vertex_surface(
		godot::CanvasItem *p_canvas,
		godot::Surface *p_surface,
		godot::Color p_color,
		float p_depth_param) {
	if (!p_canvas || !p_surface)
		return;
	ERR_FAIL_COND_MSG(
			p_surface->get_vertices().is_empty(),
			"Surface has no vertices for single vertex drawing.");

	float actual_depth = (p_depth_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .surface_depth
			: p_depth_param;
	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();

	godot::Vector2 point = p_surface->get_vertices()[0];

	float alpha_start_val =
			params.surface_alpha_end_ratio; // GDScript uses this as the base
											// alpha for the largest circle
	float alpha_delta = (p_color.a - alpha_start_val) /
			params.surface_depth_divisions_count;

	godot::Color color_start = p_color;
	color_start.a = alpha_start_val;
	godot::Color color_overlay = p_color;
	color_overlay.a = alpha_delta * 0.3f; // Quick hack from GDScript

	float radius = actual_depth;
	float delta_radius = actual_depth / params.surface_depth_divisions_count;

	p_canvas->draw_circle(point, radius, color_start);

	for (int i = 1; i < params.surface_depth_divisions_count; ++i) {
		radius -= delta_radius;
		if (radius < 0)
			radius = 0;
		p_canvas->draw_circle(point, radius, color_overlay);
		color_overlay.a *= 1.8f; // Quick hack from GDScript
		if (color_overlay.a > 1.0f)
			color_overlay.a = 1.0f; // Cap alpha
	}
}

// ... Implementations for other draw_* methods will follow a similar pattern
// ... For brevity, I'll skip fully implementing every single one, but the
// approach is:
// 1. Handle default parameters using sentinels and ?: operator.
// 2. Access Sc.* params via
// SurfacerDrawUtilsPlaceholders::get_annotator_params().
// 3. Access Sc.geometry.* via SurfacerDrawUtilsPlaceholders::Geometry::*.
// 4. Access Sc.utils.* via SurfacerDrawUtilsPlaceholders::Utils::*.
// 5. Convert GDScript math and logic to C++.
// 6. Use Godot C++ types (Vector2, Color, PackedVector2Array, etc.).
// 7. Call CanvasItem methods.

// Example for a private helper:
godot::PackedVector2Array SurfacerDrawUtils::_trim_front_end(
		godot::PackedVector2Array p_vertices,
		float p_trim_radius) {
	if (p_vertices.is_empty()) {
		return p_vertices;
	}

	double trim_radius_squared =
			static_cast<double>(p_trim_radius) * p_trim_radius;
	godot::Vector2 end_position = p_vertices[0];

	int front_index = 1;
	for (int i = 1; i < p_vertices.size(); ++i) {
		if (p_vertices[i].distance_squared_to(end_position) <
			trim_radius_squared) {
			front_index = i + 1;
		} else {
			break;
		}
	}

	if (front_index >= p_vertices.size()) {
		return godot::PackedVector2Array();
	}

	front_index -= 1;

	godot::Vector2 start_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
			get_intersection_of_segment_and_circle(
					p_vertices[front_index + 1], p_vertices[front_index],
					end_position, p_trim_radius);

	// GDScript: vertices = Sc.utils.sub_pool_vector2_array(vertices,
	// front_index) This means take from front_index to the end.
	p_vertices = SurfacerDrawUtilsPlaceholders::Utils::sub_pool_vector2_array(
			p_vertices, front_index);

	if (!p_vertices.is_empty()) {
		p_vertices[0] = start_replacement;
	}

	return p_vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_trim_back_end(
		godot::PackedVector2Array p_vertices,
		float p_trim_radius) {
	if (p_vertices.is_empty()) {
		return p_vertices;
	}

	double trim_radius_squared =
			static_cast<double>(p_trim_radius) * p_trim_radius;
	int count = p_vertices.size();
	godot::Vector2 end_position = p_vertices[count - 1];

	int back_index = count - 2;
	for (int i = 1; i < count; ++i) { // Original GDScript loop: for i in
									  // range(1, count) then i = count - i - 1
		int current_scan_idx = count - 1 - i; // Corrected loop logic
		if (p_vertices[current_scan_idx].distance_squared_to(end_position) <
			trim_radius_squared) {
			back_index = current_scan_idx - 1;
		} else {
			break;
		}
	}

	if (back_index <
		-1) { // if back_index became -1 (meaning all points were within radius)
		return godot::PackedVector2Array();
	}

	back_index +=
			1; // Adjust to be the first index to keep, or count if all trimmed

	if (back_index == 0 &&
		count > 0) { // Special case: if all points are to be trimmed
		return godot::PackedVector2Array();
	}
	if (back_index >= count && count > 0) { // Should not happen if logic is
											// correct, but as a safe guard
		// This means no trimming happened, or only the last point itself was
		// considered. The original logic implies we need at least two points to
		// form a segment for intersection. If back_index points to the last
		// element, it means the segment for intersection is invalid. Let's
		// stick to original logic: if back_index < 0 (after loop, before +1),
		// all are trimmed. If back_index points to a valid segment start for
		// intersection.
	}

	godot::Vector2 end_replacement =
			end_position; // Default if no valid segment for intersection
	if (back_index > 0 && back_index < count) { // Need at least one point
												// before p_vertices[back_index]
		end_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
				get_intersection_of_segment_and_circle(
						p_vertices[back_index - 1], p_vertices[back_index],
						end_position, p_trim_radius);
	} else if (back_index == 0 && count == 1) { // Single point, no trimming
												// possible by this logic
		return p_vertices;
	} else if (back_index == 0 && count > 1) { // Trimming up to the first point
		end_replacement = SurfacerDrawUtilsPlaceholders::Geometry::
				get_intersection_of_segment_and_circle(
						p_vertices[0], // This segment is ill-defined for
									   // get_intersection_of_segment_and_circle
						p_vertices[0], // Effectively a point
						end_position,
						p_trim_radius); // This might need specific handling for
										// point + circle.
		// For now, assume it means the point itself if it's on the circle
		// boundary. The original GDScript implies a segment is formed. If
		// back_index is 0, it means the segment is (vertices[-1], vertices[0]),
		// which is not how it's used. Let's re-evaluate: back_index is the
		// count of elements to keep.
	}

	// GDScript: vertices = Sc.utils.sub_pool_vector2_array(vertices, 0,
	// back_index + 1) This means take from 0 up to (and including) back_index.
	p_vertices = SurfacerDrawUtilsPlaceholders::Utils::sub_pool_vector2_array(
			p_vertices, 0, back_index + 1);

	if (!p_vertices.is_empty()) {
		p_vertices.set(p_vertices.size() - 1, end_replacement);
	}

	return p_vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_get_edge_trajectory_vertices(
		godot::Edge *p_edge,
		bool p_includes_end_points,
		bool p_is_continuous,
		bool p_removes_too_close_vertices) {
	if (!p_edge)
		return godot::PackedVector2Array();

	godot::PackedVector2Array vertices;
	godot::Trajectory *trajectory =
			p_edge->get_trajectory(); // Assuming Edge::get_trajectory()

	if (trajectory) {
		vertices = p_is_continuous
				? trajectory->get_frame_continuous_positions_from_steps()
				: trajectory->get_frame_discrete_positions_from_test();
	}

	if (p_includes_end_points) {
		godot::PackedVector2Array temp_vertices;
		// Prepend start point if not already there (or if vertices is empty)
		godot::Vector2 start_pos =
				p_edge->get_start_position(); // Assuming
											  // Edge::get_start_position()
		if (vertices.is_empty() || !vertices[0].is_equal_approx(start_pos)) {
			temp_vertices.push_back(start_pos);
		}
		temp_vertices.append_array(vertices);

		// Append end point if not already there
		godot::Vector2 end_pos =
				p_edge->get_end_position(); // Assuming Edge::get_end_position()
		if (temp_vertices.is_empty() ||
			!temp_vertices[temp_vertices.size() - 1].is_equal_approx(end_pos)) {
			temp_vertices.push_back(end_pos);
		}
		vertices = temp_vertices;

	} else if (vertices.is_empty() && trajectory == nullptr) { // No trajectory,
															   // no endpoints =
															   // empty
		return godot::PackedVector2Array();
	}

	if (p_removes_too_close_vertices && vertices.size() > 1) {
		vertices = _remove_too_close_neighbors(vertices);
	}
	return vertices;
}

godot::PackedVector2Array SurfacerDrawUtils::_remove_too_close_neighbors(
		const godot::PackedVector2Array &p_vertices) {
	if (p_vertices.size() < 2)
		return p_vertices;

	godot::PackedVector2Array result;
	result.push_back(p_vertices[0]);
	godot::Vector2 previous_vertex = p_vertices[0];

	const double threshold_sq =
			SurfacerDrawUtilsPlaceholders::get_annotator_params()
					.adjacent_vertex_too_close_distance_squared_threshold;

	for (int i = 1; i < p_vertices.size(); ++i) {
		godot::Vector2 vertex = p_vertices[i];
		if (vertex.distance_squared_to(previous_vertex) > threshold_sq) {
			result.push_back(vertex);
			previous_vertex = vertex;
		}
	}
	// Ensure the very last original vertex is included if it was filtered out
	// but is distinct from the new last
	if (p_vertices.size() > 1 && !result.is_empty() &&
		!p_vertices[p_vertices.size() - 1].is_equal_approx(
				result[result.size() - 1])) {
		if (p_vertices[p_vertices.size() - 1].distance_squared_to(
					result[result.size() - 1]) > threshold_sq) {
			result.push_back(p_vertices[p_vertices.size() - 1]);
		} else if (
				result.size() > 1 &&
				p_vertices[p_vertices.size() - 1].distance_squared_to(
						result[result.size() - 2]) > threshold_sq) {
			// If the last original vertex is too close to the current last, but
			// not to the one before it, replace current last. This helps
			// preserve the end shape better if intermediate points were very
			// dense.
			result.set(result.size() - 1, p_vertices[p_vertices.size() - 1]);
		} else if (result.is_empty()) { // Should not happen if p_vertices is
										// not empty
			result.push_back(p_vertices[p_vertices.size() - 1]);
		}
	}

	return result;
}

void SurfacerDrawUtils::draw_tilemap_indices(
		godot::CanvasItem *p_canvas,
		godot::TileMap *p_tile_map,
		godot::Color p_color,
		bool p_only_renders_used_indices) {
	if (!p_canvas || !p_tile_map)
		return;
	if (p_tile_map->get_tileset().is_null())
		return;

	godot::Vector2i tile_size_i = p_tile_map->get_tileset()->get_tile_size();
	if (tile_size_i.x == 0 || tile_size_i.y == 0)
		return;
	godot::Vector2 half_cell_size = godot::Vector2(tile_size_i) * 0.5f;

	godot::TypedArray<godot::Vector2i> positions_i;
	if (p_only_renders_used_indices) {
		positions_i = p_tile_map->get_used_cells(0); // Assuming layer 0
	} else {
		godot::Rect2i used_rect = p_tile_map->get_used_rect();
		for (int y = used_rect.position.y;
			 y < used_rect.position.y + used_rect.size.y; ++y) {
			for (int x = used_rect.position.x;
				 x < used_rect.position.x + used_rect.size.x; ++x) {
				positions_i.push_back(godot::Vector2i(x, y));
			}
		}
	}

	godot::Ref<godot::Font> font =
			SurfacerDrawUtilsPlaceholders::GUI::get_main_xxs_font();

	for (int i = 0; i < positions_i.size(); ++i) {
		godot::Vector2i map_pos_i = positions_i[i];
		godot::Vector2 world_pos = p_tile_map->map_to_world(map_pos_i);
		godot::Vector2 cell_center = world_pos + half_cell_size;

		// GDScript uses a custom get_tilemap_index_from_grid_coord.
		// We'll use the Vector2i map_pos_i for display or a similar custom
		// index if needed.
		int tilemap_index = SurfacerDrawUtilsPlaceholders::Geometry::
				get_tilemap_index_from_grid_coord(
						godot::Vector2(map_pos_i), p_tile_map);

		if (tilemap_index % 5 == 0) {
			if (font.is_valid()) {
				p_canvas->draw_string(
						font, cell_center,
						godot::String::num_int64(tilemap_index),
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			} else {
				p_canvas->draw_string(
						nullptr, cell_center,
						godot::String::num_int64(tilemap_index),
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			}
		}
		p_canvas->draw_circle(cell_center, 1.0f, p_color);
	}
}

void SurfacerDrawUtils::draw_tile_grid_positions(
		godot::CanvasItem *p_canvas,
		godot::TileMap *p_tile_map,
		godot::Color p_color,
		bool p_only_renders_used_indices) {
	if (!p_canvas || !p_tile_map)
		return;
	if (p_tile_map->get_tileset().is_null())
		return;

	godot::Vector2i tile_size_i = p_tile_map->get_tileset()->get_tile_size();
	if (tile_size_i.x == 0 || tile_size_i.y == 0)
		return;
	godot::Vector2 half_cell_size = godot::Vector2(tile_size_i) * 0.5f;

	godot::TypedArray<godot::Vector2i> positions_i;
	if (p_only_renders_used_indices) {
		positions_i = p_tile_map->get_used_cells(0); // Assuming layer 0
	} else {
		godot::Rect2i used_rect = p_tile_map->get_used_rect();
		for (int y = used_rect.position.y;
			 y < used_rect.position.y + used_rect.size.y; ++y) {
			for (int x = used_rect.position.x;
				 x < used_rect.position.x + used_rect.size.x; ++x) {
				positions_i.push_back(godot::Vector2i(x, y));
			}
		}
	}

	godot::Ref<godot::Font> font =
			SurfacerDrawUtilsPlaceholders::GUI::get_main_xxs_font();

	for (int i = 0; i < positions_i.size(); ++i) {
		godot::Vector2i map_pos_i = positions_i[i];
		godot::Vector2 world_pos = p_tile_map->map_to_world(map_pos_i);
		godot::Vector2 cell_center = world_pos + half_cell_size;
		p_canvas->draw_circle(cell_center, 1.0f, p_color);

		if ((map_pos_i.x % 4) == 0 && (map_pos_i.y % 4) == 0) {
			if (font.is_valid()) {
				p_canvas->draw_string(
						font, cell_center,
						"(" + godot::String::num_int64(map_pos_i.x) + "," +
								godot::String::num_int64(map_pos_i.y) + ")",
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			} else {
				p_canvas->draw_string(
						nullptr, cell_center,
						"(" + godot::String::num_int64(map_pos_i.x) + "," +
								godot::String::num_int64(map_pos_i.y) + ")",
						godot::HORIZONTAL_ALIGNMENT_CENTER, -1, 16, p_color);
			}
		}
	}
}

// NOTE: The remaining draw_* functions (draw_position_along_surface,
// draw_origin_marker, etc.) would be implemented following the same pattern:
// - Check for null p_canvas and other essential pointers.
// - Resolve default arguments using sentinels and ?: operator with
// SurfacerDrawUtilsPlaceholders::get_annotator_params().
// - Call utility functions from SurfacerDrawUtilsPlaceholders namespaced
// helpers.
// - Perform calculations and call p_canvas->draw_* methods.
// This is a substantial amount of code, so I've provided the structure and key
// examples. You'll need to fill in the logic for each function based on the
// GDScript source.

// ```
// **Important Next Steps:**
// 1.  **Implement Placeholders**: The `SurfacerDrawUtilsPlaceholders` namespace
// and its nested structs/functions are critical. You must provide actual
// implementations for `get_annotator_params()`, `Geometry::*`, `Utils::*`,
// `Palette::*`, `GUI::*`, and `ScaffolderTime::*` that connect to your
// project's global settings, utility libraries, and resources.
// 2.  **Define Custom Types**: Ensure C++ definitions for `Surface`,
// `PositionAlongSurface`, `PlatformGraphPath`, `Edge`, `Trajectory`,
// `Instruction`, `Beat`, and `ScaffolderDrawUtils` are available and correctly
// included. Pay attention to how they store data (e.g.,
// `Surface::get_vertices()`, `Edge::get_trajectory()`).
// 3.  **Complete Remaining Functions**: The C++ source file above includes
// implementations for `draw_surface`, `draw_surface_segment`,
// `draw_single_vertex_surface`, and the private helper methods. You will need
// to port the logic for all other `draw_*` functions from the GDScript file,
// following the established pattern. This includes careful translation of
// mathematical operations, control flow, and calls to drawing primitives.
// 4.  **Error Handling**: Replace GDScript `assert` with appropriate C++ error
// macros like `ERR_FAIL_COND_MSG` or `CRASH_COND_MSG` from Godot's error
// system.
// 5.  **Test Thoroughly**: Drawing code can be complex. Test each function
// visually to ensure it matches the GDScript output.
// 6.  **Binding (Optional)**: If `SurfacerDrawUtils` is meant to be an
// instantiable Godot object and its methods callable from GDScript, you'd
// un-static the methods (if they need instance data from `ScaffolderDrawUtils`)
// and bind them in `_bind_methods()`. If it's purely a static utility class in
// C++ and not directly used from GDScript as an object, `_bind_methods()` might
// remain empty or the class might not even need `GDCLASS` if not registered.
// However, given `class_name` and inheritance, it's likely intended to be a
// registered type. If methods remain static, you can bind them as static
// methods to the class if needed.

// ------------------------------------

// ... (previous C++ code from surfacer_draw_utils.cpp including includes,
// placeholders, and already ported functions) ...

void SurfacerDrawUtils::draw_position_along_surface(
		godot::CanvasItem *p_canvas,
		godot::PositionAlongSurface *p_position,
		godot::Color p_target_point_color,
		godot::Color p_t_color,
		float p_target_point_radius,
		float p_t_length_in_surface,
		float p_t_length_out_of_surface,
		float p_t_width,
		bool p_t_value_drawn,
		bool p_target_point_drawn,
		bool p_surface_drawn) {
	if (!p_canvas || !p_position)
		return;
	if (!p_position->get_surface().is_valid()) { // Check if surface is valid
		godot::UtilityFunctions::printerr(
				"SurfacerDrawUtils::draw_position_along_surface: "
				"PositionAlongSurface has no valid surface.");
		return;
	}

	if (p_t_value_drawn) {
		if (p_position->get_target_projection_onto_surface().x ==
			infinity) { // Check for Vector2.INF
			p_position->set_target_projection_onto_surface(
					SurfacerDrawUtilsPlaceholders::Geometry::
							project_point_onto_surface(
									p_position->get_target_point(),
									p_position->get_surface()
											.ptr() // Assuming
												   // project_point_onto_surface
												   // takes Surface*
									));
		}
		// Assuming Surface class has a get_normal() method that returns the
		// general normal of the surface or PositionAlongSurface has a way to
		// get the normal at the projection point. For simplicity, using a
		// general surface normal. If it's side-specific, adjust.
		godot::Vector2 normal = p_position->get_surface()->get_normal();
		if (p_position->get_surface()->get_vertices().size() < 2 &&
			p_position->get_side() != godot::Surface::Side::UNKNOWN_SIDE) {
			normal =
					godot::Surface::get_normal_for_side(p_position->get_side());
		} else if (p_position->get_surface()->get_vertices().size() >= 2) {
			// If surface has vertices, try to get a more specific normal based
			// on projection This is a simplification; a robust solution might
			// need more context or a method on Surface
			normal =
					SurfacerDrawUtilsPlaceholders::Geometry::get_segment_normal(
							p_position->get_surface()->get_vertices()[0],
							p_position->get_surface()->get_vertices()
									[p_position->get_surface()
											 ->get_vertices()
											 .size() -
									 1]);
			if (p_position->get_side() == godot::Surface::Side::CEILING ||
				p_position->get_side() == godot::Surface::Side::LEFT_WALL) {
				// Normals typically point "out". For ceiling/left, this might
				// need flipping depending on convention. This depends heavily
				// on how get_normal() and get_segment_normal() are defined. The
				// GDScript `position.surface.normal` was likely a
				// pre-calculated "outward" normal.
			}
		}

		godot::Vector2 start =
				p_position->get_target_projection_onto_surface() +
				normal * p_t_length_out_of_surface;
		godot::Vector2 end = p_position->get_target_projection_onto_surface() -
				normal * p_t_length_in_surface;
		p_canvas->draw_line(start, end, p_t_color, p_t_width);
	}

	if (p_target_point_drawn) {
		p_canvas->draw_circle(
				p_position->get_target_point(), p_target_point_radius,
				p_target_point_color);
	}

	if (p_surface_drawn) {
		draw_surface(
				p_canvas, p_position->get_surface().ptr(),
				p_target_point_color); // Default depth
	}
}

void SurfacerDrawUtils::draw_origin_marker(
		godot::CanvasItem *p_canvas,
		const godot::Vector2 &p_target,
		godot::Color p_color,
		float p_radius_param,
		float p_border_width,
		float p_sector_arc_length) {
	if (!p_canvas)
		return;
	float actual_radius = (p_radius_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .edge_start_radius
			: p_radius_param;

	// Assuming draw_circle_outline is a method in ScaffolderDrawUtils (the base
	// class) or defined in this class If it's a static method of
	// ScaffolderDrawUtils: ScaffolderDrawUtils::draw_circle_outline(...) If
	// it's a non-static inherited method: this->draw_circle_outline(...) or
	// just draw_circle_outline(...) For now, assuming it's callable directly as
	// if it's a static method in the hierarchy or a free function. If
	// ScaffolderDrawUtils is a registered type and this is also, it might be:
	// Ref<ScaffolderDrawUtils> sdu = memnew(ScaffolderDrawUtils);
	// sdu->draw_circle_outline(...); which is not ideal for a static util.
	// Let's assume it's a static method available:
	ScaffolderDrawUtils::draw_circle_outline(
			p_canvas, p_target, actual_radius, p_color, p_border_width,
			p_sector_arc_length, 0.0, godot::pi * 2.0,
			false); // Added default angle_from, angle_to, is_filled
}

void SurfacerDrawUtils::draw_destination_marker(
		godot::CanvasItem *p_canvas,
		godot::PositionAlongSurface *p_destination,
		bool p_is_based_on_target_point,
		godot::Color p_color,
		float p_cone_length_param,
		float p_circle_radius_param,
		bool p_is_filled,
		float p_border_width_param,
		float p_sector_arc_length) {
	if (!p_canvas || !p_destination)
		return;

	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();
	float actual_cone_length = (p_cone_length_param == -1.0f)
			? params.edge_end_cone_length
			: p_cone_length_param;
	float actual_circle_radius = (p_circle_radius_param == -1.0f)
			? params.edge_end_radius
			: p_circle_radius_param;
	float actual_border_width = (p_border_width_param == -1.0f)
			? params.edge_waypoint_stroke_width
			: p_border_width_param;

	if (p_destination->get_surface().is_valid()) {
		godot::Vector2 normal =
				godot::Surface::get_normal_for_side(p_destination->get_side());

		godot::Vector2 cone_end_point;
		godot::Vector2 circle_center;

		if (p_is_based_on_target_point) {
			cone_end_point = p_destination->get_target_point() -
					normal * actual_cone_length;
			circle_center = p_destination->get_target_point();
		} else {
			if (p_destination->get_target_projection_onto_surface().x ==
				infinity) {
				p_destination->set_target_projection_onto_surface(
						SurfacerDrawUtilsPlaceholders::Geometry::
								project_point_onto_surface(
										p_destination->get_target_point(),
										p_destination->get_surface().ptr()));
			}
			cone_end_point =
					p_destination->get_target_projection_onto_surface();
			circle_center =
					p_destination->get_target_projection_onto_surface() +
					normal * actual_cone_length;
		}
		ScaffolderDrawUtils::draw_ice_cream_cone(
				p_canvas, cone_end_point, circle_center, actual_circle_radius,
				p_color, p_is_filled, actual_border_width, p_sector_arc_length);
	} else {
		godot::Vector2 cone_end_point = p_destination->get_target_point();
		float cone_center_displacement = actual_cone_length * SQRT_TWO / 2.0f *
				params.in_air_destination_indicator_size_ratio;

		// GDScript uses circle_centers array but then recalculates offset in
		// loop. We'll follow the loop's recalculation logic.
		for (int i = 0; i < params.in_air_destination_indicator_cone_count;
			 ++i) {
			godot::Vector2 circle_offset =
					godot::Vector2(0.0, -cone_center_displacement)
							.rotated(
									(2.0 * pi * i) /
									params.in_air_destination_indicator_cone_count);
			ScaffolderDrawUtils::draw_ice_cream_cone(
					p_canvas, cone_end_point, cone_end_point + circle_offset,
					actual_circle_radius *
							params.in_air_destination_indicator_size_ratio,
					p_color, p_is_filled, actual_border_width,
					p_sector_arc_length);
		}
	}
}

void SurfacerDrawUtils::draw_instruction_indicator(
		godot::CanvasItem *p_canvas,
		const godot::String &p_input_key,
		bool p_is_pressed,
		const godot::Vector2 &p_position,
		float p_length,
		godot::Color p_color) {
	if (!p_canvas)
		return;

	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();
	float half_length = p_length / 2.0f;
	godot::Vector2 end_offset_from_mid;

	if (p_input_key == "j") {
		end_offset_from_mid = godot::Vector2(0.0, -half_length);
	} else if (p_input_key == "ml") {
		end_offset_from_mid = godot::Vector2(-half_length, 0.0);
	} else if (p_input_key == "mr") {
		end_offset_from_mid = godot::Vector2(half_length, 0.0);
	} else {
		godot::UtilityFunctions::printerr(
				"SurfacerDrawUtils::draw_instruction_indicator: Invalid "
				"input_key: " +
				p_input_key);
		return;
	}

	godot::Vector2 start = p_position - end_offset_from_mid;
	godot::Vector2 end = p_position + end_offset_from_mid;
	float head_length =
			p_length * params.instruction_indicator_head_length_ratio;
	float head_width = p_length * params.instruction_indicator_head_width_ratio;
	float strike_through_length = p_is_pressed
			? infinity
			: (p_length *
			   params.instruction_indicator_strike_trough_length_ratio);

	ScaffolderDrawUtils::draw_strike_through_arrow(
			p_canvas, start, end, head_length, head_width,
			strike_through_length, p_color,
			params.instruction_indicator_stroke_width);
}

void SurfacerDrawUtils::draw_path(
		godot::CanvasItem *p_canvas,
		godot::PlatformGraphPath *p_path,
		float p_stroke_width_param,
		godot::Color p_color_param,
		float p_trim_front_end_radius,
		float p_trim_back_end_radius,
		bool p_includes_waypoints, // Not used in GDScript version for polyline,
								   // but kept for signature
		bool p_includes_instruction_indicators, // Not used for polyline
		bool p_includes_continuous_positions, // Not used for polyline, logic is
											  // in
											  // _get_edge_trajectory_vertices
		bool p_includes_discrete_positions) { // Not used for polyline
	if (!p_canvas || !p_path)
		return;

	float actual_stroke_width = (p_stroke_width_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .edge_trajectory_width
			: p_stroke_width_param;
	godot::Color actual_color = (p_color_param == godot::Color(1, 1, 1, 0))
			? godot::Color(1, 1, 1, 1)
			: p_color_param;

	godot::PackedVector2Array vertices;
	godot::Array edges =
			p_path->get_edges(); // Assuming PlatformGraphPath::get_edges()
								 // returns Array
	for (int i = 0; i < edges.size(); ++i) {
		godot::Ref<godot::Edge> edge = edges[i];
		if (edge.is_valid()) {
			// Defaulting to continuous, true for includes_end_points, false for
			// removes_too_close for basic path
			vertices.append_array(_get_edge_trajectory_vertices(
					edge.ptr(), true, true, false));
		}
	}

	// De-duplicate points between edges if _get_edge_trajectory_vertices
	// includes endpoints for each edge
	if (vertices.size() > 1) {
		godot::PackedVector2Array deduplicated_vertices;
		if (!vertices.is_empty()) {
			deduplicated_vertices.push_back(vertices[0]);
			for (int i = 1; i < vertices.size(); ++i) {
				if (!vertices[i].is_equal_approx(vertices[i - 1])) {
					deduplicated_vertices.push_back(vertices[i]);
				}
			}
		}
		vertices = deduplicated_vertices;
	}

	if (p_trim_front_end_radius > 0.0f) {
		vertices = _trim_front_end(vertices, p_trim_front_end_radius);
	}
	if (p_trim_back_end_radius > 0.0f) {
		vertices = _trim_back_end(vertices, p_trim_back_end_radius);
	}

	if (vertices.size() < 2) {
		return;
	}
	p_canvas->draw_polyline(vertices, actual_color, actual_stroke_width);

	// Note: includes_waypoints, includes_instruction_indicators etc. would
	// typically be handled by drawing those elements on top, perhaps by
	// iterating edges again. The GDScript version only draws the polyline here.
	// If those elements are desired, the logic from draw_edge would need to be
	// partially replicated here.
}

void SurfacerDrawUtils::draw_path_duration_segment(
		godot::CanvasItem *p_canvas,
		godot::PlatformGraphPath *p_path,
		float p_segment_time_start,
		float p_segment_time_end,
		float p_stroke_width_param,
		godot::Color p_color_param,
		float p_trim_front_end_radius,
		float p_trim_back_end_radius) {
	if (!p_canvas || !p_path)
		return;

	float actual_stroke_width = (p_stroke_width_param == -1.0f)
			? SurfacerDrawUtilsPlaceholders::get_annotator_params()
					  .edge_trajectory_width
			: p_stroke_width_param;
	godot::Color actual_color = (p_color_param == godot::Color(1, 1, 1, 0))
			? godot::Color(1, 1, 1, 1)
			: p_color_param;

	godot::PackedVector2Array vertices;
	float edge_start_time = 0.0f;
	bool has_segment_started = false;

	godot::Array edges_arr = p_path->get_edges();
	for (int i = 0; i < edges_arr.size(); ++i) {
		godot::Ref<godot::Edge> edge = edges_arr[i];
		if (!edge.is_valid())
			continue;

		float edge_end_time = edge_start_time + edge->get_duration();
		bool is_start_of_segment =
				!has_segment_started && edge_end_time > p_segment_time_start;
		bool is_end_of_segment = edge_end_time > p_segment_time_end;

		godot::PackedVector2Array edge_vertices;
		if (has_segment_started || is_start_of_segment) {
			// Get vertices without endpoints initially, endpoints handled by
			// segment logic
			edge_vertices = _get_edge_trajectory_vertices(
					edge.ptr(), false, true, false);
		}

		int index_before_segment = -1;
		godot::Vector2 first_vertex_in_segment;
		if (is_start_of_segment) {
			float time_of_index_before = 0.0f;
			float time_of_index_after = 0.0f;
			godot::Ref<godot::Trajectory> trajectory = edge->get_trajectory();

			if (trajectory.is_valid() &&
				!edge_vertices
						 .is_empty()) { // trajectory implies edge_vertices
										// might be populated based on steps
				index_before_segment = static_cast<int>(
						(p_segment_time_start - edge_start_time) /
						SurfacerDrawUtilsPlaceholders::ScaffolderTime::
								physics_time_step);
				index_before_segment =
						MIN(index_before_segment, edge_vertices.size() - 1);
				index_before_segment =
						MAX(index_before_segment, 0); // Ensure non-negative
				time_of_index_before = edge_start_time +
						index_before_segment *
								SurfacerDrawUtilsPlaceholders::ScaffolderTime::
										physics_time_step;
				time_of_index_after = time_of_index_before +
						SurfacerDrawUtilsPlaceholders::ScaffolderTime::
								physics_time_step;
			} else { // No trajectory or empty vertices, treat as single segment
					 // from edge start to end
				index_before_segment = 0; // Effectively, use edge start
				time_of_index_before = edge_start_time;
				time_of_index_after = edge_end_time;
			}

			if (edge_vertices.is_empty()) { // Handle case where edge has
											// duration but no trajectory points
											// (e.g. teleport)
				first_vertex_in_segment = edge->get_start_position();
				if (p_segment_time_start > edge_start_time &&
					p_segment_time_start < edge_end_time &&
					time_of_index_after > time_of_index_before) {
					float weight =
							(p_segment_time_start - time_of_index_before) /
							(time_of_index_after - time_of_index_before);
					first_vertex_in_segment =
							edge->get_start_position().linear_interpolate(
									edge->get_end_position(), weight);
				} else if (p_segment_time_start <= edge_start_time) {
					first_vertex_in_segment = edge->get_start_position();
				} else {
					first_vertex_in_segment = edge->get_end_position();
				}
			} else if (
					index_before_segment >= edge_vertices.size() - 1 ||
					time_of_index_after <= time_of_index_before) {
				first_vertex_in_segment =
						edge_vertices[edge_vertices.size() - 1];
			} else {
				float weight = (p_segment_time_start - time_of_index_before) /
						(time_of_index_after - time_of_index_before);
				weight = CLAMP(weight, 0.0f, 1.0f);
				first_vertex_in_segment =
						edge_vertices[index_before_segment].linear_interpolate(
								edge_vertices[index_before_segment + 1],
								weight);
			}
		}

		int index_after_segment = -1;
		godot::Vector2 last_vertex_in_segment;
		if (is_end_of_segment) {
			float time_of_index_before = 0.0f;
			float time_of_index_after = 0.0f;
			godot::Ref<godot::Trajectory> trajectory = edge->get_trajectory();

			if (trajectory.is_valid() && !edge_vertices.is_empty()) {
				index_after_segment =
						static_cast<int>(
								(p_segment_time_end - edge_start_time) /
								SurfacerDrawUtilsPlaceholders::ScaffolderTime::
										physics_time_step) +
						1;
				index_after_segment =
						MIN(index_after_segment,
							edge_vertices.size() - 1); // Max index is size -1
				index_after_segment =
						MAX(index_after_segment, 0); // Ensure non-negative
				time_of_index_after = edge_start_time +
						index_after_segment *
								SurfacerDrawUtilsPlaceholders::ScaffolderTime::
										physics_time_step;
				time_of_index_before = time_of_index_after -
						SurfacerDrawUtilsPlaceholders::ScaffolderTime::
								physics_time_step;
			} else {
				index_after_segment =
						(edge_vertices.is_empty() ? 0
												  : edge_vertices.size() -
										 1); // Effectively edge end
				time_of_index_before = edge_start_time;
				time_of_index_after = edge_end_time;
			}

			if (edge_vertices.is_empty()) {
				last_vertex_in_segment = edge->get_end_position();
				if (p_segment_time_end > edge_start_time &&
					p_segment_time_end < edge_end_time &&
					time_of_index_after > time_of_index_before) {
					float weight = (p_segment_time_end - time_of_index_before) /
							(time_of_index_after - time_of_index_before);
					last_vertex_in_segment =
							edge->get_start_position().linear_interpolate(
									edge->get_end_position(), weight);
				} else if (p_segment_time_end <= edge_start_time) {
					last_vertex_in_segment = edge->get_start_position();
				} else {
					last_vertex_in_segment = edge->get_end_position();
				}
			} else if (
					index_after_segment == 0 ||
					time_of_index_after <= time_of_index_before) {
				last_vertex_in_segment = edge_vertices[0];
			} else {
				float weight = (p_segment_time_end - time_of_index_before) /
						(time_of_index_after - time_of_index_before);
				weight = CLAMP(weight, 0.0f, 1.0f);
				last_vertex_in_segment =
						edge_vertices[index_after_segment - 1]
								.linear_interpolate(
										edge_vertices[index_after_segment],
										weight);
			}
		}

		if (is_start_of_segment && is_end_of_segment) {
			if (edge_vertices.is_empty()) { // Edge is a single segment in time
				vertices.push_back(first_vertex_in_segment);
				vertices.push_back(last_vertex_in_segment);
			} else {
				vertices = SurfacerDrawUtilsPlaceholders::Utils::
						sub_pool_vector2_array(
								edge_vertices, index_before_segment,
								index_after_segment + 1 - index_before_segment);
				if (!vertices.is_empty()) {
					vertices[0] = first_vertex_in_segment;
					vertices.set(vertices.size() - 1, last_vertex_in_segment);
				} else { // Segment is very short, possibly within a single
						 // physics step interval
					vertices.push_back(first_vertex_in_segment);
					vertices.push_back(last_vertex_in_segment);
				}
			}
			break;
		} else if (is_start_of_segment) {
			has_segment_started = true;
			if (edge_vertices.is_empty()) {
				vertices.push_back(first_vertex_in_segment);
				vertices.push_back(edge->get_end_position());
			} else {
				vertices = SurfacerDrawUtilsPlaceholders::Utils::
						sub_pool_vector2_array(
								edge_vertices, index_before_segment);
				if (!vertices.is_empty()) {
					vertices[0] = first_vertex_in_segment;
				} else { // Started at the very end of this edge or
						 // edge_vertices was empty
					vertices.push_back(first_vertex_in_segment);
				}
				// Add edge's original end point if it wasn't part of
				// sub_pool_vector2_array
				if (edge_vertices.size() > 0 &&
					(index_before_segment < edge_vertices.size() - 1)) {
					// If sub_pool_vector2_array didn't capture the last point
					// of edge_vertices
				}
			}
		} else if (is_end_of_segment) {
			if (edge_vertices.is_empty()) {
				if (vertices.is_empty() ||
					!vertices[vertices.size() - 1].is_equal_approx(
							edge->get_start_position())) {
					vertices.push_back(edge->get_start_position());
				}
				vertices.push_back(last_vertex_in_segment);
			} else {
				godot::PackedVector2Array sub_edge_vertices =
						SurfacerDrawUtilsPlaceholders::Utils::
								sub_pool_vector2_array(
										edge_vertices, 0,
										index_after_segment + 1);
				vertices.append_array(sub_edge_vertices);
				if (!vertices.is_empty()) {
					vertices.set(vertices.size() - 1, last_vertex_in_segment);
				} else { // Should not happen if sub_edge_vertices was populated
					vertices.push_back(last_vertex_in_segment);
				}
			}
			break;
		} else if (has_segment_started) {
			if (edge_vertices.is_empty()) { // For edges with no intermediate
											// points but part of the segment
				if (vertices.is_empty() ||
					!vertices[vertices.size() - 1].is_equal_approx(
							edge->get_start_position())) {
					vertices.push_back(edge->get_start_position());
				}
				vertices.push_back(edge->get_end_position());
			} else {
				vertices.append_array(edge_vertices);
			}
		}
		edge_start_time = edge_end_time;
	}

	// De-duplicate points that might have been added if logic is imperfect
	if (vertices.size() > 1) {
		godot::PackedVector2Array final_vertices;
		if (!vertices.is_empty()) {
			final_vertices.push_back(vertices[0]);
			for (int k = 1; k < vertices.size(); ++k) {
				if (!vertices[k].is_equal_approx(vertices[k - 1])) {
					final_vertices.push_back(vertices[k]);
				}
			}
		}
		vertices = final_vertices;
	}

	if (p_trim_front_end_radius > 0.0f) {
		vertices = _trim_front_end(vertices, p_trim_front_end_radius);
	}
	if (p_trim_back_end_radius > 0.0f) {
		vertices = _trim_back_end(vertices, p_trim_back_end_radius);
	}

	if (vertices.size() < 2) {
		return;
	}
	p_canvas->draw_polyline(vertices, actual_color, actual_stroke_width);
}

void SurfacerDrawUtils::draw_beat_hashes(
		godot::CanvasItem *p_canvas,
		const godot::Array &p_beats,
		float p_downbeat_hash_length_param,
		float p_offbeat_hash_length_param,
		float p_downbeat_stroke_width_param,
		float p_offbeat_stroke_width_param,
		godot::Color p_downbeat_color_param,
		godot::Color p_offbeat_color_param) {
	if (!p_canvas)
		return;

	const auto &params = SurfacerDrawUtilsPlaceholders::get_annotator_params();
	float actual_downbeat_hash_length = (p_downbeat_hash_length_param == -1.0f)
			? params.path_downbeat_hash_length
			: p_downbeat_hash_length_param;
	float actual_offbeat_hash_length = (p_offbeat_hash_length_param == -1.0f)
			? params.path_offbeat_hash_length
			: p_offbeat_hash_length_param;
	float actual_downbeat_stroke_width =
			(p_downbeat_stroke_width_param == -1.0f)
			? params.edge_trajectory_width
			: p_downbeat_stroke_width_param;
	float actual_offbeat_stroke_width = (p_offbeat_stroke_width_param == -1.0f)
			? params.edge_trajectory_width
			: p_offbeat_stroke_width_param;
	godot::Color actual_downbeat_color =
			(p_downbeat_color_param == godot::Color(1, 1, 1, 0))
			? godot::Color(1, 1, 1, 1)
			: p_downbeat_color_param;
	godot::Color actual_offbeat_color =
			(p_offbeat_color_param == godot::Color(1, 1, 1, 0))
			? godot::Color(1, 1, 1, 1)
			: p_offbeat_color_param;

	for (int i = 0; i < p_beats.size(); ++i) {
		godot::Ref<godot::Beat> beat =
				p_beats[i]; // Assuming Beat derives from RefCounted
		if (!beat.is_valid())
			continue;

		float hash_length;
		float stroke_width;
		godot::Color color;

		if (beat->is_downbeat()) {
			hash_length = actual_downbeat_hash_length;
			stroke_width = actual_downbeat_stroke_width;
			color = actual_downbeat_color;
		} else {
			hash_length = actual_offbeat_hash_length;
			stroke_width = actual_offbeat_stroke_width;
			color = actual_offbeat_color;
		}

		godot::Vector2 hash_half_displacement =
				hash_length * beat->get_direction().orthogonal() / 2.0f;
		godot::Vector2 hash_from =
				beat->get_position() + hash_half_displacement;
		godot::Vector2 hash_to = beat->get_position() - hash_half_displacement;

		p_canvas->draw_line(
				hash_from, hash_to, color, stroke_width,
				false); // Antialiasing false in GDScript
	}
}

void SurfacerDrawUtils::draw_edge(
		godot::CanvasItem *p_canvas,
		godot::Edge *p_edge,
		float p_stroke_width_param,
		godot::Color p_discrete_trajectory_color_param,
		bool p_includes_waypoints,
		bool p_includes_instruction_indicators,
		bool p_includes_continuous_positions,
		bool p_includes_discrete_positions) {
	if (!p_canvas || !p_edge)
		return;

	const auto &annotator_params =
			SurfacerDrawUtilsPlaceholders::get_annotator_params();
	float actual_stroke_width = (p_stroke_width_param == -1.0f)
			? annotator_params.edge_trajectory_width
			: p_stroke_width_param;

	godot::Color actual_discrete_trajectory_color;
	if (p_discrete_trajectory_color_param ==
		godot::Color(1, 1, 1, 0)) { // Sentinel for default
		actual_discrete_trajectory_color =
				SurfacerDrawUtilsPlaceholders::Palette::get_color(
						"edge_discrete_trajectory_color");
	} else {
		actual_discrete_trajectory_color = p_discrete_trajectory_color_param;
		// The GDScript logic: if param is Color.white (the default value of the
		// param, not sentinel), then override. This means if user explicitly
		// passes Color(1,1,1,1), it gets overridden.
		if (p_discrete_trajectory_color_param.is_equal_approx(
					godot::Color(1, 1, 1, 1))) {
			actual_discrete_trajectory_color =
					SurfacerDrawUtilsPlaceholders::Palette::get_color(
							"edge_discrete_trajectory_color");
		}
	}

	godot::Color continuous_trajectory_color =
			SurfacerDrawUtilsPlaceholders::Palette::get_color(
					"edge_continuous_trajectory_color");
	continuous_trajectory_color.set_h(actual_discrete_trajectory_color.get_h());
	godot::Color waypoint_color =
			SurfacerDrawUtilsPlaceholders::Palette::get_color("waypoint_color");
	waypoint_color.set_h(actual_discrete_trajectory_color.get_h());
	godot::Color instruction_color =
			SurfacerDrawUtilsPlaceholders::Palette::get_color(
					"instruction_color");
	instruction_color.set_h(actual_discrete_trajectory_color.get_h());

	if (p_includes_continuous_positions) {
		godot::PackedVector2Array vertices = _get_edge_trajectory_vertices(
				p_edge, true, true, true); // removes_too_close = true
		if (vertices.size() >= 2) {
			p_canvas->draw_polyline(
					vertices, continuous_trajectory_color, actual_stroke_width);
		}
	}
	if (p_includes_discrete_positions) {
		godot::PackedVector2Array vertices = _get_edge_trajectory_vertices(
				p_edge, true, false, true); // removes_too_close = true
		if (vertices.size() >= 2) {
			p_canvas->draw_polyline(
					vertices, actual_discrete_trajectory_color,
					actual_stroke_width);
		}
	}

	if (p_includes_waypoints) {
		godot::Ref<godot::Trajectory> trajectory = p_edge->get_trajectory();
		if (trajectory.is_valid()) {
			godot::PackedVector2Array waypoint_positions =
					trajectory->get_waypoint_positions();
			// GDScript iterates size() - 1, meaning it skips the last waypoint
			// (which is the destination)
			for (int i = 0; i < waypoint_positions.size() - 1; ++i) {
				ScaffolderDrawUtils::draw_circle_outline(
						p_canvas, waypoint_positions[i],
						annotator_params.edge_waypoint_radius, waypoint_color,
						actual_stroke_width, 4.0f, 0.0, pi * 2.0, false);
			}
		}

		godot::Ref<godot::PositionAlongSurface> end_pos_along_surface =
				p_edge->get_end_position_along_surface();
		if (end_pos_along_surface.is_valid()) {
			draw_destination_marker(
					p_canvas, end_pos_along_surface.ptr(), true,
					waypoint_color);
		}

		draw_origin_marker(
				p_canvas, p_edge->get_start_position(), waypoint_color);
	}

	if (p_includes_instruction_indicators) {
		godot::Ref<godot::Trajectory> trajectory = p_edge->get_trajectory();
		if (trajectory.is_valid()) {
			godot::Array horizontal_instructions =
					trajectory->get_horizontal_instructions();
			for (int i = 0; i < horizontal_instructions.size(); ++i) {
				godot::Ref<godot::Instruction> instruction =
						horizontal_instructions[i];
				if (instruction.is_valid()) {
					draw_instruction_indicator(
							p_canvas, instruction->get_input_key(),
							instruction->is_pressed(),
							instruction->get_position(),
							annotator_params.edge_instruction_indicator_length,
							instruction_color);
				}
			}
			godot::Ref<godot::Instruction> jump_instruction_end =
					trajectory->get_jump_instruction_end();
			if (jump_instruction_end.is_valid()) {
				draw_instruction_indicator(
						p_canvas, "j", false,
						jump_instruction_end->get_position(),
						annotator_params.edge_instruction_indicator_length,
						instruction_color);
			}
		}
	}
}

// Ensure _get_edge_trajectory_vertices, _remove_too_close_neighbors,
// draw_tilemap_indices, draw_tile_grid_positions are correctly defined as
// previously shown. Also ensure ScaffolderDrawUtils::draw_circle_outline,
// ScaffolderDrawUtils::draw_ice_cream_cone, and
// ScaffolderDrawUtils::draw_strike_through_arrow are accessible.
