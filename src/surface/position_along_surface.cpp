#include "surface/position_along_surface.h"

#include "rotated_shape.h"
#include "surface.h"
#include "surfacer_geometry.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// FIXME: REVIEW THIS.

Surface::Side PositionAlongSurface::get_side() const {
	if (surface.is_valid()) {
		return surface->get_side();
	}
	return Surface::Side::UNKNOWN_SIDE;
}

bool PositionAlongSurface::is_valid() const {
	return target_position.x != vector2_invalid.y &&
			target_position.y != vector2_invalid.y;
}

void PositionAlongSurface::reset() {
	surface.unref();
	target_position = vector2_invalid;
	target_projection_onto_surface = vector2_invalid;
}

void PositionAlongSurface::match_current_grab(
		Ref<Surface> p_surface,
		const Vector2 &character_center) {
	surface = p_surface;
	target_position = character_center;
	target_projection_onto_surface = vector2_invalid;
	if (surface.is_valid() && target_position != vector2_invalid) {
		update_target_projection_onto_surface();
	}
}

void PositionAlongSurface::match_surface_target_and_collider(
		Ref<Surface> p_surface,
		const Vector2 &p_target_point,
		Ref<RotatedShape> collider,
		bool clips_to_surface_bounds,
		bool matches_target_to_character_dimensions,
		bool rejects_non_overlapping_results) {
	surface = p_surface;
	_clip_and_project_target_point_for_center_of_collider(
			surface, p_target_point, collider, clips_to_surface_bounds,
			matches_target_to_character_dimensions,
			rejects_non_overlapping_results);
}

void PositionAlongSurface::update_target_projection_onto_surface() {
	target_projection_onto_surface =
			SurfacerGeometry::project_point_onto_surface(target_point, surface);
}

void PositionAlongSurface::
		_clip_and_project_target_point_for_center_of_collider(
				Ref<Surface> surface,
				Vector2 target_point,
				Ref<RotatedShape> collider,
				bool clips_to_surface_bounds,
				bool matches_target_to_character_dimensions,
				bool rejects_non_overlapping_results) {
	target_projection_onto_surface =
			SurfacerGeometry::project_point_onto_surface(target_point, surface);

	bool is_surface_horizontal = surface.is_valid() &&
			(surface->get_side() == Surface::Side::FLOOR ||
			 surface->get_side() == Surface::Side::CEILING);

	if (clips_to_surface_bounds) {
		if (is_surface_horizontal) {
			target_point.x = target_projection_onto_surface.x;
		} else {
			target_point.y = target_projection_onto_surface.y;
		}
	}

	if (matches_target_to_character_dimensions) {
		target_point = SurfacerGeometry::
				project_shape_onto_segment_and_away_from_concave_neighbors(
						target_point, collider, surface, true,
						rejects_non_overlapping_results);
		target_projection_onto_surface =
				SurfacerGeometry::project_point_onto_surface(
						target_point, surface);
	}
	// else: use the given target point as-is

	this->target_point = target_point;
}

String PositionAlongSurface::to_string(bool verbose, bool includes_projection)
		const {
	if (verbose) {
		String projection_str = includes_projection
				? ", " + String(target_projection_onto_surface)
				: "";
		return vformat(
				"PositionAlongSurface{ %s%s, %s }", String(target_point),
				projection_str,
				(surface.is_valid() ? surface->to_string(verbose)
									: "NULL SURFACE"));
	} else {
		String projection_str = includes_projection
				? ", " +
						Geometry::get_vector_string(
								target_projection_onto_surface, 1)
				: "";
		return vformat(
				"P{%s%s, %s}", Geometry::get_vector_string(target_point, 1),
				projection_str,
				(surface.is_valid() ? surface->to_string(verbose) : "NULL"));
	}
}

void PositionAlongSurface::_bind_methods() {
	ClassDB::bind_method(
			D_METHOD("get_surface"), &PositionAlongSurface::get_surface);
	ClassDB::bind_method(
			D_METHOD("set_surface", "p_surface"),
			&PositionAlongSurface::set_surface);

	ADD_PROPERTY(
			PropertyInfo(Variant::OBJECT, "surface"), "set_surface",
			"get_surface");

	ClassDB::bind_method(
			D_METHOD("get_target_position"),
			&PositionAlongSurface::get_target_position);
	ClassDB::bind_method(
			D_METHOD("set_target_position", "p_target_position"),
			&PositionAlongSurface::set_target_position);

	ADD_PROPERTY(
			PropertyInfo(Variant::VECTOR2, "target_position"),
			"set_target_position", "get_target_position");

	ClassDB::bind_method(D_METHOD("get_side"), &PositionAlongSurface::get_side);
	ClassDB::bind_method(D_METHOD("is_valid"), &PositionAlongSurface::is_valid);

	ClassDB::bind_method(D_METHOD("reset"), &PositionAlongSurface::reset);
	ClassDB::bind_method(
			D_METHOD("match_current_grab", "surface", "character_center"),
			&PositionAlongSurface::match_current_grab);
	ClassDB::bind_method(
			D_METHOD(
					"match_surface_target_and_collider", "surface",
					"target_point", "collider", "clips_to_surface_bounds",
					"matches_target_to_character_dimensions",
					"rejects_non_overlapping_results"),
			&PositionAlongSurface::match_surface_target_and_collider,
			DEFVAL(false), DEFVAL(true), DEFVAL(true));
	ClassDB::bind_method(
			D_METHOD("update_target_projection_onto_surface"),
			&PositionAlongSurface::update_target_projection_onto_surface);
	ClassDB::bind_method(
			D_METHOD("to_string", "verbose", "includes_projection"),
			&PositionAlongSurface::to_string, DEFVAL(true), DEFVAL(false));
	ClassDB::bind_static_method(
			"PositionAlongSurface", D_METHOD("copy", "destination", "source"),
			&PositionAlongSurface::copy);
}
