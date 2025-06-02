#ifndef POSITION_ALONG_SURFACE_H
#define POSITION_ALONG_SURFACE_H

#include "snore_core/geometry.h"
#include "surfacer/surface/surface.h"

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class RotatedShape;

// - Represents a position along a surface.
// - Rather than considering polyline length, this only specifies the position
//   along the axis the surface is aligned to.
// - The position always indicates the center of the character's bounding
//   box.
class PositionAlongSurface : public RefCounted {
	GDCLASS(PositionAlongSurface, RefCounted)

public:
	PositionAlongSurface() = default;
	~PositionAlongSurface() = default;

	void set_surface(const Ref<Surface> &p_surface) { surface = p_surface; }
	Ref<Surface> get_surface() const { return surface; }

	void set_target_position(Vector2 p_target_position) {
		target_position = p_target_position;
	}
	Vector2 get_target_position() const { return target_position; }

	Surface::Side get_side() const;

	bool is_valid() const;

	void reset();

	void match_current_grab(
			const Ref<Surface> &p_surface,
			const Vector2 &p_character_center);

	void match_surface_target_and_collider(
			const Ref<Surface> &p_surface,
			const Vector2 &p_target_point,
			const Ref<RotatedShape> &p_collider,
			bool p_clips_to_surface_bounds = false,
			bool p_matches_target_to_character_dimensions = true,
			bool p_rejects_non_overlapping_results = true);

	void update_target_projection_onto_surface();

	String to_string(bool p_verbose = true, bool p_includes_projection = false)
			const;

	static void copy(
			Ref<PositionAlongSurface> r_destination,
			const Ref<PositionAlongSurface> &p_source);

protected:
	static void _bind_methods();

private:
	Ref<Surface> surface;
	Vector2 target_position = vector2_invalid;
	Vector2 target_projection_onto_surface = vector2_invalid;

	void clip_and_project_target_point_for_center_of_collider(
			const Ref<Surface> &p_surface,
			const Vector2 &p_target_point,
			const Ref<RotatedShape> &p_collider,
			bool p_clips_to_surface_bounds,
			bool p_matches_target_to_character_dimensions,
			bool p_rejects_non_overlapping_results);
};

} //namespace godot

#endif
