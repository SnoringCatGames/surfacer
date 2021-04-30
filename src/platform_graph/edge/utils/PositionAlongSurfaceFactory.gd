class_name PositionAlongSurfaceFactory
extends Node

static func create_position_offset_from_target_point(
        target_point: Vector2,
        surface: Surface,
        collider_half_width_height: Vector2,
        clips_to_surface_bounds := false) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(
            surface,
            target_point,
            collider_half_width_height,
            clips_to_surface_bounds,
            true)
    return position

static func create_position_from_unmodified_target_point(
        target_point: Vector2,
        surface: Surface,
        collider_half_width_height: Vector2) -> PositionAlongSurface:
    assert(surface != null)
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(
            surface,
            target_point,
            collider_half_width_height,
            false,
            false)
    return position

static func create_position_without_surface(
        target_point: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.target_point = target_point
    return position
