extends PlayerMovement
class_name JumpFromPlatformMovement

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    pass

func get_instructions_for_edge(start: PositionAlongSurface, end: PositionAlongSurface) -> Array:
    # FIXME: LEFT OFF HERE: Need to reconcile PositionAlongSurface vs Vector2 (maybe I should also store Vector2 in PositionAlongSurface?)
    var displacement: Vector2 = end.player_center - start.player_center
    var max_vertical_displacement := -(params.jump_boost * params.jump_boost) / 2 / params.gravity
    var duration_to_peak := -params.jump_boost / params.gravity
    
    # Check whether the vertical displacement is possible.
    if max_vertical_displacement < displacement.y:
        return []
    
    var duration_from_peak_to_end = (start.y + max_vertical_displacement - end.y) / params.gravity
    var duration_for_horizontal_displacement = displacement.x / params.max_horizontal_speed_default
    var duration = duration_to_peak + duration_from_peak_to_end
    
    # Check whether the horizontal displacement is possible.
    if duration < duration_for_horizontal_displacement:
        return []
    
    # FIXME: LEFT OFF HERE
    # - Hold sideways for duration_for_horizontal_displacement
    # - Hold up for duration_to_peak
    # 
    var instructions := []
    
    
    return instructions

func get_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> Array:
    # FIXME
    return []

func get_max_upward_range() -> float:
    # FIXME
    return 0.0

func get_max_horizontal_range() -> float:
    # FIXME
    return 0.0
