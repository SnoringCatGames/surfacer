#ifndef SCAFFOLDER_DRAW_UTILS_H
#define SCAFFOLDER_DRAW_UTILS_H

#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/classes/capsule_shape2d.hpp>
#include <godot_cpp/classes/circle_shape2d.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/rectangle_shape2d.hpp>
#include <godot_cpp/classes/shape2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_vector2_array.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

// Helper class for RotatedShape concept, mirroring potential GDScript structure
class RotatedShapeData : public RefCounted {
	GDCLASS(RotatedShapeData, RefCounted);

private:
	Ref<Shape2D> shape;
	bool _is_rotated_90_degrees = false;

protected:
	static void _bind_methods() {
		ClassDB::bind_method(
				D_METHOD("set_shape", "p_shape"), &RotatedShapeData::set_shape);
		ClassDB::bind_method(
				D_METHOD("get_shape"), &RotatedShapeData::get_shape);
		ClassDB::bind_method(
				D_METHOD("set_is_rotated_90_degrees", "p_rotated"),
				&RotatedShapeData::set_is_rotated_90_degrees);
		ClassDB::bind_method(
				D_METHOD("get_is_rotated_90_degrees"),
				&RotatedShapeData::get_is_rotated_90_degrees);
		ADD_PROPERTY(
				PropertyInfo(
						Variant::OBJECT, "shape", PROPERTY_HINT_RESOURCE_TYPE,
						"Shape2D"),
				"set_shape", "get_shape");
		ADD_PROPERTY(
				PropertyInfo(Variant::BOOL, "is_rotated_90_degrees"),
				"set_is_rotated_90_degrees", "get_is_rotated_90_degrees");
	}

public:
	RotatedShapeData() = default;
	RotatedShapeData(Ref<Shape2D> p_shape, bool p_is_rotated) :
			shape(p_shape), _is_rotated_90_degrees(p_is_rotated) {}

	void set_shape(const Ref<Shape2D> &p_s) { shape = p_s; }
	Ref<Shape2D> get_shape() const { return shape; }
	void set_is_rotated_90_degrees(bool p_rotated) {
		_is_rotated_90_degrees = p_rotated;
	}
	bool get_is_rotated_90_degrees() const { return _is_rotated_90_degrees; }
};

class ScaffolderDrawUtils : public Node {
	GDCLASS(ScaffolderDrawUtils, Node);

public:
	static constexpr double STRIKE_THROUGH_ANGLE = -Math_PI / 3.0;
	static constexpr double EXCLAMATION_MARK_GAP_LENGTH_TO_WIDTH_RATIO = 0.5;
	static constexpr double EXCLAMATION_MARK_BODY_LOWER_END_WIDTH_RATIO = 0.5;
	static constexpr double EXCLAMATION_MARK_DOT_WIDTH_RATIO = 1.0;

protected:
	static void _bind_methods();

public:
	ScaffolderDrawUtils();
	~ScaffolderDrawUtils();

	void draw_closed_polyline(
			CanvasItem *p_canvas,
			PackedVector2Array p_points,
			Color p_color,
			double p_stroke_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_line(
			CanvasItem *p_canvas,
			Vector2 p_from,
			Vector2 p_to,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_polyline(
			CanvasItem *p_canvas,
			const PackedVector2Array &p_vertices,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_rectangle(
			CanvasItem *p_canvas,
			Vector2 p_center,
			Vector2 p_half_width_height,
			bool p_is_rotated_90_degrees,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_stroke_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_circle(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_arc(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			double p_start_angle,
			double p_end_angle,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_width = 1.0,
			bool p_antialiased = false) const;
	void draw_dashed_capsule(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			double p_height,
			bool p_is_rotated_90_degrees,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_thickness = 1.0,
			bool p_antialiased = false) const;
	void draw_x(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_width,
			double p_height,
			Color p_color,
			double p_stroke_width) const;
	void draw_plus(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_width,
			double p_height,
			Color p_color,
			double p_stroke_width) const;
	void draw_asterisk(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_width,
			double p_height,
			Color p_color,
			double p_stroke_width) const;
	void draw_checkmark(
			CanvasItem *p_canvas,
			Vector2 p_position,
			double p_width,
			Color p_color,
			double p_stroke_width) const;
	void draw_exclamation_mark(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_width,
			double p_length,
			Color p_color,
			bool p_is_filled,
			double p_stroke_width,
			double p_sector_arc_length = 4.0) const;
	void draw_arrow(
			CanvasItem *p_canvas,
			Vector2 p_start,
			Vector2 p_end,
			double p_head_length,
			double p_head_width,
			Color p_color,
			double p_stroke_width) const;
	void draw_strike_through_arrow(
			CanvasItem *p_canvas,
			Vector2 p_start,
			Vector2 p_end,
			double p_head_length,
			double p_head_width,
			double p_strike_through_length,
			Color p_color,
			double p_stroke_width) const;
	void draw_diamond_outline(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_width,
			double p_height,
			Color p_color,
			double p_stroke_width) const;
	void draw_shape_outline(
			CanvasItem *p_canvas,
			Vector2 p_position,
			const Ref<RotatedShapeData> &p_shape_data,
			Color p_color,
			double p_thickness) const;
	void draw_dashed_shape(
			CanvasItem *p_canvas,
			Vector2 p_position,
			const Ref<RotatedShapeData> &p_shape_data,
			Color p_color,
			double p_dash_length,
			double p_dash_gap,
			double p_dash_offset = 0.0,
			double p_thickness = 1.0) const;
	void draw_circle_outline(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			Color p_color,
			double p_border_width = 1.0,
			double p_sector_arc_length = 4.0) const;
	void draw_arc(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			double p_start_angle,
			double p_end_angle,
			Color p_color,
			double p_border_width = 1.0,
			double p_sector_arc_length = 4.0) const;
	PackedVector2Array compute_arc_points(
			Vector2 p_center,
			double p_radius,
			double p_start_angle,
			double p_end_angle,
			double p_sector_arc_length = 4.0) const;
	void draw_rectangle_outline(
			CanvasItem *p_canvas,
			Vector2 p_center,
			Vector2 p_half_width_height,
			bool p_is_rotated_90_degrees,
			Color p_color,
			double p_thickness = 1.0) const;
	void draw_capsule_outline(
			CanvasItem *p_canvas,
			Vector2 p_center,
			double p_radius,
			double p_height,
			bool p_is_rotated_90_degrees,
			Color p_color,
			double p_thickness = 1.0,
			double p_sector_arc_length = 4.0) const;
	void draw_ice_cream_cone(
			CanvasItem *p_canvas,
			Vector2 p_cone_end_point,
			Vector2 p_circle_center,
			double p_circle_radius,
			Color p_color,
			bool p_is_filled,
			double p_border_width = 1.0,
			double p_sector_arc_length = 4.0) const;
	void draw_smooth_segment_with_two_circular_ends(
			CanvasItem *p_canvas,
			Vector2 p_center_1,
			double p_radius_1,
			Vector2 p_center_2,
			double p_radius_2,
			Color p_color,
			bool p_is_filled,
			double p_stroke_width,
			double p_sector_arc_length = 4.0) const;
};

} // namespace godot

#endif // SCAFFOLDER_DRAW_UTILS_H