class_name PositionAlongSurfaceFactory
extends Node


static func create_position_offset_from_target_point(
        target_point: Vector2,
        surface: Surface,
        collider: RotatedShape,
        clips_to_surface_bounds := false) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(
            surface,
            target_point,
            collider,
            clips_to_surface_bounds,
            true)
    return position


static func create_position_from_unmodified_target_point(
        target_point: Vector2,
        surface: Surface) -> PositionAlongSurface:
    assert(surface != null)
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(
            surface,
            target_point,
            null,
            false,
            false)
    return position


static func create_position_without_surface(
        target_point: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.target_point = target_point
    return position
