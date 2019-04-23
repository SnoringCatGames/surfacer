extends PlayerMovement
class_name JumpFromPlatformMovement

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    pass

func get_instructions_for_edge(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> PlayerInstructions:
    return _get_instructions_for_positions(start.target_point, end.target_point)

func get_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    return _get_instructions_for_positions(start.target_point, end)

func _get_instructions_for_positions(start: Vector2, end: Vector2) -> PlayerInstructions:
    var displacement: Vector2 = end - start
    var max_vertical_displacement := get_max_upward_distance()
    var duration_to_peak := -params.jump_boost / params.gravity
    
    assert(duration_to_peak > 0)
    
    # Check whether the vertical displacement is possible.
    if max_vertical_displacement < displacement.y:
        return null
    
    var discriminant = \
            (end.y - (start.y + max_vertical_displacement)) * 2 / \
            params.gravity
    if discriminant < 0:
        # We can't reach the end position with our start position.
        return null
    var duration_from_peak_to_end = sqrt(discriminant)
    var duration_for_horizontal_displacement = \
            abs(displacement.x / params.max_horizontal_speed_default)
    var duration = duration_to_peak + duration_from_peak_to_end
    
    # Check whether the horizontal displacement is possible.
    if duration < duration_for_horizontal_displacement:
        return null
    
    var horizontal_movement_input_name = "move_left" if displacement.x < 0 else "move_right"
    
    # FIXME: Add support for maintaining horizontal speed when falling, and needing to push back
    # the other way to slow it.
    var instructions := [
        # The horizontal movement.
        PlayerInstruction.new(horizontal_movement_input_name, 0, true),
        PlayerInstruction.new(horizontal_movement_input_name, duration_for_horizontal_displacement, false),
        # The vertical movement.
        PlayerInstruction.new("move_up", 0, true),
        PlayerInstruction.new("move_up", duration_to_peak, false),
    ]
    
    return PlayerInstructions.new(instructions, duration, displacement.length())

func get_max_upward_distance() -> float:
    return -(params.jump_boost * params.jump_boost) / 2 / params.gravity

func get_max_horizontal_distance() -> float:
    return -params.jump_boost / params.gravity * 2 * params.max_horizontal_speed_default
