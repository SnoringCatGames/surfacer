#include "scaffolder_draw_utils.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

ScaffolderDrawUtils::ScaffolderDrawUtils() {
	// GDScript: Sc.log_service.report_submodule_initialized(self,
	// "ScaffolderDrawUtils") This would be replaced by your C++ project's
	// logging/initialization mechanism if needed.
	// UtilityFunctions::print("ScaffolderDrawUtils initialized.");
}

ScaffolderDrawUtils::~ScaffolderDrawUtils() {}

void ScaffolderDrawUtils::draw_closed_polyline(
		CanvasItem *p_canvas,
		PackedVector2Array p_points,
		Color p_color,
		double p_stroke_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	int original_size = p_points.size();
	ERR_FAIL_COND_MSG(
			original_size < 2,
			"draw_closed_polyline requires at least 2 points.");

	if (original_size == 2) {
		p_canvas->draw_line(
				p_points[0], p_points[1], p_color, p_stroke_width,
				p_antialiased);
		return;
	}

	// PackedVector2Array p_points is passed by value, so modifications are
	// local.
	p_points.insert(
			0, p_points[0]); // Duplicates the first point at the beginning

	if (p_points[0].is_equal_approx(
				p_points[original_size])) { // original_size is now index of
											// original last point
		p_points.push_back(
				p_points[0]); // original_size was old size, points[0] is the
							  // very first original point
	} else {
		// original_size + 1 is current size after insert
		// original_size + 2 for new size
		// original_size + 3 for new size
		p_points.resize(
				original_size +
				3); // After insert(0, points[0]), size is original_size + 1
					// points[original_size] was the original last point.
					// points[original_size+1] is new slot
					// points[original_size+2] is new slot
		// The GDScript logic:
		// points.insert(0, points[0]) -> size = original_size + 1. points[0] is
		// new, points[1] is original points[0]. if points[1] ==
		// points[original_size]: (original_size is index of last element of
		// original array)
		//    points.push_back(points[1])
		// else:
		//    points.resize(original_size + 3) // This seems off. If
		//    original_size = 3, insert makes it 4. resize(6).
		//    points[original_size+1] = points[1] // points[4] = points[1]
		//    points[original_size+2] = points[1] // points[5] = points[1]

		// Let's re-evaluate GDScript logic carefully:
		// 1. `points.insert(0, points[0])` -> `current_points` has
		// `original_points[0]` at index 0, and original `points` from index 1.
		// Size = `original_size + 1`.
		//    `current_points[0]` is a copy of `original_points[0]`.
		//    `current_points[1]` is `original_points[0]`.
		//    `current_points[original_size]` is `original_points[original_size
		//    - 1]`.
		//
		// Corrected interpretation:
		// `p_points.insert(0, p_points[0]);` // p_points[0] is now a duplicate
		// of the original p_points[0]. The original p_points[0] is now at
		// p_points[1]. The original p_points[original_size-1] is now at
		// p_points[original_size]. Size is original_size + 1.

		// if p_points[1] == p_points[original_size]: (Comparing original first
		// and original last)
		//    p_points.push_back(p_points[1]); // Add original first again at
		//    the end.
		// else:
		//    p_points.resize(original_size + 3); // Current size is
		//    original_size + 1. This adds 2 slots. p_points[original_size + 1]
		//    = p_points[1]; // original_first p_points[original_size + 2] =
		//    p_points[1]; // original_first

		// Let's use a clearer approach for C++ based on intent:
		// We need a list like: P0_copy, P0, P1, ..., Pn-1, P0_copy,
		// P0_another_copy if P0 == Pn-1, then: P0_copy, P0, P1, ..., Pn-1(=P0),
		// P0_copy The goal is to make the polyline wrap around smoothly.
		// GDScript:
		// points.insert(0, points[0]) -> effectively prepends current points[0]
		// if points[0] == points[original_size]: (original_size is now the
		// index of the last element of the *modified* array, which was the
		// original last element)
		//    points.push_back(points[0])
		// else:
		//    points.resize(original_size + 3) // original_size is the size
		//    *before* insert. points[original_size] = points[0] // This is
		//    where it gets tricky. points[original_size + 1] = points[0]

		// Let's simplify based on the final structure needed for draw_polyline:
		// P_adj_start, P_start, P1, ..., P_end, P_adj_end
		// where P_adj_start and P_adj_end help close the loop.
		// The GDScript code is a bit convoluted. The final polyline sent to
		// draw_polyline is: [P0_offset_A, P0, P1, ..., P_last, P0_offset_B]
		// where P0_offset_A and P0_offset_B are modified. And P_last might be
		// P0 if it was already closed.

		// Sticking to direct port of the array manipulation:
		PackedVector2Array temp_points = p_points; // original points
		p_points.clear();
		p_points.push_back(temp_points[0]); // Prepend first element
		p_points.append_array(temp_points); // Add all original elements

		// Now p_points is [orig_P0, orig_P0, orig_P1, ..., orig_P_last]. Size =
		// original_size + 1. orig_P0 is at p_points[0] and p_points[1].
		// orig_P_last is at p_points[original_size].

		if (p_points[1].is_equal_approx(
					p_points[original_size])) { // If original_first ==
												// original_last
			p_points.push_back(p_points[1]); // Add original_first to the end
		} else {
			// Current size is original_size + 1. Need to make it original_size
			// + 3. This means adding two elements.
			p_points.push_back(p_points[1]); // Add original_first
			p_points.push_back(p_points[1]); // Add original_first again
		}
	}
	// At this point, p_points should have a structure that draw_polyline can
	// use by modifying its first (index 1 after offset) and last-but-one
	// (new_size-2) points.

	int new_size = p_points.size();
	ERR_FAIL_COND_MSG(
			new_size < 4,
			"Internal error in draw_closed_polyline point setup."); // Minimum
																	// for
																	// P_adj,
																	// P0,
																	// P_last_or_P0,
																	// P_adj

	Vector2 tangentish_direction =
			p_points[2] - p_points[1]; // Based on (original P1 - original P0)
	Vector2 offset = tangentish_direction * 0.00001;
	p_points.set(
			0,
			p_points[1] +
					offset); // Modify the prepended point (was copy of P0)
	p_points.set(
			new_size - 1,
			p_points[new_size - 2] -
					offset); // Modify the appended point (was copy of P0)

	// The GDScript logic for points[1] and points[new_size-2] was:
	// points[1] = points[0] + offset  (here points[0] is the *original*
	// points[0]) points[new_size - 2] = points[0] - offset This means the
	// points that form the actual start/end of the visible polyline are
	// adjusted. The polyline passed to draw_polyline is [adj_start, P0_mod, P1,
	// ..., P_last_mod, adj_end] Let's re-verify the GDScript: `points.insert(0,
	// points[0])` -> `points` is now `[P0_orig, P0_orig, P1_orig, ...]`
	// `points[1] = points[0] + offset` -> `points` is `[P0_orig, P0_orig +
	// offset, P1_orig, ...]` This seems to modify the *second* element. The
	// intent is to make the segments (points[0],points[1]) and
	// (points[N-2],points[N-1]) collinear with the main body. The polyline
	// drawn is from points[0] to points[N-1]. The fix is for the caps at
	// points[0] and points[N-1]. The GDScript `points.insert(0, points[0])` and
	// `points.push_back(points[0])` (effectively) creates `[P0, P0, P1, ...,
	// P_last, P0]`. Then `points[1]` (the second P0) and `points[new_size-2]`
	// (P_last) are modified. This means the actual polyline drawn is `[P0,
	// P0_mod, P1, ..., P_last_mod, P0]`.

	// Simpler: create the final array structure directly.
	PackedVector2Array final_polyline;
	final_polyline.push_back(p_points[0]); // P0
	final_polyline.append_array(p_points); // P0, P0, P1, ..., P_last
	if (!p_points[0].is_equal_approx(p_points[p_points.size() - 1])) {
		final_polyline.push_back(p_points[0]); // P0, P0, P1, ..., P_last, P0
	}
	// Now final_polyline is [P0, P0, P1, ..., P_last (maybe P0), P0]
	// This is not matching the GDScript manipulation.

	// Let's use the version of p_points after the if/else block for push_backs.
	// `p_points` is now:
	// if closed: [orig_P0, orig_P0, P1, ..., P_last(=orig_P0), orig_P0]
	// if open:   [orig_P0, orig_P0, P1, ..., P_last, orig_P0, orig_P0]
	// new_size is its size.
	// `tangentish_direction = p_points[2] - p_points[1];` (orig_P1 - orig_P0)
	// `offset = tangentish_direction * 0.00001;`
	// `p_points[1] = p_points[0] + offset;` // This is WRONG. points[0] is
	// orig_P0. points[1] is orig_P0. Should be `p_points[1] = p_points[1] +
	// offset` if it's the point to shift. Or, `p_points[1] =
	// THE_ACTUAL_START_POINT_OF_POLYGON + offset`.
	// The GDScript `points[0]` in `points[1] = points[0] + offset` refers to
	// the *current* `points[0]`. After `points.insert(0, points[0])`,
	// `points[0]` and `points[1]` are identical (original `points[0]`). So
	// `points[1] = points[0] + offset` means `points[1]` becomes
	// `original_points[0] + offset`. And `points[new_size - 2] = points[0] -
	// offset` means `points[new_size-2]` becomes `original_points[0] - offset`.
	// This makes the start segment `(points[0], points[1])` -> `(original_P0,
	// original_P0 + offset)`. And end segment `(points[new_size-3],
	// points[new_size-2])` -> `(prev_to_last_adj, original_P0 - offset)`. And
	// the polyline is drawn with this modified `p_points`.

	// Re-porting the array manipulation carefully:
	PackedVector2Array poly_to_draw =
			p_points; // p_points is the input parameter
	int o_size = poly_to_draw.size();

	PackedVector2Array work_points;
	work_points.push_back(poly_to_draw[0]); // Add P0
	work_points.append_array(poly_to_draw); // Add P0, P1, ..., P_last. Now [P0,
											// P0, P1, ..., P_last]

	if (work_points[0].is_equal_approx(
				work_points[o_size])) { // If original P0 == original P_last
		work_points.push_back(work_points[0]); // Add P0 at end. Now [P0, P0,
											   // P1,...,P_last(=P0), P0]
	} else {
		work_points.push_back(work_points[0]); // Add P0
		work_points.push_back(
				work_points[0]); // Add P0. Now [P0, P0, P1,...,P_last, P0, P0]
	}
	// This matches the structure of `points` in GDScript after the if/else.
	// `work_points[0]` is original P0. `work_points[1]` is original P0.
	// `work_points[2]` is original P1.

	int current_size = work_points.size();
	if (current_size < 3) { // Should not happen with original_size >= 2
		p_canvas->draw_polyline(
				poly_to_draw, p_color, p_stroke_width, p_antialiased);
		return;
	}

	Vector2 actual_start_node =
			work_points[1]; // This is the node that starts the visible polygon.
	Vector2 actual_second_node = work_points[2];
	Vector2 actual_end_node =
			work_points[current_size - 2]; // This is the node that ends the
										   // visible polygon.
	Vector2 actual_prev_to_end_node = work_points[current_size - 3];

	Vector2 start_tangent_dir =
			(actual_second_node - actual_start_node).normalized();
	Vector2 end_tangent_dir =
			(actual_end_node - actual_prev_to_end_node)
					.normalized(); // Points from prev_to_end towards end

	work_points.set(
			0,
			actual_start_node -
					start_tangent_dir * 0.0001); // Adjust point before start
	work_points.set(
			current_size - 1,
			actual_end_node +
					end_tangent_dir * 0.0001); // Adjust point after end

	p_canvas->draw_polyline(
			work_points, p_color, p_stroke_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_line(
		CanvasItem *p_canvas,
		Vector2 p_from,
		Vector2 p_to,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_dash_length <= 0, "Dash length must be positive.");
	// ERR_FAIL_COND_MSG(p_dash_gap < 0, "Dash gap must be non-negative."); //
	// GDScript allows 0 gap

	double segment_length = p_from.distance_to(p_to);
	if (segment_length < CMP_EPSILON)
		return;
	Vector2 direction_normalized = (p_to - p_from).normalized();

	double current_pos_val = p_dash_offset;
	// Normalize dash_offset to be within one pattern length to avoid excessive
	// skipping
	double pattern_length = p_dash_length + p_dash_gap;
	if (pattern_length > CMP_EPSILON) {
		current_pos_val = std::fmod(p_dash_offset, pattern_length);
		if (current_pos_val < 0) {
			current_pos_val += pattern_length;
		}
	}

	while (current_pos_val < segment_length) {
		double dash_start_pos = current_pos_val;
		double dash_end_pos = current_pos_val + p_dash_length;

		if (dash_start_pos < segment_length) { // Only draw if some part of the
											   // dash is in the segment
			Vector2 current_from =
					p_from + direction_normalized * MAX(0.0, dash_start_pos);
			Vector2 current_to = p_from +
					direction_normalized * MIN(segment_length, dash_end_pos);

			if (current_to.distance_squared_to(current_from) >
				CMP_EPSILON_SQUARED) {
				p_canvas->draw_line(
						current_from, current_to, p_color, p_width,
						p_antialiased);
			}
		}
		current_pos_val += p_dash_length + p_dash_gap;
		if (p_dash_length + p_dash_gap <= CMP_EPSILON &&
			p_dash_length > CMP_EPSILON) { // Avoid infinite loop if gap is
										   // zero/negative
			break;
		}
	}
}

void ScaffolderDrawUtils::draw_dashed_polyline(
		CanvasItem *p_canvas,
		const PackedVector2Array &p_vertices,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	// The GDScript version's TODO about honoring gaps across vertices is
	// important. A simple loop like this will restart the dash pattern for each
	// segment. For a continuous dash pattern along the polyline, a more complex
	// approach is needed. Porting the existing behavior:
	double current_offset = p_dash_offset;
	for (int i = 0; i < p_vertices.size() - 1; ++i) {
		Vector2 from = p_vertices[i];
		Vector2 to = p_vertices[i + 1];
		draw_dashed_line(
				p_canvas, from, to, p_color, p_dash_length, p_dash_gap,
				current_offset, p_width, p_antialiased);

		// To attempt to continue the pattern (basic version, might not be
		// perfect):
		double segment_length = from.distance_to(to);
		if (p_dash_length + p_dash_gap > CMP_EPSILON) {
			current_offset = std::fmod(
					current_offset - segment_length,
					p_dash_length + p_dash_gap);
			if (current_offset < 0) { // ensure positive offset for next segment
				current_offset += (p_dash_length + p_dash_gap);
			}
		}
	}
}

void ScaffolderDrawUtils::draw_dashed_rectangle(
		CanvasItem *p_canvas,
		Vector2 p_center,
		Vector2 p_half_width_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_stroke_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	double half_width = p_is_rotated_90_degrees ? p_half_width_height.y
												: p_half_width_height.x;
	double half_height = p_is_rotated_90_degrees ? p_half_width_height.x
												 : p_half_width_height.y;

	Vector2 top_left = p_center + Vector2(-half_width, -half_height);
	Vector2 top_right = p_center + Vector2(half_width, -half_height);
	Vector2 bottom_right = p_center + Vector2(half_width, half_height);
	Vector2 bottom_left = p_center + Vector2(-half_width, half_height);

	PackedVector2Array rect_vertices;
	rect_vertices.push_back(top_left);
	rect_vertices.push_back(top_right);
	rect_vertices.push_back(bottom_right);
	rect_vertices.push_back(bottom_left);
	rect_vertices.push_back(top_left); // Close the loop for continuous dashing

	// Use draw_dashed_polyline to handle continuous dashing if implemented well
	draw_dashed_polyline(
			p_canvas, rect_vertices, p_color, p_dash_length, p_dash_gap,
			p_dash_offset, p_stroke_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_circle(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	draw_dashed_arc(
			p_canvas, p_center, p_radius, 0.0, tau, p_color, p_dash_length,
			p_dash_gap, p_dash_offset, p_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_arc(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_dash_length <= 0.0, "Dash length must be positive.");
	ERR_FAIL_COND_MSG(p_radius < 0.0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON)
		return; // Nothing to draw for zero radius

	// Normalize angles
	p_start_angle = Math::fposmod(p_start_angle, tau);
	p_end_angle = Math::fposmod(p_end_angle, tau);
	if (p_end_angle <= p_start_angle &&
		std::abs(p_end_angle - p_start_angle) >
				CMP_EPSILON) { // Handle wrap around TAU for full circle or arc
							   // across 0
		if ((p_start_angle > p_end_angle) &&
			((p_start_angle - p_end_angle) <
			 pi)) { // Small arc crossing 0 backwards
			// This case is tricky, often draw_arc handles it by taking total
			// angle. For dashing, we need a consistent direction.
		} else {
			p_end_angle += tau;
		}
	}

	double total_arc_length = (p_end_angle - p_start_angle) * p_radius;
	if (total_arc_length <= CMP_EPSILON)
		return;

	double pattern_length = p_dash_length + p_dash_gap;
	ERR_FAIL_COND_MSG(
			pattern_length <= 0.0 && p_dash_length > 0,
			"Pattern length (dash + gap) must be positive if dash_length is "
			"positive.");

	double current_arc_pos = p_dash_offset;
	if (pattern_length > CMP_EPSILON) {
		current_arc_pos = std::fmod(p_dash_offset, pattern_length);
		if (current_arc_pos < 0) {
			current_arc_pos += pattern_length;
		}
	}

	while (current_arc_pos < total_arc_length) {
		double dash_start_arc = current_arc_pos;
		double dash_end_arc = current_arc_pos + p_dash_length;

		if (dash_start_arc < total_arc_length) {
			double angle1 = p_start_angle + MAX(0.0, dash_start_arc) / p_radius;
			double angle2 = p_start_angle +
					MIN(total_arc_length, dash_end_arc) / p_radius;

			if (angle2 >
				angle1 + CMP_EPSILON) { // Ensure there's an arc to draw
				// For short dashes, draw_line is fine. For longer ones,
				// draw_arc might be better if available. Godot's draw_arc draws
				// a filled sector part. We need a line. So, we approximate with
				// small line segments or use draw_polyline on arc points. For
				// simplicity, using draw_line between the two points on the
				// circle.
				Vector2 from_p = p_center +
						Vector2(Math::cos(angle1), Math::sin(angle1)) *
								p_radius;
				Vector2 to_p = p_center +
						Vector2(Math::cos(angle2), Math::sin(angle2)) *
								p_radius;
				p_canvas->draw_line(
						from_p, to_p, p_color, p_width, p_antialiased);
			}
		}
		current_arc_pos += pattern_length;
		if (pattern_length <= CMP_EPSILON && p_dash_length > CMP_EPSILON)
			break;
	}
}

void ScaffolderDrawUtils::draw_dashed_capsule(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_thickness,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0, "Radius cannot be negative.");
	ERR_FAIL_COND_MSG(p_height < 0, "Height cannot be negative.");

	Vector2 dir = p_is_rotated_90_degrees ? Vector2(0, 1) : Vector2(1, 0);
	Vector2 line_half_vec = dir * (p_height / 2.0);

	Vector2 center1 = p_center - line_half_vec;
	Vector2 center2 = p_center + line_half_vec;

	double start_angle1, end_angle1, start_angle2, end_angle2;
	Vector2 p1_start, p1_end, p2_start, p2_end;

	if (p_is_rotated_90_degrees) {
		start_angle1 = pi;
		end_angle1 = tau; // Top semi-circle (0 to PI in Godot angles if
						  // center1 is top) Corrected: center1 is top, so
						  // angles PI to 2PI (TAU)
		start_angle2 = 0.0;
		end_angle2 = pi; // Bottom semi-circle

		p1_start = center1 + Vector2(p_radius, 0); // Right point of top arc
		p1_end = center2 + Vector2(p_radius, 0); // Right point of bottom arc
		p2_start = center2 + Vector2(-p_radius, 0); // Left point of bottom arc
		p2_end = center1 + Vector2(-p_radius, 0); // Left point of top arc
	} else { // Horizontal capsule
		start_angle1 = pi / 2.0;
		end_angle1 = pi * 3.0 / 2.0; // Left semi-circle
		start_angle2 = -pi / 2.0;
		end_angle2 = pi / 2.0; // Right semi-circle

		p1_start = center1 + Vector2(0, -p_radius); // Top point of left arc
		p1_end = center2 + Vector2(0, -p_radius); // Top point of right arc
		p2_start = center2 + Vector2(0, p_radius); // Bottom point of right arc
		p2_end = center1 + Vector2(0, p_radius); // Bottom point of left arc
	}

	// This needs to be a continuous dash pattern around the whole capsule.
	// The GDScript version calls draw_dashed_arc and draw_dashed_line
	// separately, which will restart the dash pattern. Porting existing
	// behavior:
	draw_dashed_arc(
			p_canvas, center1, p_radius, start_angle1, end_angle1, p_color,
			p_dash_length, p_dash_gap, p_dash_offset, p_thickness,
			p_antialiased);
	draw_dashed_arc(
			p_canvas, center2, p_radius, start_angle2, end_angle2, p_color,
			p_dash_length, p_dash_gap, p_dash_offset, p_thickness,
			p_antialiased);

	// Calculate offset for straight lines based on arc lengths
	double arc_len = pi * p_radius;
	double offset_line1 = p_dash_offset;
	if (p_dash_length + p_dash_gap > CMP_EPSILON) {
		offset_line1 =
				std::fmod(p_dash_offset - arc_len, p_dash_length + p_dash_gap);
		if (offset_line1 < 0)
			offset_line1 += (p_dash_length + p_dash_gap);
	}

	draw_dashed_line(
			p_canvas, p1_start, p1_end, p_color, p_dash_length, p_dash_gap,
			offset_line1, p_thickness, p_antialiased);

	double line_len = p_height;
	double offset_line2 = offset_line1;
	if (p_dash_length + p_dash_gap > CMP_EPSILON) {
		offset_line2 =
				std::fmod(offset_line1 - line_len, p_dash_length + p_dash_gap);
		if (offset_line2 < 0)
			offset_line2 += (p_dash_length + p_dash_gap);
	}
	// The second arc starts after the first line, so its offset also needs
	// adjustment. This is getting complicated to perfectly replicate continuous
	// dashing with separate calls. The GDScript itself doesn't guarantee
	// continuous dashing across these elements.

	draw_dashed_line(
			p_canvas, p2_start, p2_end, p_color, p_dash_length, p_dash_gap,
			offset_line2, p_thickness, p_antialiased);
}

void ScaffolderDrawUtils::draw_x(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	p_canvas->draw_line(
			p_center + Vector2(-half_width, -half_height),
			p_center + Vector2(half_width, half_height), p_color,
			p_stroke_width);
	p_canvas->draw_line(
			p_center + Vector2(half_width, -half_height),
			p_center + Vector2(-half_width, half_height), p_color,
			p_stroke_width);
}

void ScaffolderDrawUtils::draw_plus(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	p_canvas->draw_line(
			p_center + Vector2(-half_width, 0),
			p_center + Vector2(half_width, 0), p_color, p_stroke_width);
	p_canvas->draw_line(
			p_center + Vector2(0, -half_height),
			p_center + Vector2(0, half_height), p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_asterisk(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double plus_width = p_width;
	double plus_height = p_height;
	double x_width = plus_width * 0.8;
	double x_height = plus_height * 0.8;
	draw_x(p_canvas, p_center, x_width, x_height, p_color, p_stroke_width);
	draw_plus(
			p_canvas, p_center, plus_width, plus_height, p_color,
			p_stroke_width);
}

void ScaffolderDrawUtils::draw_checkmark(
		CanvasItem *p_canvas,
		Vector2 p_position,
		double p_width,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	Vector2 top_left_point =
			p_position + Vector2(-p_width / 3.0, -p_width / 6.0);
	Vector2 bottom_mid_point = p_position + Vector2(0, p_width / 6.0);
	Vector2 top_right_point =
			p_position + Vector2(p_width * 2.0 / 3.0, -p_width / 2.0 * 1.33);

	Vector2 slight_horizontal_offset = Vector2(0.001, 0.0);

	PackedVector2Array vertices;
	vertices.push_back(top_left_point);
	vertices.push_back(bottom_mid_point - slight_horizontal_offset);
	// The GDScript version has two very close points here to make the polyline
	// turn sharply. For draw_polyline, this is fine.
	vertices.push_back(bottom_mid_point + slight_horizontal_offset);
	vertices.push_back(top_right_point);

	p_canvas->draw_polyline(vertices, p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_exclamation_mark(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_length,
		Color p_color,
		bool p_is_filled,
		double p_stroke_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_length = p_length / 2.0;

	double body_top_radius = half_width;
	double body_bottom_radius =
			body_top_radius * EXCLAMATION_MARK_BODY_LOWER_END_WIDTH_RATIO;
	double dot_radius = body_top_radius * EXCLAMATION_MARK_DOT_WIDTH_RATIO;

	double gap_length = p_width * EXCLAMATION_MARK_GAP_LENGTH_TO_WIDTH_RATIO;
	double body_length = p_length - gap_length - dot_radius * 2.0;
	ERR_FAIL_COND_MSG(
			body_length < 0,
			"Exclamation mark body length is negative. Adjust dimensions.");

	Vector2 body_top_center =
			p_center + Vector2(0.0, -half_length + body_top_radius);
	Vector2 body_bottom_center = body_top_center +
			Vector2(0.0, body_length - body_top_radius - body_bottom_radius);
	Vector2 dot_center = p_center + Vector2(0.0, half_length - dot_radius);

	if (p_is_filled) {
		p_canvas->draw_circle(dot_center, dot_radius, p_color);
	} else {
		draw_circle_outline(
				p_canvas, dot_center, dot_radius, p_color, p_stroke_width,
				p_sector_arc_length);
	}
	draw_smooth_segment_with_two_circular_ends(
			p_canvas, body_top_center, body_top_radius, body_bottom_center,
			body_bottom_radius, p_color, p_is_filled, p_stroke_width,
			p_sector_arc_length);
}

void ScaffolderDrawUtils::draw_arrow(
		CanvasItem *p_canvas,
		Vector2 p_start,
		Vector2 p_end,
		double p_head_length,
		double p_head_width,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	draw_strike_through_arrow(
			p_canvas, p_start, p_end, p_head_length, p_head_width, infinity,
			p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_strike_through_arrow(
		CanvasItem *p_canvas,
		Vector2 p_start,
		Vector2 p_end,
		double p_head_length,
		double p_head_width,
		double p_strike_through_length,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double start_to_end_angle = p_start.angle_to_point(p_end);
	Vector2 head_diff_1 = Vector2(p_head_length, -p_head_width * 0.5)
								  .rotated(start_to_end_angle);
	Vector2 head_diff_2 = Vector2(p_head_length, p_head_width * 0.5)
								  .rotated(start_to_end_angle);
	Vector2 head_end_1 = p_end - head_diff_1; // Arrowhead points from ends of
											  // head_diff towards p_end
	Vector2 head_end_2 = p_end -
			head_diff_2; // Corrected: head points from p_end towards start

	// The GDScript `end + head_diff` means the arrow head points away from
	// start. If head_length is positive, head_diff_1 is (L, -W/2).rotated. end
	// + (L, -W/2).rotated means the arrowhead base is at 'end', and points
	// extend further. This is unusual. Usually arrow head points *towards*
	// 'end'. Let's assume the GDScript logic is intended: arrowhead extends
	// *beyond* 'end'. If `head_length` is meant to be the length of the barbs:
	Vector2 direction = (p_end - p_start).normalized();
	Vector2 barb1_end = p_end - direction * p_head_length +
			direction.orthogonal() * p_head_width * 0.5;
	Vector2 barb2_end = p_end - direction * p_head_length -
			direction.orthogonal() * p_head_width * 0.5;

	p_canvas->draw_line(p_end, barb1_end, p_color, p_stroke_width);
	p_canvas->draw_line(p_end, barb2_end, p_color, p_stroke_width);
	p_canvas->draw_line(p_start, p_end, p_color, p_stroke_width);

	if (!std::isinf(p_strike_through_length) && p_strike_through_length > 0) {
		double strike_through_angle = start_to_end_angle + STRIKE_THROUGH_ANGLE;
		Vector2 strike_through_middle = p_start.lerp(p_end, 0.5);
		double strike_through_half_length = p_strike_through_length / 2.0;
		Vector2 strike_through_offset = Vector2(
				Math::cos(strike_through_angle) * strike_through_half_length,
				Math::sin(strike_through_angle) * strike_through_half_length);
		Vector2 strike_through_start =
				strike_through_middle - strike_through_offset;
		Vector2 strike_through_end =
				strike_through_middle + strike_through_offset;
		p_canvas->draw_line(
				strike_through_start, strike_through_end, p_color,
				p_stroke_width);
	}
}

void ScaffolderDrawUtils::draw_diamond_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	Vector2 p1 = p_center + Vector2(-half_width, 0);
	Vector2 p2 = p_center + Vector2(0, -half_height);
	Vector2 p3 = p_center + Vector2(half_width, 0);
	Vector2 p4 = p_center + Vector2(0, half_height);
	p_canvas->draw_line(p1, p2, p_color, p_stroke_width);
	p_canvas->draw_line(p2, p3, p_color, p_stroke_width);
	p_canvas->draw_line(p3, p4, p_color, p_stroke_width);
	p_canvas->draw_line(p4, p1, p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_shape_outline(
		CanvasItem *p_canvas,
		Vector2 p_position,
		const Ref<RotatedShapeData> &p_shape_data,
		Color p_color,
		double p_thickness) const {
	if (!p_canvas || !p_shape_data.is_valid() ||
		!p_shape_data->get_shape().is_valid()) {
		// UtilityFunctions::print_error("Invalid shape data provided for
		// draw_shape_outline.");
		return;
	}
	Ref<Shape2D> shape = p_shape_data->get_shape();
	bool is_rotated = p_shape_data->get_is_rotated_90_degrees();

	// Need to cast to specific shape types
	Ref<CircleShape2D> circle = shape;
	if (circle.is_valid()) {
		draw_circle_outline(
				p_canvas, p_position, circle->get_radius(), p_color,
				p_thickness);
		return;
	}
	Ref<CapsuleShape2D> capsule = shape;
	if (capsule.is_valid()) {
		draw_capsule_outline(
				p_canvas, p_position, capsule->get_radius(),
				capsule->get_height(), is_rotated, p_color, p_thickness);
		return;
	}
	Ref<RectangleShape2D> rect = shape;
	if (rect.is_valid()) {
		draw_rectangle_outline(
				p_canvas, p_position, rect->get_size() / 2.0, is_rotated,
				p_color, p_thickness); // RectangleShape2D uses size (full
									   // width/height), need half for extents
		return;
	}
	UtilityFunctions::printerr(
			"Unsupported Shape2D type for draw_shape_outline: " +
			shape->get_class());
}

void ScaffolderDrawUtils::draw_dashed_shape(
		CanvasItem *p_canvas,
		Vector2 p_position,
		const Ref<RotatedShapeData> &p_shape_data,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_thickness) const {
	if (!p_canvas || !p_shape_data.is_valid() ||
		!p_shape_data->get_shape().is_valid()) {
		// UtilityFunctions::print_error("Invalid shape data provided for
		// draw_dashed_shape.");
		return;
	}
	Ref<Shape2D> shape = p_shape_data->get_shape();
	bool is_rotated = p_shape_data->get_is_rotated_90_degrees();

	Ref<CircleShape2D> circle = shape;
	if (circle.is_valid()) {
		draw_dashed_circle(
				p_canvas, p_position, circle->get_radius(), p_color,
				p_dash_length, p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	Ref<CapsuleShape2D> capsule = shape;
	if (capsule.is_valid()) {
		draw_dashed_capsule(
				p_canvas, p_position, capsule->get_radius(),
				capsule->get_height(), is_rotated, p_color, p_dash_length,
				p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	Ref<RectangleShape2D> rect = shape;
	if (rect.is_valid()) {
		draw_dashed_rectangle(
				p_canvas, p_position, rect->get_size() / 2.0, is_rotated,
				p_color, p_dash_length, p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	UtilityFunctions::printerr(
			"Unsupported Shape2D type for draw_dashed_shape: " +
			shape->get_class());
}

void ScaffolderDrawUtils::draw_circle_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		Color p_color,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON &&
		p_border_width >
				0) { // Draw a point if radius is zero but border has width
		p_canvas->draw_circle(
				p_center, p_border_width / 2.0,
				p_color); // Draw a small filled circle
		return;
	}
	if (p_radius < CMP_EPSILON)
		return;

	PackedVector2Array points = compute_arc_points(
			p_center, p_radius, 0.0, tau, p_sector_arc_length);
	if (points.size() < 2)
		return;

	// The GDScript fix for polyline gaps:
	PackedVector2Array final_points;
	final_points.push_back(
			points[0]); // Add P0 (which is also P_last due to TAU)
	final_points.append_array(points); // Add P0, P1, ..., P_last(=P0)
	// Now final_points = [P0, P0, P1, ..., P_last(=P0)]
	// The GDScript then does:
	// points.insert(0, points[0]); -> [P0, P0, P1, ..., P_last(=P0)]
	// points.push_back(points[0]); -> [P0, P0, P1, ..., P_last(=P0), P0]
	// points[points.size() - 2].y -= 0.0001; -> Modifies P_last(=P0)
	// points[1].y += 0.0001; -> Modifies the second P0
	// This is to make the segments (P0, P0_mod_y+) and (P_prev_to_last,
	// P_last_mod_y-) somewhat collinear for caps.

	// Using the draw_closed_polyline logic which is designed for this.
	draw_closed_polyline(
			p_canvas, points, p_color, p_border_width,
			false); // Antialiasing false by default in GDScript draw_polyline
}

void ScaffolderDrawUtils::draw_arc(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		Color p_color,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON)
		return;

	PackedVector2Array points = compute_arc_points(
			p_center, p_radius, p_start_angle, p_end_angle,
			p_sector_arc_length);
	if (points.size() < 2)
		return;
	p_canvas->draw_polyline(points, p_color, p_border_width);
}

PackedVector2Array ScaffolderDrawUtils::compute_arc_points(
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		double p_sector_arc_length) const {
	ERR_FAIL_COND_V_MSG(
			p_sector_arc_length <= 0.0, PackedVector2Array(),
			"Sector arc length must be positive.");
	ERR_FAIL_COND_V_MSG(
			p_radius < 0.0, PackedVector2Array(), "Radius cannot be negative.");

	if (p_radius < CMP_EPSILON) {
		PackedVector2Array single_point;
		single_point.push_back(p_center);
		return single_point;
	}

	double angle_diff = p_end_angle - p_start_angle;
	if (std::abs(angle_diff) < CMP_EPSILON) { // Very small or zero angle diff
		PackedVector2Array p;
		p.push_back(
				p_center +
				Vector2(Math::cos(p_start_angle), Math::sin(p_start_angle)) *
						p_radius);
		return p;
	}

	// Ensure delta_theta has the correct sign for the direction of the arc
	double delta_theta_abs = p_sector_arc_length / p_radius;
	double delta_theta = (angle_diff < 0) ? -delta_theta_abs : delta_theta_abs;

	// Calculate sector_count based on the absolute angle_diff and absolute
	// delta_theta
	int sector_count = static_cast<int>(
			std::floor(std::abs(angle_diff) / delta_theta_abs));
	if (sector_count < 0)
		sector_count = 0;

	PackedVector2Array points;
	double theta = p_start_angle;

	for (int i = 0; i <= sector_count; ++i) {
		points.push_back(
				p_center +
				Vector2(Math::cos(theta), Math::sin(theta)) * p_radius);
		theta += delta_theta;
	}

	// Ensure the very last point is at end_angle if not perfectly divisible
	// Check if the last computed theta is close to end_angle or if we need to
	// add end_angle explicitly
	double last_computed_angle = p_start_angle + sector_count * delta_theta;
	if (std::abs(last_computed_angle - p_end_angle) >
		CMP_EPSILON * std::abs(delta_theta)) { // If not close enough
		if (points.is_empty() ||
			!points[points.size() - 1].is_equal_approx(
					p_center +
					Vector2(Math::cos(p_end_angle), Math::sin(p_end_angle)) *
							p_radius)) {
			points.push_back(
					p_center +
					Vector2(Math::cos(p_end_angle), Math::sin(p_end_angle)) *
							p_radius);
		}
	} else if (!points.is_empty()) { // If close enough, set the last point
									 // exactly to end_angle
		points.set(
				points.size() - 1,
				p_center +
						Vector2(Math::cos(p_end_angle),
								Math::sin(p_end_angle)) *
								p_radius);
	}

	if (points.is_empty()) { // Should only happen if sector_count was 0 and
							 // end_angle was not added
		points.push_back(
				p_center +
				Vector2(Math::cos(p_start_angle), Math::sin(p_start_angle)) *
						p_radius);
		if (std::abs(p_start_angle - p_end_angle) > CMP_EPSILON) {
			points.push_back(
					p_center +
					Vector2(Math::cos(p_end_angle), Math::sin(p_end_angle)) *
							p_radius);
		}
	}

	return points;
}

void ScaffolderDrawUtils::draw_rectangle_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		Vector2 p_half_width_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_thickness) const {
	if (!p_canvas)
		return;
	double x_offset = p_is_rotated_90_degrees ? p_half_width_height.y
											  : p_half_width_height.x;
	double y_offset = p_is_rotated_90_degrees ? p_half_width_height.x
											  : p_half_width_height.y;

	PackedVector2Array polyline;
	// Order: P0, P1, P2, P3, P0_again (for draw_polyline to close it)
	// The GDScript version uses a trick by starting/ending in middle of a
	// segment. P1, P2, P3, P4, P_mid_P4_P1, P_mid_P4_P1 (6 points) Let's
	// replicate that.
	Vector2 p1 = p_center + Vector2(-x_offset, -y_offset);
	Vector2 p2 = p_center + Vector2(x_offset, -y_offset);
	Vector2 p3 = p_center + Vector2(x_offset, y_offset);
	Vector2 p4 = p_center + Vector2(-x_offset, y_offset);

	polyline.resize(6);
	polyline.set(1, p1);
	polyline.set(2, p2);
	polyline.set(3, p3);
	polyline.set(4, p4);
	polyline.set(
			5, p1.lerp(p4, 0.5)); // GDScript was lerp(polyline[4], polyline[1],
								  // 0.5) which is p4.lerp(p1, 0.5). Same point.
	polyline.set(0, polyline[5]);

	p_canvas->draw_polyline(polyline, p_color, p_thickness);
}

void ScaffolderDrawUtils::draw_capsule_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_thickness,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0, "Radius cannot be negative.");
	ERR_FAIL_COND_MSG(p_height < 0, "Height cannot be negative.");
	if (p_radius < CMP_EPSILON && p_height < CMP_EPSILON)
		return; // Nothing to draw

	// Calculate centers of the two semicircles
	Vector2 end_offset_dir =
			p_is_rotated_90_degrees ? Vector2(0.0, 1.0) : Vector2(1.0, 0.0);
	Vector2 c1 = p_center - end_offset_dir * (p_height / 2.0);
	Vector2 c2 = p_center + end_offset_dir * (p_height / 2.0);

	// Angles for the semicircles
	double start_angle1, end_angle1, start_angle2, end_angle2;
	if (p_is_rotated_90_degrees) { // Vertical capsule
		start_angle1 = pi;
		end_angle1 = tau; // Top semicircle (c1 is upper)
		start_angle2 = 0.0;
		end_angle2 = pi; // Bottom semicircle (c2 is lower)
	} else { // Horizontal capsule
		start_angle1 = pi / 2.0;
		end_angle1 = pi * 3.0 / 2.0; // Left semicircle (c1 is left)
		start_angle2 = -pi / 2.0;
		end_angle2 = pi / 2.0; // Right semicircle (c2 is right)
	}

	PackedVector2Array arc1_points = compute_arc_points(
			c1, p_radius, start_angle1, end_angle1, p_sector_arc_length);
	PackedVector2Array arc2_points = compute_arc_points(
			c2, p_radius, start_angle2, end_angle2, p_sector_arc_length);

	PackedVector2Array polyline;
	if (arc1_points.size() > 0)
		polyline.append_array(arc1_points);
	if (arc2_points.size() > 0)
		polyline.append_array(arc2_points);

	if (polyline.size() < 2)
		return; // Not enough points to draw

	// Close the polyline using the draw_closed_polyline method for better caps
	draw_closed_polyline(p_canvas, polyline, p_color, p_thickness, false);
}

void ScaffolderDrawUtils::draw_ice_cream_cone(
		CanvasItem *p_canvas,
		Vector2 p_cone_end_point,
		Vector2 p_circle_center,
		double p_circle_radius,
		Color p_color,
		bool p_is_filled,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(
			p_circle_radius < 0.0, "Circle radius cannot be negative.");

	double distance_to_circle_center =
			p_cone_end_point.distance_to(p_circle_center);

	if (p_circle_radius <= CMP_EPSILON) {
		p_canvas->draw_line(
				p_circle_center, p_cone_end_point, p_color, p_border_width,
				false);
		return;
	}
	if (distance_to_circle_center <= p_circle_radius +
				CMP_EPSILON) { // cone_end_point is inside or on the circle
		if (p_is_filled) {
			p_canvas->draw_circle(p_circle_center, p_circle_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, p_circle_center, p_circle_radius, p_color,
					p_border_width, p_sector_arc_length);
		}
		return;
	}

	double angle_to_cone_tip_from_circle_center =
			(p_cone_end_point - p_circle_center)
					.angle(); // angle of vector from circle_center to
							  // cone_end_point
	double angle_offset_to_tangency =
			std::acos(p_circle_radius / distance_to_circle_center);

	double tangent_angle1 =
			angle_to_cone_tip_from_circle_center + angle_offset_to_tangency;
	double tangent_angle2 =
			angle_to_cone_tip_from_circle_center - angle_offset_to_tangency;

	// Arc is from tangent_angle1 to tangent_angle2 (or vice versa depending on
	// winding) The GDScript uses start_angle =
	// angle_from_circle_center_to_cone_end_point +
	// angle_from_circle_center_to_point_of_tangency end_angle =
	// angle_from_circle_center_to_cone_end_point + 2.0 * PI -
	// angle_from_circle_center_to_point_of_tangency This means the arc covers
	// the "far side" of the circle from the cone point.
	double base_angle =
			(p_cone_end_point - p_circle_center)
					.angle(); // angle_from_circle_center_to_cone_end_point in
							  // GDScript was angle_to_point(circle_center) from
							  // cone_end_point which is (circle_center -
							  // cone_end_point).angle()
	base_angle = (p_circle_center - p_cone_end_point)
						 .angle(); // This is
								   // angle_from_cone_end_point_to_circle_center
								   // We need angle from circle center towards
								   // cone end point, then add/sub offset. Let
								   // vector D = cone_end_point - circle_center.
								   // Angle is D.angle(). Tangent points are
								   // circle_center + R * (cos(D.angle() +/-
								   // offset), sin(D.angle() +/- offset))
	// Let's use the GDScript's angle definitions:
	double angle_from_circle_center_to_cone_end_point =
			(p_cone_end_point - p_circle_center)
					.angle(); // This is what GDScript's
							  // `cone_end_point.angle_to_point(circle_center)`
							  // means if origin is cone_end_point. If origin is
							  // (0,0), then (circle_center -
							  // cone_end_point).angle(). The GDScript
							  // `cone_end_point.angle_to_point(circle_center)`
							  // is `(circle_center - cone_end_point).angle()`.
	angle_from_circle_center_to_cone_end_point =
			(p_circle_center - p_cone_end_point)
					.angle(); // Angle of vector from cone_end_point to
							  // circle_center

	// The arc should be on the side of the circle visible from cone_end_point.
	// The points of tangency are P_t1, P_t2.
	// The arc is between P_t1 and P_t2 on the circle.
	// The polygon is P_cone_end_point, P_t1, arc points, P_t2.

	// Recalculate angles for the arc part:
	// Angle of vector from circle_center to cone_end_point
	double angle_cc_to_cep = (p_cone_end_point - p_circle_center).angle();
	double arc_start_angle =
			angle_cc_to_cep - angle_offset_to_tangency; // One tangent point
	double arc_end_angle =
			angle_cc_to_cep + angle_offset_to_tangency; // Other tangent point

	// Ensure arc_end_angle is greater than arc_start_angle for
	// compute_arc_points convention Or ensure compute_arc_points handles
	// angle_diff correctly. The GDScript logic for start/end angle implies a
	// large arc. start_angle := angle_from_circle_center_to_cone_end_point +
	// angle_from_circle_center_to_point_of_tangency end_angle :=
	// angle_from_circle_center_to_cone_end_point + 2.0 * PI -
	// angle_from_circle_center_to_point_of_tangency This means the arc is the
	// major arc.
	double gd_angle_from_circle_center_to_cone_end_point =
			(p_cone_end_point - p_circle_center)
					.angle(); // angle of vector from circle center to cone end
							  // point
	double gd_start_angle = gd_angle_from_circle_center_to_cone_end_point +
			angle_offset_to_tangency;
	double gd_end_angle = gd_angle_from_circle_center_to_cone_end_point + tau -
			angle_offset_to_tangency;

	PackedVector2Array arc_points = compute_arc_points(
			p_circle_center, p_circle_radius, gd_start_angle, gd_end_angle,
			p_sector_arc_length);

	PackedVector2Array polygon_points;
	// The GDScript logic for extra points:
	// points.push_back(extra_cone_end_point_1)
	// points.push_back(cone_end_point)
	// points.push_back(extra_cone_end_point_2)
	// points.push_back(points[0]) -> This closes with the start of the arc.
	// The arc_points are already in order.
	// Polygon should be: cone_end_point, then one end of arc, then arc points,
	// then other end of arc.

	polygon_points.append_array(arc_points); // Arc points first

	// The GDScript `extra_cone_end_point` logic is to make the tip sharp for
	// polyline drawing. For `draw_colored_polygon`, it might not be strictly
	// necessary if the points are ordered correctly. Order:
	// arc_points[0]...arc_points[N-1], cone_end_point
	if (!arc_points.is_empty()) {
		Vector2 extra_cone_end_point_1 = p_cone_end_point +
				(arc_points[arc_points.size() - 1] - p_cone_end_point) *
						0.000001;
		Vector2 extra_cone_end_point_2 = p_cone_end_point +
				(arc_points[0] - p_cone_end_point) * 0.000001;

		polygon_points.push_back(extra_cone_end_point_1);
		polygon_points.push_back(p_cone_end_point);
		polygon_points.push_back(extra_cone_end_point_2);
		// The GDScript `points.push_back(points[0])` closes it with the start
		// of the arc. This is already handled if arc_points form a part of the
		// polygon.
	} else { // Should not happen if radius > 0 and cone is outside
		polygon_points.push_back(p_cone_end_point);
	}

	if (p_is_filled) {
		if (polygon_points.size() >= 3) {
			p_canvas->draw_polygon(
					polygon_points,
					PackedColorArray::make(p_color)); // draw_polygon for filled
		}
	} else {
		// For outline, we need to draw the two tangent lines and the arc
		if (!arc_points.is_empty()) {
			p_canvas->draw_line(
					p_cone_end_point, arc_points[0], p_color, p_border_width);
			p_canvas->draw_polyline(arc_points, p_color, p_border_width);
			p_canvas->draw_line(
					p_cone_end_point, arc_points[arc_points.size() - 1],
					p_color, p_border_width);
		} else {
			p_canvas->draw_line(
					p_cone_end_point, p_circle_center, p_color,
					p_border_width); // Fallback if no arc points
		}
	}
}

void ScaffolderDrawUtils::_bind_methods() {
	// Binding all methods to make them callable from GDScript
	ClassDB::bind_method(
			D_METHOD(
					"draw_closed_polyline", "p_canvas", "p_points", "p_color",
					"p_stroke_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_closed_polyline, DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_line", "p_canvas", "p_from", "p_to", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset", "p_width",
					"p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_line, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_polyline", "p_canvas", "p_vertices", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset", "p_width",
					"p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_polyline, DEFVAL(0.0),
			DEFVAL(1.0), DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_rectangle", "p_canvas", "p_center",
					"p_half_width_height", "p_is_rotated_90_degrees", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_stroke_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_rectangle, DEFVAL(0.0),
			DEFVAL(1.0), DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_circle", "p_canvas", "p_center", "p_radius",
					"p_color", "p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_circle, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_arc", "p_canvas", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_color", "p_dash_length",
					"p_dash_gap", "p_dash_offset", "p_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_arc, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_capsule", "p_canvas", "p_center", "p_radius",
					"p_height", "p_is_rotated_90_degrees", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_thickness", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_capsule, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_x", "p_canvas", "p_center", "p_width", "p_height",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_x);
	ClassDB::bind_method(
			D_METHOD(
					"draw_plus", "p_canvas", "p_center", "p_width", "p_height",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_plus);
	ClassDB::bind_method(
			D_METHOD(
					"draw_asterisk", "p_canvas", "p_center", "p_width",
					"p_height", "p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_asterisk);
	ClassDB::bind_method(
			D_METHOD(
					"draw_checkmark", "p_canvas", "p_position", "p_width",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_checkmark);
	ClassDB::bind_method(
			D_METHOD(
					"draw_exclamation_mark", "p_canvas", "p_center", "p_width",
					"p_length", "p_color", "p_is_filled", "p_stroke_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_exclamation_mark, DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_arrow", "p_canvas", "p_start", "p_end",
					"p_head_length", "p_head_width", "p_color",
					"p_stroke_width"),
			&ScaffolderDrawUtils::draw_arrow);
	ClassDB::bind_method(
			D_METHOD(
					"draw_strike_through_arrow", "p_canvas", "p_start", "p_end",
					"p_head_length", "p_head_width", "p_strike_through_length",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_strike_through_arrow);
	ClassDB::bind_method(
			D_METHOD(
					"draw_diamond_outline", "p_canvas", "p_center", "p_width",
					"p_height", "p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_diamond_outline);
	ClassDB::bind_method(
			D_METHOD(
					"draw_shape_outline", "p_canvas", "p_position",
					"p_shape_data", "p_color", "p_thickness"),
			&ScaffolderDrawUtils::draw_shape_outline);
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_shape", "p_canvas", "p_position",
					"p_shape_data", "p_color", "p_dash_length", "p_dash_gap",
					"p_dash_offset", "p_thickness"),
			&ScaffolderDrawUtils::draw_dashed_shape, DEFVAL(0.0), DEFVAL(1.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_circle_outline", "p_canvas", "p_center", "p_radius",
					"p_color", "p_border_width", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_circle_outline, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_arc", "p_canvas", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_color", "p_border_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_arc, DEFVAL(1.0), DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"compute_arc_points", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_sector_arc_length"),
			&ScaffolderDrawUtils::compute_arc_points, DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_rectangle_outline", "p_canvas", "p_center",
					"p_half_width_height", "p_is_rotated_90_degrees", "p_color",
					"p_thickness"),
			&ScaffolderDrawUtils::draw_rectangle_outline, DEFVAL(1.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_capsule_outline", "p_canvas", "p_center", "p_radius",
					"p_height", "p_is_rotated_90_degrees", "p_color",
					"p_thickness", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_capsule_outline, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_ice_cream_cone", "p_canvas", "p_cone_end_point",
					"p_circle_center", "p_circle_radius", "p_color",
					"p_is_filled", "p_border_width", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_ice_cream_cone, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_smooth_segment_with_two_circular_ends", "p_canvas",
					"p_center_1", "p_radius_1", "p_center_2", "p_radius_2",
					"p_color", "p_is_filled", "p_stroke_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_smooth_segment_with_two_circular_ends,
			DEFVAL(4.0));
}

// -----------------------

ScaffolderDrawUtils::ScaffolderDrawUtils() {
	// GDScript: Sc.log_service.report_submodule_initialized(self,
	// "ScaffolderDrawUtils") This would be replaced by your C++ project's
	// logging/initialization mechanism if needed.
	// UtilityFunctions::print("ScaffolderDrawUtils initialized.");
}

ScaffolderDrawUtils::~ScaffolderDrawUtils() {}

void ScaffolderDrawUtils::draw_closed_polyline(
		CanvasItem *p_canvas,
		PackedVector2Array p_points,
		Color p_color,
		double p_stroke_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	int original_size = p_points.size();
	ERR_FAIL_COND_MSG(
			original_size < 2,
			"draw_closed_polyline requires at least 2 points.");

	if (original_size == 2) {
		p_canvas->draw_line(
				p_points[0], p_points[1], p_color, p_stroke_width,
				p_antialiased);
		return;
	}

	// PackedVector2Array p_points is passed by value, so modifications are
	// local.
	p_points.insert(
			0, p_points[0]); // Duplicates the first point at the beginning

	if (p_points[0].is_equal_approx(
				p_points[original_size])) { // original_size is now index of
											// original last point
		p_points.push_back(
				p_points[0]); // original_size was old size, points[0] is the
							  // very first original point
	} else {
		// original_size + 1 is current size after insert
		// original_size + 2 for new size
		// original_size + 3 for new size
		p_points.resize(
				original_size +
				3); // After insert(0, points[0]), size is original_size + 1
					// points[original_size] was the original last point.
					// points[original_size+1] is new slot
					// points[original_size+2] is new slot
		// The GDScript logic:
		// points.insert(0, points[0]) -> size = original_size + 1. points[0] is
		// new, points[1] is original points[0]. if points[1] ==
		// points[original_size]: (original_size is index of last element of
		// original array)
		//    points.push_back(points[1])
		// else:
		//    points.resize(original_size + 3) // This seems off. If
		//    original_size = 3, insert makes it 4. resize(6).
		//    points[original_size+1] = points[1] // points[4] = points[1]
		//    points[original_size+2] = points[1] // points[5] = points[1]

		// Let's re-evaluate GDScript logic carefully:
		// 1. `points.insert(0, points[0])` -> `current_points` has
		// `original_points[0]` at index 0, and original `points` from index 1.
		// Size = `original_size + 1`.
		//    `current_points[0]` is a copy of `original_points[0]`.
		//    `current_points[1]` is `original_points[0]`.
		//    `current_points[original_size]` is `original_points[original_size
		//    - 1]`.
		//
		// Corrected interpretation:
		// `p_points.insert(0, p_points[0]);` // p_points[0] is now a duplicate
		// of the original p_points[0]. The original p_points[0] is now at
		// p_points[1]. The original p_points[original_size-1] is now at
		// p_points[original_size]. Size is original_size + 1.

		// if p_points[1] == p_points[original_size]: (Comparing original first
		// and original last)
		//    p_points.push_back(p_points[1]); // Add original first again at
		//    the end.
		// else:
		//    p_points.resize(original_size + 3); // Current size is
		//    original_size + 1. This adds 2 slots. p_points[original_size + 1]
		//    = p_points[1]; // original_first p_points[original_size + 2] =
		//    p_points[1]; // original_first

		// Let's use a clearer approach for C++ based on intent:
		// We need a list like: P0_copy, P0, P1, ..., Pn-1, P0_copy,
		// P0_another_copy if P0 == Pn-1, then: P0_copy, P0, P1, ..., Pn-1(=P0),
		// P0_copy The goal is to make the polyline wrap around smoothly.
		// GDScript:
		// points.insert(0, points[0]) -> effectively prepends current points[0]
		// if points[0] == points[original_size]: (original_size is now the
		// index of the last element of the *modified* array, which was the
		// original last element)
		//    points.push_back(points[0])
		// else:
		//    points.resize(original_size + 3) // original_size is the size
		//    *before* insert. points[original_size] = points[0] // This is
		//    where it gets tricky. points[original_size + 1] = points[0]

		// Let's simplify based on the final structure needed for draw_polyline:
		// P_adj_start, P_start, P1, ..., P_end, P_adj_end
		// where P_adj_start and P_adj_end help close the loop.
		// The GDScript code is a bit convoluted. The final polyline sent to
		// draw_polyline is: [P0_offset_A, P0, P1, ..., P_last, P0_offset_B]
		// where P0_offset_A and P0_offset_B are modified. And P_last might be
		// P0 if it was already closed.

		// Sticking to direct port of the array manipulation:
		PackedVector2Array temp_points = p_points; // original points
		p_points.clear();
		p_points.push_back(temp_points[0]); // Prepend first element
		p_points.append_array(temp_points); // Add all original elements

		// Now p_points is [orig_P0, orig_P0, orig_P1, ..., orig_P_last]. Size =
		// original_size + 1. orig_P0 is at p_points[0] and p_points[1].
		// orig_P_last is at p_points[original_size].

		if (p_points[1].is_equal_approx(
					p_points[original_size])) { // If original_first ==
												// original_last
			p_points.push_back(p_points[1]); // Add original_first to the end
		} else {
			// Current size is original_size + 1. Need to make it original_size
			// + 3. This means adding two elements.
			p_points.push_back(p_points[1]); // Add original_first
			p_points.push_back(p_points[1]); // Add original_first again
		}
	}
	// At this point, p_points should have a structure that draw_polyline can
	// use by modifying its first (index 1 after offset) and last-but-one
	// (new_size-2) points.

	int new_size = p_points.size();
	ERR_FAIL_COND_MSG(
			new_size < 4,
			"Internal error in draw_closed_polyline point setup."); // Minimum
																	// for
																	// P_adj,
																	// P0,
																	// P_last_or_P0,
																	// P_adj

	Vector2 tangentish_direction =
			p_points[2] - p_points[1]; // Based on (original P1 - original P0)
	Vector2 offset = tangentish_direction * 0.00001;
	p_points.set(
			0,
			p_points[1] +
					offset); // Modify the prepended point (was copy of P0)
	p_points.set(
			new_size - 1,
			p_points[new_size - 2] -
					offset); // Modify the appended point (was copy of P0)

	// The GDScript logic for points[1] and points[new_size-2] was:
	// points[1] = points[0] + offset  (here points[0] is the *original*
	// points[0]) points[new_size - 2] = points[0] - offset This means the
	// points that form the actual start/end of the visible polyline are
	// adjusted. The polyline passed to draw_polyline is [adj_start, P0_mod, P1,
	// ..., P_last_mod, adj_end] Let's re-verify the GDScript: `points.insert(0,
	// points[0])` -> `points` is now `[P0_orig, P0_orig, P1_orig, ...]`
	// `points[1] = points[0] + offset` -> `points` is `[P0_orig, P0_orig +
	// offset, P1_orig, ...]` This seems to modify the *second* element. The
	// intent is to make the segments (points[0],points[1]) and
	// (points[N-2],points[N-1]) collinear with the main body. The polyline
	// drawn is from points[0] to points[N-1]. The fix is for the caps at
	// points[0] and points[N-1]. The GDScript `points.insert(0, points[0])` and
	// `points.push_back(points[0])` (effectively) creates `[P0, P0, P1, ...,
	// P_last, P0]`. Then `points[1]` (the second P0) and `points[new_size-2]`
	// (P_last) are modified. This means the actual polyline drawn is `[P0,
	// P0_mod, P1, ..., P_last_mod, P0]`.

	// Simpler: create the final array structure directly.
	PackedVector2Array final_polyline;
	final_polyline.push_back(p_points[0]); // P0
	final_polyline.append_array(p_points); // P0, P0, P1, ..., P_last
	if (!p_points[0].is_equal_approx(p_points[p_points.size() - 1])) {
		final_polyline.push_back(p_points[0]); // P0, P0, P1, ..., P_last, P0
	}
	// Now final_polyline is [P0, P0, P1, ..., P_last (maybe P0), P0]
	// This is not matching the GDScript manipulation.

	// Let's use the version of p_points after the if/else block for push_backs.
	// `p_points` is now:
	// if closed: [orig_P0, orig_P0, P1, ..., P_last(=orig_P0), orig_P0]
	// if open:   [orig_P0, orig_P0, P1, ..., P_last, orig_P0, orig_P0]
	// new_size is its size.
	// `tangentish_direction = p_points[2] - p_points[1];` (orig_P1 - orig_P0)
	// `offset = tangentish_direction * 0.00001;`
	// `p_points[1] = p_points[0] + offset;` // This is WRONG. points[0] is
	// orig_P0. points[1] is orig_P0. Should be `p_points[1] = p_points[1] +
	// offset` if it's the point to shift. Or, `p_points[1] =
	// THE_ACTUAL_START_POINT_OF_POLYGON + offset`.
	// The GDScript `points[0]` in `points[1] = points[0] + offset` refers to
	// the *current* `points[0]`. After `points.insert(0, points[0])`,
	// `points[0]` and `points[1]` are identical (original `points[0]`). So
	// `points[1] = points[0] + offset` means `points[1]` becomes
	// `original_points[0] + offset`. And `points[new_size - 2] = points[0] -
	// offset` means `points[new_size-2]` becomes `original_points[0] - offset`.
	// This makes the start segment `(points[0], points[1])` -> `(original_P0,
	// original_P0 + offset)`. And end segment `(points[new_size-3],
	// points[new_size-2])` -> `(prev_to_last_adj, original_P0 - offset)`. And
	// the polyline is drawn with this modified `p_points`.

	// Re-porting the array manipulation carefully:
	PackedVector2Array poly_to_draw =
			p_points; // p_points is the input parameter
	int o_size = poly_to_draw.size();

	PackedVector2Array work_points;
	work_points.push_back(poly_to_draw[0]); // Add P0
	work_points.append_array(poly_to_draw); // Add P0, P1, ..., P_last. Now [P0,
											// P0, P1, ..., P_last]

	if (work_points[0].is_equal_approx(
				work_points[o_size])) { // If original P0 == original P_last
		work_points.push_back(work_points[0]); // Add P0 at end. Now [P0, P0,
											   // P1,...,P_last(=P0), P0]
	} else {
		work_points.push_back(work_points[0]); // Add P0
		work_points.push_back(
				work_points[0]); // Add P0. Now [P0, P0, P1,...,P_last, P0, P0]
	}
	// This matches the structure of `points` in GDScript after the if/else.
	// `work_points[0]` is original P0. `work_points[1]` is original P0.
	// `work_points[2]` is original P1.

	int current_size = work_points.size();
	if (current_size < 3) { // Should not happen with original_size >= 2
		p_canvas->draw_polyline(
				poly_to_draw, p_color, p_stroke_width, p_antialiased);
		return;
	}

	Vector2 actual_start_node =
			work_points[1]; // This is the node that starts the visible polygon.
	Vector2 actual_second_node = work_points[2];
	Vector2 actual_end_node =
			work_points[current_size - 2]; // This is the node that ends the
										   // visible polygon.
	Vector2 actual_prev_to_end_node = work_points[current_size - 3];

	Vector2 start_tangent_dir =
			(actual_second_node - actual_start_node).normalized();
	Vector2 end_tangent_dir =
			(actual_end_node - actual_prev_to_end_node)
					.normalized(); // Points from prev_to_end towards end

	work_points.set(
			0,
			actual_start_node -
					start_tangent_dir * 0.0001); // Adjust point before start
	work_points.set(
			current_size - 1,
			actual_end_node +
					end_tangent_dir * 0.0001); // Adjust point after end

	p_canvas->draw_polyline(
			work_points, p_color, p_stroke_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_line(
		CanvasItem *p_canvas,
		Vector2 p_from,
		Vector2 p_to,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_dash_length <= 0, "Dash length must be positive.");
	// ERR_FAIL_COND_MSG(p_dash_gap < 0, "Dash gap must be non-negative."); //
	// GDScript allows 0 gap

	double segment_length = p_from.distance_to(p_to);
	if (segment_length < CMP_EPSILON)
		return;
	Vector2 direction_normalized = (p_to - p_from).normalized();

	double current_pos_val = p_dash_offset;
	// Normalize dash_offset to be within one pattern length to avoid excessive
	// skipping
	double pattern_length = p_dash_length + p_dash_gap;
	if (pattern_length > CMP_EPSILON) {
		current_pos_val = std::fmod(p_dash_offset, pattern_length);
		if (current_pos_val < 0) {
			current_pos_val += pattern_length;
		}
	}

	while (current_pos_val < segment_length) {
		double dash_start_pos = current_pos_val;
		double dash_end_pos = current_pos_val + p_dash_length;

		if (dash_start_pos < segment_length) { // Only draw if some part of the
											   // dash is in the segment
			Vector2 current_from =
					p_from + direction_normalized * MAX(0.0, dash_start_pos);
			Vector2 current_to = p_from +
					direction_normalized * MIN(segment_length, dash_end_pos);

			if (current_to.distance_squared_to(current_from) >
				CMP_EPSILON_SQUARED) {
				p_canvas->draw_line(
						current_from, current_to, p_color, p_width,
						p_antialiased);
			}
		}
		current_pos_val += p_dash_length + p_dash_gap;
		if (p_dash_length + p_dash_gap <= CMP_EPSILON &&
			p_dash_length > CMP_EPSILON) { // Avoid infinite loop if gap is
										   // zero/negative
			break;
		}
	}
}

void ScaffolderDrawUtils::draw_dashed_polyline(
		CanvasItem *p_canvas,
		const PackedVector2Array &p_vertices,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	// The GDScript version's TODO about honoring gaps across vertices is
	// important. A simple loop like this will restart the dash pattern for each
	// segment. For a continuous dash pattern along the polyline, a more complex
	// approach is needed. Porting the existing behavior:
	double current_offset = p_dash_offset;
	for (int i = 0; i < p_vertices.size() - 1; ++i) {
		Vector2 from = p_vertices[i];
		Vector2 to = p_vertices[i + 1];
		draw_dashed_line(
				p_canvas, from, to, p_color, p_dash_length, p_dash_gap,
				current_offset, p_width, p_antialiased);

		// To attempt to continue the pattern (basic version, might not be
		// perfect):
		double segment_length = from.distance_to(to);
		if (p_dash_length + p_dash_gap > CMP_EPSILON) {
			current_offset = std::fmod(
					current_offset - segment_length,
					p_dash_length + p_dash_gap);
			if (current_offset < 0) { // ensure positive offset for next segment
				current_offset += (p_dash_length + p_dash_gap);
			}
		}
	}
}

void ScaffolderDrawUtils::draw_dashed_rectangle(
		CanvasItem *p_canvas,
		Vector2 p_center,
		Vector2 p_half_width_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_stroke_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	double half_width = p_is_rotated_90_degrees ? p_half_width_height.y
												: p_half_width_height.x;
	double half_height = p_is_rotated_90_degrees ? p_half_width_height.x
												 : p_half_width_height.y;

	Vector2 top_left = p_center + Vector2(-half_width, -half_height);
	Vector2 top_right = p_center + Vector2(half_width, -half_height);
	Vector2 bottom_right = p_center + Vector2(half_width, half_height);
	Vector2 bottom_left = p_center + Vector2(-half_width, half_height);

	PackedVector2Array rect_vertices;
	rect_vertices.push_back(top_left);
	rect_vertices.push_back(top_right);
	rect_vertices.push_back(bottom_right);
	rect_vertices.push_back(bottom_left);
	rect_vertices.push_back(top_left); // Close the loop for continuous dashing

	// Use draw_dashed_polyline to handle continuous dashing if implemented well
	draw_dashed_polyline(
			p_canvas, rect_vertices, p_color, p_dash_length, p_dash_gap,
			p_dash_offset, p_stroke_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_circle(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	draw_dashed_arc(
			p_canvas, p_center, p_radius, 0.0, tau, p_color, p_dash_length,
			p_dash_gap, p_dash_offset, p_width, p_antialiased);
}

void ScaffolderDrawUtils::draw_dashed_arc(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_width,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_dash_length <= 0.0, "Dash length must be positive.");
	ERR_FAIL_COND_MSG(p_radius < 0.0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON)
		return; // Nothing to draw for zero radius

	// Normalize angles
	p_start_angle = Math::fposmod(p_start_angle, tau);
	p_end_angle = Math::fposmod(p_end_angle, tau);
	if (p_end_angle <= p_start_angle &&
		std::abs(p_end_angle - p_start_angle) >
				CMP_EPSILON) { // Handle wrap around TAU for full circle or arc
							   // across 0
		if ((p_start_angle > p_end_angle) &&
			((p_start_angle - p_end_angle) <
			 pi)) { // Small arc crossing 0 backwards
			// This case is tricky, often draw_arc handles it by taking total
			// angle. For dashing, we need a consistent direction.
		} else {
			p_end_angle += tau;
		}
	}

	double total_arc_length = (p_end_angle - p_start_angle) * p_radius;
	if (total_arc_length <= CMP_EPSILON)
		return;

	double pattern_length = p_dash_length + p_dash_gap;
	ERR_FAIL_COND_MSG(
			pattern_length <= 0.0 && p_dash_length > 0,
			"Pattern length (dash + gap) must be positive if dash_length is "
			"positive.");

	double current_arc_pos = p_dash_offset;
	if (pattern_length > CMP_EPSILON) {
		current_arc_pos = std::fmod(p_dash_offset, pattern_length);
		if (current_arc_pos < 0) {
			current_arc_pos += pattern_length;
		}
	}

	while (current_arc_pos < total_arc_length) {
		double dash_start_arc = current_arc_pos;
		double dash_end_arc = current_arc_pos + p_dash_length;

		if (dash_start_arc < total_arc_length) {
			double angle1 = p_start_angle + MAX(0.0, dash_start_arc) / p_radius;
			double angle2 = p_start_angle +
					MIN(total_arc_length, dash_end_arc) / p_radius;

			if (angle2 >
				angle1 + CMP_EPSILON) { // Ensure there's an arc to draw
				// For short dashes, draw_line is fine. For longer ones,
				// draw_arc might be better if available. Godot's draw_arc draws
				// a filled sector part. We need a line. So, we approximate with
				// small line segments or use draw_polyline on arc points. For
				// simplicity, using draw_line between the two points on the
				// circle.
				Vector2 from_p = p_center +
						Vector2(Math::cos(angle1), Math::sin(angle1)) *
								p_radius;
				Vector2 to_p = p_center +
						Vector2(Math::cos(angle2), Math::sin(angle2)) *
								p_radius;
				p_canvas->draw_line(
						from_p, to_p, p_color, p_width, p_antialiased);
			}
		}
		current_arc_pos += pattern_length;
		if (pattern_length <= CMP_EPSILON && p_dash_length > CMP_EPSILON)
			break;
	}
}

void ScaffolderDrawUtils::draw_dashed_capsule(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_thickness,
		bool p_antialiased) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0, "Radius cannot be negative.");
	ERR_FAIL_COND_MSG(p_height < 0, "Height cannot be negative.");

	Vector2 dir = p_is_rotated_90_degrees ? Vector2(0, 1) : Vector2(1, 0);
	Vector2 line_half_vec = dir * (p_height / 2.0);

	Vector2 center1 = p_center - line_half_vec;
	Vector2 center2 = p_center + line_half_vec;

	double start_angle1, end_angle1, start_angle2, end_angle2;
	Vector2 p1_start, p1_end, p2_start, p2_end;

	if (p_is_rotated_90_degrees) {
		start_angle1 = pi;
		end_angle1 = tau; // Top semi-circle (0 to PI in Godot angles if
						  // center1 is top) Corrected: center1 is top, so
						  // angles PI to 2PI (TAU)
		start_angle2 = 0.0;
		end_angle2 = pi; // Bottom semi-circle

		p1_start = center1 + Vector2(p_radius, 0); // Right point of top arc
		p1_end = center2 + Vector2(p_radius, 0); // Right point of bottom arc
		p2_start = center2 + Vector2(-p_radius, 0); // Left point of bottom arc
		p2_end = center1 + Vector2(-p_radius, 0); // Left point of top arc
	} else { // Horizontal capsule
		start_angle1 = pi / 2.0;
		end_angle1 = pi * 3.0 / 2.0; // Left semi-circle
		start_angle2 = -pi / 2.0;
		end_angle2 = pi / 2.0; // Right semi-circle

		p1_start = center1 + Vector2(0, -p_radius); // Top point of left arc
		p1_end = center2 + Vector2(0, -p_radius); // Top point of right arc
		p2_start = center2 + Vector2(0, p_radius); // Bottom point of right arc
		p2_end = center1 + Vector2(0, p_radius); // Bottom point of left arc
	}

	// This needs to be a continuous dash pattern around the whole capsule.
	// The GDScript version calls draw_dashed_arc and draw_dashed_line
	// separately, which will restart the dash pattern. Porting existing
	// behavior:
	draw_dashed_arc(
			p_canvas, center1, p_radius, start_angle1, end_angle1, p_color,
			p_dash_length, p_dash_gap, p_dash_offset, p_thickness,
			p_antialiased);
	draw_dashed_arc(
			p_canvas, center2, p_radius, start_angle2, end_angle2, p_color,
			p_dash_length, p_dash_gap, p_dash_offset, p_thickness,
			p_antialiased);

	// Calculate offset for straight lines based on arc lengths
	double arc_len = pi * p_radius;
	double offset_line1 = p_dash_offset;
	if (p_dash_length + p_dash_gap > CMP_EPSILON) {
		offset_line1 =
				std::fmod(p_dash_offset - arc_len, p_dash_length + p_dash_gap);
		if (offset_line1 < 0)
			offset_line1 += (p_dash_length + p_dash_gap);
	}

	draw_dashed_line(
			p_canvas, p1_start, p1_end, p_color, p_dash_length, p_dash_gap,
			offset_line1, p_thickness, p_antialiased);

	double line_len = p_height;
	double offset_line2 = offset_line1;
	if (p_dash_length + p_dash_gap > CMP_EPSILON) {
		offset_line2 =
				std::fmod(offset_line1 - line_len, p_dash_length + p_dash_gap);
		if (offset_line2 < 0)
			offset_line2 += (p_dash_length + p_dash_gap);
	}
	// The second arc starts after the first line, so its offset also needs
	// adjustment. This is getting complicated to perfectly replicate continuous
	// dashing with separate calls. The GDScript itself doesn't guarantee
	// continuous dashing across these elements.

	draw_dashed_line(
			p_canvas, p2_start, p2_end, p_color, p_dash_length, p_dash_gap,
			offset_line2, p_thickness, p_antialiased);
}

void ScaffolderDrawUtils::draw_smooth_segment_with_two_circular_ends(
		CanvasItem *p_canvas,
		Vector2 p_center_1,
		double p_radius_1,
		Vector2 p_center_2,
		double p_radius_2,
		Color p_color,
		bool p_is_filled,
		double p_stroke_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(
			p_radius_1 < 0.0 || p_radius_2 < 0.0, "Radii cannot be negative.");

	Vector2 larger_center, smaller_center;
	double larger_radius, smaller_radius;

	if (p_radius_1 > p_radius_2) {
		larger_radius = p_radius_1;
		larger_center = p_center_1;
		smaller_radius = p_radius_2;
		smaller_center = p_center_2;
	} else {
		larger_radius = p_radius_2;
		larger_center = p_center_2;
		smaller_radius = p_radius_1;
		smaller_center = p_center_1;
	}

	double distance_between_circle_centers =
			smaller_center.distance_to(larger_center);

	if (larger_radius < CMP_EPSILON) { // Both radii are effectively zero
		p_canvas->draw_line(
				smaller_center, larger_center, p_color, p_stroke_width, false);
		return;
	}
	if (distance_between_circle_centers + smaller_radius <=
		larger_radius + CMP_EPSILON) {
		// Smaller circle is inside or tangent to the larger one. Draw the
		// larger circle.
		if (p_is_filled) {
			p_canvas->draw_circle(larger_center, larger_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, larger_center, larger_radius, p_color,
					p_stroke_width, p_sector_arc_length);
		}
		return;
	}
	if (smaller_radius < CMP_EPSILON) {
		// Degenerate case: An ice-cream-cone shape.
		draw_ice_cream_cone(
				p_canvas, smaller_center, larger_center, larger_radius, p_color,
				p_is_filled, p_stroke_width, p_sector_arc_length);
		return;
	}
	if (distance_between_circle_centers < CMP_EPSILON &&
		std::abs(larger_radius - smaller_radius) < CMP_EPSILON) {
		// Concentric circles of same size, draw one.
		if (p_is_filled) {
			p_canvas->draw_circle(larger_center, larger_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, larger_center, larger_radius, p_color,
					p_stroke_width, p_sector_arc_length);
		}
		return;
	}

	double angle_between_circle_centers =
			(larger_center - smaller_center)
					.angle(); // GD:
							  // smaller_center.angle_to_point(larger_center)
	double beta = 0.0;
	if (distance_between_circle_centers >
		CMP_EPSILON) { // Avoid division by zero if centers are same
		beta = Math::asin(
				(larger_radius - smaller_radius) /
				distance_between_circle_centers);
	}

	// GDScript angle logic:
	// var angle_from_circle_center_to_point_of_outer_tangency :=
	// angle_between_circle_centers - beta This is one of the two angles (from
	// center to tangent point) for the common tangent lines. The other is
	// angle_between_circle_centers + beta. The arcs are formed by points
	// *perpendicular* to these tangent lines at the circle circumference.

	double gd_smaller_start_angle =
			angle_between_circle_centers - beta + pi / 2.0;
	double gd_smaller_end_angle =
			angle_between_circle_centers + beta - pi / 2.0;

	double gd_larger_start_angle = gd_smaller_end_angle;
	double gd_larger_end_angle = gd_smaller_start_angle;

	// Adjust larger_end_angle for correct sweep direction, similar to GDScript
	if (gd_smaller_end_angle >
		gd_smaller_start_angle) { // This condition might need checking based on
								  // angle normalization
		// If standard angle normalization (0 to 2PI) makes end_angle >
		// start_angle for the desired sweep then the sweep for the larger
		// circle needs to be adjusted. The GDScript logic: if smaller_end_angle
		// > smaller_start_angle: larger_end_angle += 2.0 * PI else:
		// larger_end_angle -= 2.0 * PI This ensures that (larger_end_angle -
		// larger_start_angle) has a significant magnitude and correct
		// direction. My compute_arc_points uses (end_angle - start_angle) to
		// determine sweep. Let's ensure the angular difference for the second
		// arc continues the path. If smaller arc sweeps from A to B, larger arc
		// should sweep from B to A (on respective circles). A more robust way
		// for compute_arc_points is to ensure it always sweeps
		// counter-clockwise if end > start, and clockwise if end < start, over
		// the shortest path, unless end is explicitly start + k*TAU. The
		// GDScript logic seems to aim for a specific total sweep.

		// Let's ensure the sweep for the second arc is in the opposite
		// direction of the first arc's sweep, relative to the line connecting
		// centers, to form the other side of the shape. The GDScript logic
		// `larger_end_angle = smaller_start_angle` and then adjusting it by 2PI
		// effectively makes the larger arc cover the "other side".
		if ((gd_smaller_end_angle - gd_smaller_start_angle) >
			0) { // Assuming positive sweep for smaller
			if (gd_larger_end_angle > gd_larger_start_angle)
				gd_larger_end_angle -= tau;
		} else { // Assuming negative sweep for smaller
			if (gd_larger_end_angle < gd_larger_start_angle)
				gd_larger_end_angle += tau;
		}
		// A simpler way: ensure the total angular span of each arc is roughly
		// PI. The GDScript logic `if smaller_end_angle > smaller_start_angle:
		// larger_end_angle += 2PI else: larger_end_angle -=2PI` is to make sure
		// the `larger_end_angle` is on the "other side" of `larger_start_angle`
		// after a full circle adjustment. This is to make `compute_arc_points`
		// sweep over the major arc if needed. The angles `alpha +/- beta +/-
		// PI/2` define the four tangent points. The arcs connect these points.
		// Arc1: from (alpha - beta + PI/2) to (alpha + beta - PI/2) on smaller
		// circle. Arc2: from (alpha + beta - PI/2) to (alpha - beta + PI/2) on
		// larger circle. The GDScript `if smaller_end_angle >
		// smaller_start_angle` handles angle wrapping. If
		// `gd_smaller_end_angle` (alpha + beta - PI/2) is numerically greater
		// than `gd_smaller_start_angle` (alpha - beta + PI/2), it implies a
		// sweep that might be less than PI or crossing the 0/2PI boundary in a
		// certain way. The `compute_arc_points` should handle the sweep
		// correctly given start and end. The key is that `larger_start_angle`
		// is `gd_smaller_end_angle` and `larger_end_angle` is
		// `gd_smaller_start_angle`. We need to ensure `compute_arc_points`
		// sweeps correctly. If `gd_smaller_end_angle` is, say, 5PI/3 and
		// `gd_smaller_start_angle` is PI/3, then `compute_arc_points` for
		// smaller circle sweeps from PI/3 to 5PI/3. Then for larger circle,
		// `larger_start_angle` is 5PI/3 and `larger_end_angle` is PI/3.
		// `compute_arc_points` should sweep from 5PI/3 to PI/3 (e.g. 5PI/3 to
		// PI/3 + 2PI). My `compute_arc_points` calculates `angle_diff =
		// p_end_angle - p_start_angle`. If `p_end_angle < p_start_angle` (e.g.
		// PI/3 vs 5PI/3), `angle_diff` is negative. `delta_theta` becomes
		// negative. This is correct.
	}

	PackedVector2Array smaller_circle_arc_points = compute_arc_points(
			smaller_center, smaller_radius, gd_smaller_start_angle,
			gd_smaller_end_angle, p_sector_arc_length);
	PackedVector2Array larger_circle_arc_points = compute_arc_points(
			larger_center, larger_radius,
			gd_larger_start_angle, // This is smaller_end_angle
			gd_larger_end_angle, // This is smaller_start_angle
			p_sector_arc_length);

	int smaller_arc_count = smaller_circle_arc_points.size();
	int larger_arc_count = larger_circle_arc_points.size();

	ERR_FAIL_COND_MSG(
			smaller_arc_count + larger_arc_count < 2 && !p_is_filled,
			"Not enough points for polyline.");
	ERR_FAIL_COND_MSG(
			smaller_arc_count + larger_arc_count < 3 && p_is_filled,
			"Not enough points for polygon.");

	PackedVector2Array final_points;
	// The GDScript `points.resize(smaller_arc_count + larger_arc_count + 2)`
	// And then `points[i+1] = smaller_circle_arc_points[i]`
	// And `points[smaller_arc_count + i + 1] = larger_circle_arc_points[i]`
	// This means the actual points start at index 1 of the `final_points`
	// array. Index 0 and last index are for the polyline closing trick.

	final_points.resize(smaller_arc_count + larger_arc_count + 2);

	for (int i = 0; i < smaller_arc_count; ++i) {
		final_points.set(i + 1, smaller_circle_arc_points[i]);
	}
	for (int i = 0; i < larger_arc_count; ++i) {
		final_points.set(
				smaller_arc_count + i + 1, larger_circle_arc_points[i]);
	}

	// Ensure there are enough points for the trick.
	// The actual content is from final_points[1] to
	// final_points[smaller_arc_count + larger_arc_count]. The last valid data
	// point is at index `smaller_arc_count + larger_arc_count`. The point
	// before that is at `smaller_arc_count + larger_arc_count - 1`.
	if (final_points.size() <
		4) { // Need at least 2 content points + 2 padding for the trick to make
			 // sense e.g. P_trick_start, P_content1, P_content2, P_trick_end
		// Fallback for very few points (e.g., if arcs are single points)
		PackedVector2Array minimal_points;
		if (smaller_arc_count > 0)
			minimal_points.append_array(smaller_circle_arc_points);
		if (larger_arc_count > 0)
			minimal_points.append_array(larger_circle_arc_points);
		if (minimal_points.size() >= 2 && !p_is_filled) {
			p_canvas->draw_polyline(minimal_points, p_color, p_stroke_width);
		} else if (minimal_points.size() >= 3 && p_is_filled) {
			PackedColorArray colors;
			colors.push_back(p_color);
			p_canvas->draw_polygon(minimal_points, colors);
		} else if (minimal_points.size() == 1 && p_is_filled) {
			p_canvas->draw_circle(
					minimal_points[0], MAX(p_stroke_width / 2.0, 1.0), p_color);
		} else if (minimal_points.size() == 1 && !p_is_filled) {
			p_canvas->draw_circle(
					minimal_points[0], p_stroke_width / 2.0,
					p_color); // draw a point
		}
		return;
	}

	// Apply the polyline closing trick, similar to GDScript
	// `points[points.size() - 1] = lerp(points[points.size() - 2], points[1],
	// 0.5)` `points[0] = points[points.size() - 1]` Here, `points.size() - 2`
	// refers to the last actual content point. `points[1]` refers to the first
	// actual content point.
	final_points.set(
			final_points.size() - 1,
			final_points[final_points.size() - 2].linear_interpolate(
					final_points[1], 0.5));
	final_points.set(0, final_points[final_points.size() - 1]);

	if (p_is_filled) {
		// For draw_polygon, we don't need the polyline trick points (index 0
		// and size-1). We need a simple closed polygon from the content points.
		PackedVector2Array polygon_content_points;
		for (int i = 0; i < smaller_arc_count; ++i) {
			polygon_content_points.push_back(smaller_circle_arc_points[i]);
		}
		for (int i = 0; i < larger_arc_count; ++i) {
			polygon_content_points.push_back(larger_circle_arc_points[i]);
		}
		if (polygon_content_points.size() >= 3) {
			PackedColorArray colors;
			colors.push_back(p_color); // Single color for the whole polygon
			p_canvas->draw_polygon(polygon_content_points, colors);
		}
	} else {
		p_canvas->draw_polyline(final_points, p_color, p_stroke_width);
	}
}
// ... (ensure includes like iostream, cmath, and Godot headers are present)
// ... (ensure ScaffolderDrawUtils class definition and _bind_methods are set
// up)

// Assuming the following constants are defined in ScaffolderDrawUtils.h or
// accessible: static constexpr double STRIKE_THROUGH_ANGLE = -pi / 3.0;
// static constexpr double EXCLAMATION_MARK_GAP_LENGTH_TO_WIDTH_RATIO = 0.5;
// static constexpr double EXCLAMATION_MARK_BODY_LOWER_END_WIDTH_RATIO = 0.5;
// static constexpr double EXCLAMATION_MARK_DOT_WIDTH_RATIO = 1.0;

void ScaffolderDrawUtils::draw_x(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	p_canvas->draw_line(
			p_center + Vector2(-half_width, -half_height),
			p_center + Vector2(half_width, half_height), p_color,
			p_stroke_width);
	p_canvas->draw_line(
			p_center + Vector2(half_width, -half_height),
			p_center + Vector2(-half_width, half_height), p_color,
			p_stroke_width);
}

void ScaffolderDrawUtils::draw_plus(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	p_canvas->draw_line(
			p_center + Vector2(-half_width, 0),
			p_center + Vector2(half_width, 0), p_color, p_stroke_width);
	p_canvas->draw_line(
			p_center + Vector2(0, -half_height),
			p_center + Vector2(0, half_height), p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_asterisk(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double plus_width = p_width;
	double plus_height = p_height;
	double x_width = plus_width * 0.8;
	double x_height = plus_height * 0.8;
	draw_x(p_canvas, p_center, x_width, x_height, p_color, p_stroke_width);
	draw_plus(
			p_canvas, p_center, plus_width, plus_height, p_color,
			p_stroke_width);
}

void ScaffolderDrawUtils::draw_checkmark(
		CanvasItem *p_canvas,
		Vector2 p_position,
		double p_width,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	Vector2 top_left_point =
			p_position + Vector2(-p_width / 3.0, -p_width / 6.0);
	Vector2 bottom_mid_point = p_position + Vector2(0, p_width / 6.0);
	Vector2 top_right_point =
			p_position + Vector2(p_width * 2.0 / 3.0, -p_width / 2.0 * 1.33);

	Vector2 slight_horizontal_offset = Vector2(0.001, 0.0);

	PackedVector2Array vertices;
	vertices.push_back(top_left_point);
	vertices.push_back(bottom_mid_point - slight_horizontal_offset);
	vertices.push_back(bottom_mid_point + slight_horizontal_offset);
	vertices.push_back(top_right_point);

	p_canvas->draw_polyline(vertices, p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_exclamation_mark(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_length,
		Color p_color,
		bool p_is_filled,
		double p_stroke_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_length = p_length / 2.0;

	double body_top_radius = half_width;
	double body_bottom_radius =
			body_top_radius * EXCLAMATION_MARK_BODY_LOWER_END_WIDTH_RATIO;
	double dot_radius = body_top_radius * EXCLAMATION_MARK_DOT_WIDTH_RATIO;

	double gap_length = p_width * EXCLAMATION_MARK_GAP_LENGTH_TO_WIDTH_RATIO;
	double body_length = p_length - gap_length - dot_radius * 2.0;

	ERR_FAIL_COND_MSG(
			body_length < 0.0,
			"Exclamation mark body length is negative. Adjust dimensions.");

	Vector2 body_top_center =
			p_center + Vector2(0.0, -half_length + body_top_radius);
	Vector2 body_bottom_center = body_top_center +
			Vector2(0.0, body_length - body_top_radius - body_bottom_radius);
	Vector2 dot_center = p_center + Vector2(0.0, half_length - dot_radius);

	if (p_is_filled) {
		p_canvas->draw_circle(dot_center, dot_radius, p_color);
	} else {
		draw_circle_outline(
				p_canvas, dot_center, dot_radius, p_color, p_stroke_width,
				p_sector_arc_length);
	}

	draw_smooth_segment_with_two_circular_ends(
			p_canvas, body_top_center, body_top_radius, body_bottom_center,
			body_bottom_radius, p_color, p_is_filled, p_stroke_width,
			p_sector_arc_length);
}

void ScaffolderDrawUtils::draw_arrow(
		CanvasItem *p_canvas,
		Vector2 p_start,
		Vector2 p_end,
		double p_head_length,
		double p_head_width,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	draw_strike_through_arrow(
			p_canvas, p_start, p_end, p_head_length, p_head_width,
			Math_INF, // Use Godot's INF
			p_color, p_stroke_width);
}

void ScaffolderDrawUtils::draw_strike_through_arrow(
		CanvasItem *p_canvas,
		Vector2 p_start,
		Vector2 p_end,
		double p_head_length,
		double p_head_width,
		double p_strike_through_length,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;

	double start_to_end_angle = p_start.angle_to_point(p_end);
	Vector2 head_diff_1 = Vector2(p_head_length, -p_head_width * 0.5)
								  .rotated(start_to_end_angle);
	Vector2 head_diff_2 = Vector2(p_head_length, p_head_width * 0.5)
								  .rotated(start_to_end_angle);
	Vector2 head_barb_end_1 = p_end + head_diff_1;
	Vector2 head_barb_end_2 = p_end + head_diff_2;

	p_canvas->draw_line(p_end, head_barb_end_1, p_color, p_stroke_width);
	p_canvas->draw_line(p_end, head_barb_end_2, p_color, p_stroke_width);
	p_canvas->draw_line(p_start, p_end, p_color, p_stroke_width); // Arrow body

	if (!Math::is_inf(p_strike_through_length) && p_strike_through_length > 0) {
		double strike_through_angle = start_to_end_angle +
				STRIKE_THROUGH_ANGLE; // STRIKE_THROUGH_ANGLE should be a class
									  // const
		Vector2 strike_through_middle = p_start.linear_interpolate(p_end, 0.5);
		double strike_through_half_length = p_strike_through_length / 2.0;
		Vector2 strike_through_offset = Vector2(
				Math::cos(strike_through_angle) * strike_through_half_length,
				Math::sin(strike_through_angle) * strike_through_half_length);
		Vector2 strike_through_start =
				strike_through_middle - strike_through_offset;
		Vector2 strike_through_end =
				strike_through_middle + strike_through_offset;
		p_canvas->draw_line(
				strike_through_start, strike_through_end, p_color,
				p_stroke_width);
	}
}

void ScaffolderDrawUtils::draw_diamond_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_width,
		double p_height,
		Color p_color,
		double p_stroke_width) const {
	if (!p_canvas)
		return;
	double half_width = p_width / 2.0;
	double half_height = p_height / 2.0;
	Vector2 p1 = p_center + Vector2(-half_width, 0);
	Vector2 p2 = p_center + Vector2(0, -half_height);
	Vector2 p3 = p_center + Vector2(half_width, 0);
	Vector2 p4 = p_center + Vector2(0, half_height);
	p_canvas->draw_line(p1, p2, p_color, p_stroke_width);
	p_canvas->draw_line(p2, p3, p_color, p_stroke_width);
	p_canvas->draw_line(p3, p4, p_color, p_stroke_width);
	p_canvas->draw_line(p4, p1, p_color, p_stroke_width);
}

// Assumes RotatedShapeData class is defined as in previous responses
// (in scaffolder_draw_utils.h or accessible)
// class RotatedShapeData : public RefCounted { ... Ref<Shape2D> shape; bool
// is_rotated_90_degrees; ... }
void ScaffolderDrawUtils::draw_shape_outline(
		CanvasItem *p_canvas,
		Vector2 p_position,
		const Ref<RotatedShapeData> &p_shape_data,
		Color p_color,
		double p_thickness) const {
	if (!p_canvas || !p_shape_data.is_valid() ||
		!p_shape_data->get_shape().is_valid()) {
		UtilityFunctions::printerr(
				"ScaffolderDrawUtils::draw_shape_outline: Invalid shape data "
				"provided.");
		return;
	}
	Ref<Shape2D> shape = p_shape_data->get_shape();
	bool is_rotated = p_shape_data->get_is_rotated_90_degrees();

	Ref<CircleShape2D> circle = shape;
	if (circle.is_valid()) {
		draw_circle_outline(
				p_canvas, p_position, circle->get_radius(), p_color,
				p_thickness);
		return;
	}
	Ref<CapsuleShape2D> capsule = shape;
	if (capsule.is_valid()) {
		draw_capsule_outline(
				p_canvas, p_position, capsule->get_radius(),
				capsule->get_height(), is_rotated, p_color, p_thickness);
		return;
	}
	Ref<RectangleShape2D> rect_shape =
			shape; // Renamed to avoid conflict with Rect2
	if (rect_shape.is_valid()) {
		// RectangleShape2D::get_size() returns full size,
		// draw_rectangle_outline expects half_width_height
		draw_rectangle_outline(
				p_canvas, p_position, rect_shape->get_size() / 2.0, is_rotated,
				p_color, p_thickness);
		return;
	}
	UtilityFunctions::printerr(
			"ScaffolderDrawUtils::draw_shape_outline: Unsupported Shape2D "
			"type: ",
			shape->get_class());
}

void ScaffolderDrawUtils::draw_dashed_shape(
		CanvasItem *p_canvas,
		Vector2 p_position,
		const Ref<RotatedShapeData> &p_shape_data,
		Color p_color,
		double p_dash_length,
		double p_dash_gap,
		double p_dash_offset,
		double p_thickness) const {
	if (!p_canvas || !p_shape_data.is_valid() ||
		!p_shape_data->get_shape().is_valid()) {
		UtilityFunctions::printerr(
				"ScaffolderDrawUtils::draw_dashed_shape: Invalid shape data "
				"provided.");
		return;
	}
	Ref<Shape2D> shape = p_shape_data->get_shape();
	bool is_rotated = p_shape_data->get_is_rotated_90_degrees();

	Ref<CircleShape2D> circle = shape;
	if (circle.is_valid()) {
		draw_dashed_circle(
				p_canvas, p_position, circle->get_radius(), p_color,
				p_dash_length, p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	Ref<CapsuleShape2D> capsule = shape;
	if (capsule.is_valid()) {
		draw_dashed_capsule(
				p_canvas, p_position, capsule->get_radius(),
				capsule->get_height(), is_rotated, p_color, p_dash_length,
				p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	Ref<RectangleShape2D> rect_shape = shape;
	if (rect_shape.is_valid()) {
		draw_dashed_rectangle(
				p_canvas, p_position, rect_shape->get_size() / 2.0, is_rotated,
				p_color, p_dash_length, p_dash_gap, p_dash_offset, p_thickness);
		return;
	}
	UtilityFunctions::printerr(
			"ScaffolderDrawUtils::draw_dashed_shape: Unsupported Shape2D "
			"type: ",
			shape->get_class());
}

void ScaffolderDrawUtils::draw_circle_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		Color p_color,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0.0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON && p_border_width > 0.0) {
		p_canvas->draw_circle(p_center, p_border_width / 2.0, p_color);
		return;
	}
	if (p_radius < CMP_EPSILON)
		return;

	PackedVector2Array points = compute_arc_points(
			p_center, p_radius, 0.0,
			tau, // 2.0 * PI
			p_sector_arc_length);

	if (points.size() < 2)
		return; // Not enough points to draw a polyline

	// GDScript trick for closing circle polyline smoothly
	PackedVector2Array final_polyline_points;
	final_polyline_points.push_back(points[0]); // Add P0 (original first point)
	final_polyline_points.append_array(points); // Add P0, P1, ..., P_last(=P0)
	// Now final_polyline_points is [P0, P0, P1, ..., P_last(=P0)]
	final_polyline_points.push_back(points[0]); // Add P0 again at the end
	// Now final_polyline_points is [P0, P0, P1, ..., P_last(=P0), P0]
	// Size is original_points.size() + 2

	if (final_polyline_points.size() >=
		3) { // Need at least 3 points for this trick (e.g. P0, P0_mod,
			 // P0_again)
		// Original points size must be at least 1.
		// If original points size is 2 (e.g. P0, P0), then final size is 4.
		// final_polyline_points[size-2] is the original P_last(=P0)
		// final_polyline_points[1] is the original P0
		Vector2 p_last_mod =
				final_polyline_points[final_polyline_points.size() - 2];
		p_last_mod.y -= 0.0001;
		final_polyline_points.set(final_polyline_points.size() - 2, p_last_mod);

		Vector2 p1_mod = final_polyline_points[1];
		p1_mod.y += 0.0001;
		final_polyline_points.set(1, p1_mod);
	}

	p_canvas->draw_polyline(final_polyline_points, p_color, p_border_width);
}

void ScaffolderDrawUtils::draw_arc(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		Color p_color,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0.0, "Radius cannot be negative.");
	if (p_radius < CMP_EPSILON)
		return;

	PackedVector2Array points = compute_arc_points(
			p_center, p_radius, p_start_angle, p_end_angle,
			p_sector_arc_length);

	if (points.size() < 2 &&
		points.size() >
				0) { // If only one point, draw a small circle for the point
		p_canvas->draw_circle(points[0], p_border_width / 2.0, p_color);
	} else if (points.size() >= 2) {
		p_canvas->draw_polyline(points, p_color, p_border_width);
	}
}

PackedVector2Array ScaffolderDrawUtils::compute_arc_points(
		Vector2 p_center,
		double p_radius,
		double p_start_angle,
		double p_end_angle,
		double p_sector_arc_length) const {
	ERR_FAIL_COND_V_MSG(
			p_sector_arc_length <= 0.0, PackedVector2Array(),
			"Sector arc length must be positive.");
	ERR_FAIL_COND_V_MSG(
			p_radius < 0.0, PackedVector2Array(), "Radius cannot be negative.");

	PackedVector2Array points;
	if (p_radius < CMP_EPSILON) {
		points.push_back(p_center);
		return points;
	}

	double angle_diff = p_end_angle - p_start_angle;

	if (Math::is_zero_approx(angle_diff)) {
		points.push_back(
				p_center +
				Vector2(Math::cos(p_start_angle), Math::sin(p_start_angle)) *
						p_radius);
		return points;
	}

	// GDScript: var sector_count := floor(abs(angle_diff) * radius /
	// sector_arc_length) GDScript: var delta_theta := sector_arc_length /
	// radius GDScript: if angle_diff < 0: delta_theta = -delta_theta

	double abs_angle_diff = Math::abs(angle_diff);
	int sector_count = static_cast<int>(
			Math::floor(abs_angle_diff * p_radius / p_sector_arc_length));
	if (sector_count < 0)
		sector_count = 0; // Should not happen if abs_angle_diff is used

	double delta_theta = p_sector_arc_length / p_radius;
	if (angle_diff < 0.0) {
		delta_theta = -delta_theta;
	}

	// GDScript: var should_include_partial_sector_at_end := abs(angle_diff) -
	// sector_count * delta_theta > 0.01 Note: GDScript uses sector_count *
	// delta_theta, but delta_theta there already has sign. Here, use
	// abs(delta_theta) for comparison with abs_angle_diff.
	bool should_include_partial_sector_at_end =
			abs_angle_diff - sector_count * Math::abs(delta_theta) > 0.01;

	double theta = p_start_angle;
	for (int i = 0; i <= sector_count; ++i) {
		points.push_back(
				p_center +
				Vector2(Math::cos(theta), Math::sin(theta)) * p_radius);
		if (i < sector_count) { // Avoid overshooting if last point is added
								// separately
			theta += delta_theta;
		}
	}

	if (should_include_partial_sector_at_end) {
		// Ensure the last point is exactly at end_angle if it wasn't hit
		Vector2 last_point_val = p_center +
				Vector2(Math::cos(p_end_angle), Math::sin(p_end_angle)) *
						p_radius;
		if (points.is_empty() ||
			!points[points.size() - 1].is_equal_approx(last_point_val)) {
			points.push_back(last_point_val);
		}
	} else if (!points.is_empty()) {
		// If no partial sector, ensure the last point (which should be at
		// end_angle) is precise
		points.set(
				points.size() - 1,
				p_center +
						Vector2(Math::cos(p_end_angle),
								Math::sin(p_end_angle)) *
								p_radius);
	}

	if (points.is_empty()) { // Fallback if logic somehow resulted in no points
		points.push_back(
				p_center +
				Vector2(Math::cos(p_start_angle), Math::sin(p_start_angle)) *
						p_radius);
		if (!Math::is_zero_approx(p_start_angle - p_end_angle)) {
			points.push_back(
					p_center +
					Vector2(Math::cos(p_end_angle), Math::sin(p_end_angle)) *
							p_radius);
		}
	}
	return points;
}

void ScaffolderDrawUtils::draw_rectangle_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		Vector2 p_half_width_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_thickness) const {
	if (!p_canvas)
		return;
	double x_offset = p_is_rotated_90_degrees ? p_half_width_height.y
											  : p_half_width_height.x;
	double y_offset = p_is_rotated_90_degrees ? p_half_width_height.x
											  : p_half_width_height.y;

	PackedVector2Array polyline;
	polyline.resize(6);

	Vector2 p1 = p_center + Vector2(-x_offset, -y_offset);
	Vector2 p2 = p_center + Vector2(x_offset, -y_offset);
	Vector2 p3 = p_center + Vector2(x_offset, y_offset);
	Vector2 p4 = p_center + Vector2(-x_offset, y_offset);

	polyline.set(1, p1);
	polyline.set(2, p2);
	polyline.set(3, p3);
	polyline.set(4, p4);

	polyline.set(5, p4.linear_interpolate(p1, 0.5));
	polyline.set(0, polyline[5]);

	p_canvas->draw_polyline(polyline, p_color, p_thickness);
}

void ScaffolderDrawUtils::draw_capsule_outline(
		CanvasItem *p_canvas,
		Vector2 p_center,
		double p_radius,
		double p_height,
		bool p_is_rotated_90_degrees,
		Color p_color,
		double p_thickness,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(p_radius < 0.0, "Radius cannot be negative.");
	ERR_FAIL_COND_MSG(p_height < 0.0, "Height cannot be negative.");
	if (p_radius < CMP_EPSILON && p_height < CMP_EPSILON)
		return;

	// GDScript logic:
	// var sector_count := ceil((PI * radius / sector_arc_length) / 2.0) * 2.0
	// -> ensures even number for symmetry var delta_theta := PI / sector_count
	// var theta := PI / 2.0 if is_rotated_90_degrees else 0.0
	// var capsule_end_offset := Vector2(height / 2.0, 0.0) if
	// is_rotated_90_degrees else Vector2(0.0, height / 2.0) -> This seems
	// swapped in GDScript Corrected offset logic:
	Vector2 capsule_end_offset_dir =
			p_is_rotated_90_degrees ? Vector2(0.0, 1.0) : Vector2(1.0, 0.0);
	Vector2 capsule_end_offset = capsule_end_offset_dir * (p_height / 2.0);

	Vector2 end_center1 = p_center - capsule_end_offset;
	Vector2 end_center2 = p_center + capsule_end_offset;

	double start_angle1, end_angle1, start_angle2, end_angle2;

	if (p_is_rotated_90_degrees) { // Vertical capsule
		start_angle1 = pi;
		end_angle1 = tau; // Top semicircle (end_center1 is upper)
		start_angle2 = 0.0;
		end_angle2 = pi; // Bottom semicircle (end_center2 is lower)
	} else { // Horizontal capsule
		start_angle1 = pi / 2.0;
		end_angle1 = pi * 3.0 / 2.0; // Left semicircle (end_center1 is left)
		start_angle2 = -pi / 2.0;
		end_angle2 = pi / 2.0; // Right semicircle (end_center2 is right)
							   // Or pi * 3.0/2.0 to pi / 2.0 + TAU
	}

	PackedVector2Array arc1_points = compute_arc_points(
			end_center1, p_radius, start_angle1, end_angle1,
			p_sector_arc_length);
	PackedVector2Array arc2_points = compute_arc_points(
			end_center2, p_radius, start_angle2, end_angle2,
			p_sector_arc_length);

	PackedVector2Array combined_vertices;
	// The order matters for the polyline trick. GDScript adds arc1 then arc2.
	if (arc1_points.size() > 0)
		combined_vertices.append_array(arc1_points);
	// If arc1 ends where arc2 begins (or vice-versa), remove duplicate.
	// For a capsule, they don't meet directly, the straight segments connect
	// them. The GDScript `draw_capsule_outline` directly constructs points for
	// two semicircles and two connecting lines. My previous C++ port for
	// `draw_capsule_outline` used `draw_closed_polyline` after combining arc
	// points. The GDScript `draw_capsule_outline` has its own specific point
	// generation and trick: `var vertex_count := (sector_count + 1) * 2 + 2` It
	// fills `vertices[1]` to `vertices[vertex_count-2]` Then
	// `vertices[vertex_count - 1] = lerp(vertices[vertex_count - 2],
	// vertices[1], 0.5)` `vertices[0] = vertices[vertex_count - 1]`

	// Let's follow the GDScript's direct construction for
	// `draw_capsule_outline`
	PackedVector2Array final_vertices;
	int sector_count_per_half = 0;
	if (p_radius > CMP_EPSILON && p_sector_arc_length > CMP_EPSILON) {
		sector_count_per_half = static_cast<int>(
				Math::ceil((pi * p_radius / p_sector_arc_length) / 2.0) * 2.0);
	}
	if (sector_count_per_half == 0 && p_radius > CMP_EPSILON)
		sector_count_per_half = 2; // Minimum segments for a curve

	int points_per_arc = sector_count_per_half + 1;
	// Total content points: arc1_points + (optional P1 of arc2 if not same as
	// last of arc1) + arc2_points_rest The GDScript logic is simpler: it makes
	// points for one semicircle, then the other. And assumes they connect to
	// form the outline.

	// Replicating GDScript's `draw_capsule_outline` point generation:
	// `theta` initialization and `delta_theta` calculation
	double initial_theta, delta_theta_capsule;
	if (p_radius > CMP_EPSILON && sector_count_per_half > 0) {
		delta_theta_capsule = pi / sector_count_per_half;
	} else {
		delta_theta_capsule =
				pi; // Effectively 2 points per arc if sector_count is 0
		points_per_arc = 2; // Start and end point for each "arc"
	}

	if (p_is_rotated_90_degrees) { // Vertical
		initial_theta =
				pi / 2.0; // Starts from rightmost point of top circle, goes CCW
	} else { // Horizontal
		initial_theta =
				0.0; // Starts from rightmost point of left circle, goes CCW
	}

	// Corrected logic based on typical capsule drawing (two semicircles and two
	// straight lines) Semicircle 1 (around end_center1) Semicircle 2 (around
	// end_center2) Line 1 (top) Line 2 (bottom) This is more complex than the
	// GDScript's direct loop if it implies straight segments are part of the
	// loop. The GDScript `draw_capsule_outline` seems to generate points for
	// the full perimeter in one go.

	// Sticking to the GDScript's loop structure for point generation:
	final_vertices.resize(points_per_arc * 2 + 2); // +2 for the polyline trick
	double current_theta = initial_theta;

	// First semicircle (around end_center1)
	// GDScript: theta starts at PI/2 (vertical) or 0 (horizontal)
	// and iterates for sector_count+1 points.
	// This seems to be for one full circle if loop is 2*PI.
	// The GDScript `draw_capsule_outline` is quite specific.
	// Let's use the `arc1_points` and `arc2_points` and connect them.
	PackedVector2Array perimeter_points;
	Vector2 p1_arc1, pN_arc1, p1_arc2, pN_arc2;

	if (!arc1_points.is_empty()) {
		perimeter_points.append_array(arc1_points);
		p1_arc1 = arc1_points[0];
		pN_arc1 = arc1_points[arc1_points.size() - 1];
	}
	if (!arc2_points.is_empty()) {
		// Connect pN_arc1 to p1_arc2 (or pN_arc2 if reversed) with a line if
		// not already connected by arcs Then add arc2_points, then connect
		// pN_arc2 to p1_arc1 This is what draw_closed_polyline would do if
		// perimeter_points was [arc1, line, arc2, line] For a capsule, the arcs
		// are distinct. Order: arc1_points, then points from arc2_points in
		// order that connects smoothly. The straight edges are implicitly
		// formed if the arcs don't fully meet. However, a capsule has explicit
		// straight edges. Arc1 (end_center1), LineA, Arc2 (end_center2), LineB

		// Points for the straight segments:
		Vector2 tangent_offset_dir =
				(end_center2 - end_center1).orthogonal().normalized() *
				p_radius;
		Vector2 t1_c1 = end_center1 + tangent_offset_dir;
		Vector2 t2_c1 = end_center1 - tangent_offset_dir;
		Vector2 t1_c2 = end_center2 + tangent_offset_dir;
		Vector2 t2_c2 = end_center2 - tangent_offset_dir;

		// Reconstruct perimeter_points: arc around c1 from t2_c1 to t1_c1, line
		// t1_c1 to t1_c2, arc c2 from t1_c2 to t2_c2, line t2_c2 to t2_c1
		perimeter_points.clear();
		// Determine angles for arcs based on tangent points
		double angle_c1_to_t2 = (t2_c1 - end_center1).angle();
		double angle_c1_to_t1 = (t1_c1 - end_center1).angle();
		PackedVector2Array cap1_arc = compute_arc_points(
				end_center1, p_radius, angle_c1_to_t2, angle_c1_to_t1,
				p_sector_arc_length);

		double angle_c2_to_t1 = (t1_c2 - end_center2).angle();
		double angle_c2_to_t2 = (t2_c2 - end_center2).angle();
		PackedVector2Array cap2_arc = compute_arc_points(
				end_center2, p_radius, angle_c2_to_t1, angle_c2_to_t2,
				p_sector_arc_length);

		if (!cap1_arc.is_empty())
			perimeter_points.append_array(cap1_arc);
		if (!cap1_arc.is_empty() && !cap2_arc.is_empty()) {
			// Ensure connection from last of cap1_arc (should be t1_c1) to
			// t1_c2
			if (!perimeter_points[perimeter_points.size() - 1].is_equal_approx(
						t1_c1))
				perimeter_points.push_back(t1_c1);
			if (!t1_c1.is_equal_approx(t1_c2))
				perimeter_points.push_back(t1_c2); // Line segment
		}
		if (!cap2_arc.is_empty())
			perimeter_points.append_array(cap2_arc);
		if (!cap2_arc.is_empty() && !cap1_arc.is_empty()) {
			// Ensure connection from last of cap2_arc (should be t2_c2) to
			// t2_c1 (start of cap1_arc)
			if (!perimeter_points[perimeter_points.size() - 1].is_equal_approx(
						t2_c2))
				perimeter_points.push_back(t2_c2);
			if (!t2_c2.is_equal_approx(t2_c1))
				perimeter_points.push_back(t2_c1); // Line segment
		}
	}

	if (perimeter_points.size() < 2) {
		if (perimeter_points.size() == 1)
			p_canvas->draw_circle(
					perimeter_points[0], p_thickness / 2.0, p_color);
		return;
	}

	// Apply the polyline closing trick from GDScript's draw_capsule_outline
	PackedVector2Array final_draw_points;
	final_draw_points.resize(perimeter_points.size() + 2);
	for (int i = 0; i < perimeter_points.size(); ++i) {
		final_draw_points.set(i + 1, perimeter_points[i]);
	}

	if (final_draw_points.size() >=
		4) { // Min 2 content points + 2 trick points
		final_draw_points.set(
				final_draw_points.size() - 1,
				final_draw_points[final_draw_points.size() - 2]
						.linear_interpolate(final_draw_points[1], 0.5));
		final_draw_points.set(
				0, final_draw_points[final_draw_points.size() - 1]);
		p_canvas->draw_polyline(final_draw_points, p_color, p_thickness);
	} else if (!perimeter_points
						.is_empty()) { // Fallback if trick cannot be applied
		p_canvas->draw_polyline(perimeter_points, p_color, p_thickness);
	}
}

void ScaffolderDrawUtils::draw_ice_cream_cone(
		CanvasItem *p_canvas,
		Vector2 p_cone_end_point,
		Vector2 p_circle_center,
		double p_circle_radius,
		Color p_color,
		bool p_is_filled,
		double p_border_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(
			p_circle_radius < 0.0, "Circle radius cannot be negative.");

	double distance_from_cone_end_point_to_circle_center =
			p_cone_end_point.distance_to(p_circle_center);

	if (p_circle_radius < CMP_EPSILON) {
		p_canvas->draw_line(
				p_circle_center, p_cone_end_point, p_color, p_border_width,
				false);
		return;
	}
	if (distance_from_cone_end_point_to_circle_center <=
		p_circle_radius + CMP_EPSILON) {
		if (p_is_filled) {
			p_canvas->draw_circle(p_circle_center, p_circle_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, p_circle_center, p_circle_radius, p_color,
					p_border_width, p_sector_arc_length);
		}
		return;
	}

	// GDScript: var angle_from_circle_center_to_point_of_tangency :=
	// acos(circle_radius / distance_from_cone_end_point_to_circle_center)
	// GDScript: var angle_from_circle_center_to_cone_end_point :=
	// cone_end_point.angle_to_point(circle_center) This GDScript angle is
	// (circle_center - cone_end_point).angle(). For consistency, let's use
	// (cone_end_point - circle_center).angle() as the base direction from
	// circle center.
	double angle_offset_to_tangency = Math::acos(
			p_circle_radius / distance_from_cone_end_point_to_circle_center);
	double angle_dir_cc_to_cep =
			(p_cone_end_point - p_circle_center)
					.angle(); // Angle of vector from circle_center to
							  // cone_end_point

	// GDScript start/end angles for the arc:
	// start_angle := angle_from_circle_center_to_cone_end_point +
	// angle_from_circle_center_to_point_of_tangency end_angle :=
	// angle_from_circle_center_to_cone_end_point + 2.0 * PI -
	// angle_from_circle_center_to_point_of_tangency The GDScript
	// `angle_from_circle_center_to_cone_end_point` is `(p_circle_center -
	// p_cone_end_point).angle()`. Let's use `angle_dir_cc_to_cep` for clarity.
	// The arc should be the part of the circle visible from the cone_end_point.
	// Tangent points are at `angle_dir_cc_to_cep +/- angle_offset_to_tangency`.
	// The arc between these points *not* containing `angle_dir_cc_to_cep` is
	// the one we want. So, from `angle_dir_cc_to_cep +
	// angle_offset_to_tangency` around to `angle_dir_cc_to_cep -
	// angle_offset_to_tangency` (the long way).

	double arc_start_angle = angle_dir_cc_to_cep + angle_offset_to_tangency;
	double arc_end_angle = angle_dir_cc_to_cep - angle_offset_to_tangency +
			tau; // Ensure positive sweep for compute_arc_points

	PackedVector2Array arc_points = compute_arc_points(
			p_circle_center, p_circle_radius, arc_start_angle, arc_end_angle,
			p_sector_arc_length);

	PackedVector2Array final_draw_points; // For draw_polyline or draw_polygon
	if (!arc_points.is_empty()) {
		final_draw_points.append_array(arc_points);

		// GDScript extra points for sharp tip
		Vector2 extra_cone_end_point_1 = p_cone_end_point +
				(arc_points[arc_points.size() - 1] - p_cone_end_point) *
						0.000001;
		Vector2 extra_cone_end_point_2 = p_cone_end_point +
				(arc_points[0] - p_cone_end_point) * 0.000001;

		final_draw_points.push_back(extra_cone_end_point_1);
		final_draw_points.push_back(p_cone_end_point);
		final_draw_points.push_back(extra_cone_end_point_2);
		final_draw_points.push_back(
				arc_points[0]); // Close the polygon for draw_polyline
	} else { // Should not happen if cone is outside circle and radius > 0
		final_draw_points.push_back(p_cone_end_point);
		final_draw_points.push_back(p_circle_center); // Fallback: line
	}

	if (p_is_filled) {
		// For filled polygon, we need a simple list of vertices: arc points +
		// cone tip. The `final_draw_points` from GDScript is already set up for
		// this if `draw_colored_polygon` handles the extra points well. Or,
		// more cleanly:
		PackedVector2Array filled_polygon_points;
		if (!arc_points.is_empty()) {
			filled_polygon_points.append_array(arc_points);
			filled_polygon_points.push_back(p_cone_end_point); // Arc + tip
		}
		if (filled_polygon_points.size() >= 3) {
			PackedColorArray colors;
			colors.push_back(p_color);
			p_canvas->draw_polygon(filled_polygon_points, colors);
		} else if (!final_draw_points
							.is_empty()) { // Fallback to GDScript's point list
										   // if simpler one fails
			PackedColorArray colors;
			colors.push_back(p_color);
			p_canvas->draw_polygon(final_draw_points, colors);
		}

	} else { // Outline
		if (final_draw_points.size() >= 2) {
			p_canvas->draw_polyline(final_draw_points, p_color, p_border_width);
		}
	}
}

void ScaffolderDrawUtils::draw_smooth_segment_with_two_circular_ends(
		CanvasItem *p_canvas,
		Vector2 p_center_1,
		double p_radius_1,
		Vector2 p_center_2,
		double p_radius_2,
		Color p_color,
		bool p_is_filled,
		double p_stroke_width,
		double p_sector_arc_length) const {
	if (!p_canvas)
		return;
	ERR_FAIL_COND_MSG(
			p_radius_1 < 0.0 || p_radius_2 < 0.0, "Radii cannot be negative.");

	Vector2 larger_center, smaller_center;
	double larger_radius, smaller_radius;

	if (p_radius_1 > p_radius_2) {
		larger_radius = p_radius_1;
		larger_center = p_center_1;
		smaller_radius = p_radius_2;
		smaller_center = p_center_2;
	} else {
		larger_radius = p_radius_2;
		larger_center = p_center_2;
		smaller_radius = p_radius_1;
		smaller_center = p_center_1;
	}

	double dist_centers = smaller_center.distance_to(larger_center);

	if (larger_radius <=
		CMP_EPSILON) { // Both radii are zero or negative (error caught already)
		p_canvas->draw_line(
				smaller_center, larger_center, p_color, p_stroke_width, false);
		return;
	}
	if (dist_centers + smaller_radius <=
		larger_radius + CMP_EPSILON) { // Smaller circle is inside or tangent to
									   // larger one
		if (p_is_filled) {
			p_canvas->draw_circle(larger_center, larger_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, larger_center, larger_radius, p_color,
					p_stroke_width, p_sector_arc_length);
		}
		return;
	}
	if (smaller_radius <=
		CMP_EPSILON) { // Smaller radius is zero, becomes an ice cream cone
		draw_ice_cream_cone(
				p_canvas, smaller_center, larger_center, larger_radius, p_color,
				p_is_filled, p_stroke_width, p_sector_arc_length);
		return;
	}
	if (dist_centers < CMP_EPSILON &&
		std::abs(larger_radius - smaller_radius) <
				CMP_EPSILON) { // Concentric circles of same size
		if (p_is_filled) {
			p_canvas->draw_circle(larger_center, larger_radius, p_color);
		} else {
			draw_circle_outline(
					p_canvas, larger_center, larger_radius, p_color,
					p_stroke_width, p_sector_arc_length);
		}
		return;
	}

	double angle_between_centers =
			(larger_center - smaller_center)
					.angle(); // Angle of vector from smaller to larger center
	double beta = std::asin((larger_radius - smaller_radius) / dist_centers);

	// Points of tangency for the "straps"
	// For smaller circle
	double s_tangent1_angle = angle_between_centers + beta;
	double s_tangent2_angle = angle_between_centers - beta;
	// For larger circle
	double l_tangent1_angle = angle_between_centers + beta;
	double l_tangent2_angle = angle_between_centers - beta;

	Vector2 s_p1 = smaller_center +
			Vector2(Math::cos(s_tangent1_angle), Math::sin(s_tangent1_angle)) *
					smaller_radius;
	Vector2 s_p2 = smaller_center +
			Vector2(Math::cos(s_tangent2_angle), Math::sin(s_tangent2_angle)) *
					smaller_radius;
	Vector2 l_p1 = larger_center +
			Vector2(Math::cos(l_tangent1_angle), Math::sin(l_tangent1_angle)) *
					larger_radius;
	Vector2 l_p2 = larger_center +
			Vector2(Math::cos(l_tangent2_angle), Math::sin(l_tangent2_angle)) *
					larger_radius;

	// Arcs (these are the "outer" arcs that are part of the shape)
	// Smaller circle arc is from tangent2 to tangent1 (clockwise if beta > 0)
	// Larger circle arc is from tangent1 to tangent2 (clockwise if beta > 0)
	// The GDScript angles:
	// smaller_start_angle := angle_between_circle_centers - beta + PI / 2.0 ->
	// This seems to be for internal tangents or different geometry. The
	// provided GDScript angles for arcs are complex and might be for a specific
	// orientation. The visual is two circles connected by two common external
	// tangents. The arcs are the parts of the circles *not* between the tangent
	// points on the "inside".

	// Correct angles for the external tangent connection:
	// Arc on smaller circle: from angle (angle_between_centers - beta) to
	// (angle_between_centers + beta) - this is the "inner" arc. We need the
	// "outer" arc. So from (angle_between_centers + beta) around to
	// (angle_between_centers - beta + TAU).
	double smaller_arc_start = angle_between_centers + beta;
	double smaller_arc_end =
			angle_between_centers - beta + tau; // Ensure it's a positive sweep

	// Arc on larger circle
	double larger_arc_start = angle_between_centers - beta;
	double larger_arc_end = angle_between_centers + beta;

	PackedVector2Array smaller_arc_points = compute_arc_points(
			smaller_center, smaller_radius, smaller_arc_start, smaller_arc_end,
			p_sector_arc_length);
	PackedVector2Array larger_arc_points = compute_arc_points(
			larger_center, larger_radius, larger_arc_start, larger_arc_end,
			p_sector_arc_length);

	PackedVector2Array polygon_points;
	// Order: s_p1, points of smaller_arc, s_p2, l_p2 (connected to s_p2),
	// points of larger_arc, l_p1 (connected to s_p1) The tangent points are
	// s_p1, s_p2 on smaller, and l_p1, l_p2 on larger. Strap 1: s_p1 to l_p1.
	// Strap 2: s_p2 to l_p2. Arc 1 (smaller): from s_p2 around to s_p1. Arc 2
	// (larger): from l_p1 around to l_p2.

	// Re-evaluate arc angles for the shape:
	// Smaller circle: arc from point of tangent2 to point of tangent1 (e.g.
	// s_p2 to s_p1) Larger circle: arc from point of tangent1 to point of
	// tangent2 (e.g. l_p1 to l_p2)

	// Angles for arcs that form part of the convex hull:
	// Smaller circle: from (angle_between_centers - beta) to
	// (angle_between_centers + beta) going the long way around. Angle for s_p2
	// is (angle_between_centers - beta). Angle for s_p1 is
	// (angle_between_centers + beta). Arc on smaller circle: from s_p1
	// (angle_between_centers + beta) to s_p2 (angle_between_centers - beta +
	// TAU)
	PackedVector2Array arc_s = compute_arc_points(
			smaller_center, smaller_radius, angle_between_centers + beta,
			angle_between_centers - beta + tau, p_sector_arc_length);
	// Arc on larger circle: from l_p2 (angle_between_centers - beta) to l_p1
	// (angle_between_centers + beta)
	PackedVector2Array arc_l = compute_arc_points(
			larger_center, larger_radius, angle_between_centers - beta,
			angle_between_centers + beta, p_sector_arc_length);

	polygon_points.append_array(arc_s); // Starts at s_p1, ends at s_p2
	polygon_points.append_array(arc_l); // Starts at l_p2, ends at l_p1

	if (polygon_points.size() < 3 && p_is_filled) { // Not enough for polygon
		// Fallback: draw two circles and two lines if not filled
	}

	if (p_is_filled) {
		if (polygon_points.size() >= 3) {
			p_canvas->draw_polygon(
					polygon_points, PackedColorArray::make(p_color));
		}
	} else {
		// Draw the two arcs and two tangent lines
		if (arc_s.size() > 1)
			p_canvas->draw_polyline(arc_s, p_color, p_stroke_width);
		else if (arc_s.size() == 1)
			p_canvas->draw_circle(
					arc_s[0], p_stroke_width / 2.0, p_color); // Draw a point

		if (arc_l.size() > 1)
			p_canvas->draw_polyline(arc_l, p_color, p_stroke_width);
		else if (arc_l.size() == 1)
			p_canvas->draw_circle(arc_l[0], p_stroke_width / 2.0, p_color);

		p_canvas->draw_line(s_p1, l_p1, p_color, p_stroke_width);
		p_canvas->draw_line(s_p2, l_p2, p_color, p_stroke_width);
	}
}

void ScaffolderDrawUtils::_bind_methods() {
	// Binding all methods to make them callable from GDScript
	ClassDB::bind_method(
			D_METHOD(
					"draw_closed_polyline", "p_canvas", "p_points", "p_color",
					"p_stroke_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_closed_polyline, DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_line", "p_canvas", "p_from", "p_to", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset", "p_width",
					"p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_line, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_polyline", "p_canvas", "p_vertices", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset", "p_width",
					"p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_polyline, DEFVAL(0.0),
			DEFVAL(1.0), DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_rectangle", "p_canvas", "p_center",
					"p_half_width_height", "p_is_rotated_90_degrees", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_stroke_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_rectangle, DEFVAL(0.0),
			DEFVAL(1.0), DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_circle", "p_canvas", "p_center", "p_radius",
					"p_color", "p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_circle, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_arc", "p_canvas", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_color", "p_dash_length",
					"p_dash_gap", "p_dash_offset", "p_width", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_arc, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_capsule", "p_canvas", "p_center", "p_radius",
					"p_height", "p_is_rotated_90_degrees", "p_color",
					"p_dash_length", "p_dash_gap", "p_dash_offset",
					"p_thickness", "p_antialiased"),
			&ScaffolderDrawUtils::draw_dashed_capsule, DEFVAL(0.0), DEFVAL(1.0),
			DEFVAL(false));
	ClassDB::bind_method(
			D_METHOD(
					"draw_x", "p_canvas", "p_center", "p_width", "p_height",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_x);
	ClassDB::bind_method(
			D_METHOD(
					"draw_plus", "p_canvas", "p_center", "p_width", "p_height",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_plus);
	ClassDB::bind_method(
			D_METHOD(
					"draw_asterisk", "p_canvas", "p_center", "p_width",
					"p_height", "p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_asterisk);
	ClassDB::bind_method(
			D_METHOD(
					"draw_checkmark", "p_canvas", "p_position", "p_width",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_checkmark);
	ClassDB::bind_method(
			D_METHOD(
					"draw_exclamation_mark", "p_canvas", "p_center", "p_width",
					"p_length", "p_color", "p_is_filled", "p_stroke_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_exclamation_mark, DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_arrow", "p_canvas", "p_start", "p_end",
					"p_head_length", "p_head_width", "p_color",
					"p_stroke_width"),
			&ScaffolderDrawUtils::draw_arrow);
	ClassDB::bind_method(
			D_METHOD(
					"draw_strike_through_arrow", "p_canvas", "p_start", "p_end",
					"p_head_length", "p_head_width", "p_strike_through_length",
					"p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_strike_through_arrow);
	ClassDB::bind_method(
			D_METHOD(
					"draw_diamond_outline", "p_canvas", "p_center", "p_width",
					"p_height", "p_color", "p_stroke_width"),
			&ScaffolderDrawUtils::draw_diamond_outline);
	ClassDB::bind_method(
			D_METHOD(
					"draw_shape_outline", "p_canvas", "p_position",
					"p_shape_data", "p_color", "p_thickness"),
			&ScaffolderDrawUtils::draw_shape_outline);
	ClassDB::bind_method(
			D_METHOD(
					"draw_dashed_shape", "p_canvas", "p_position",
					"p_shape_data", "p_color", "p_dash_length", "p_dash_gap",
					"p_dash_offset", "p_thickness"),
			&ScaffolderDrawUtils::draw_dashed_shape, DEFVAL(0.0), DEFVAL(1.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_circle_outline", "p_canvas", "p_center", "p_radius",
					"p_color", "p_border_width", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_circle_outline, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_arc", "p_canvas", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_color", "p_border_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_arc, DEFVAL(1.0), DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"compute_arc_points", "p_center", "p_radius",
					"p_start_angle", "p_end_angle", "p_sector_arc_length"),
			&ScaffolderDrawUtils::compute_arc_points, DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_rectangle_outline", "p_canvas", "p_center",
					"p_half_width_height", "p_is_rotated_90_degrees", "p_color",
					"p_thickness"),
			&ScaffolderDrawUtils::draw_rectangle_outline, DEFVAL(1.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_capsule_outline", "p_canvas", "p_center", "p_radius",
					"p_height", "p_is_rotated_90_degrees", "p_color",
					"p_thickness", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_capsule_outline, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_ice_cream_cone", "p_canvas", "p_cone_end_point",
					"p_circle_center", "p_circle_radius", "p_color",
					"p_is_filled", "p_border_width", "p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_ice_cream_cone, DEFVAL(1.0),
			DEFVAL(4.0));
	ClassDB::bind_method(
			D_METHOD(
					"draw_smooth_segment_with_two_circular_ends", "p_canvas",
					"p_center_1", "p_radius_1", "p_center_2", "p_radius_2",
					"p_color", "p_is_filled", "p_stroke_width",
					"p_sector_arc_length"),
			&ScaffolderDrawUtils::draw_smooth_segment_with_two_circular_ends,
			DEFVAL(4.0));
}
