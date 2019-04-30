extends PlayerMovement
class_name JumpFromPlatformMovement

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

# FIXME: Update other references to this API
func get_all_edges_from_surface(surface: Surface) -> Array:
    # FIXME: LEFT OFF HERE: A ***************
    # - Get nearby and fallable
    # - For each, determine where the best jump-off point would be from the starting surface.
    # - call _get_possible_instructions_for_positions
    return []

func get_possible_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    return _get_possible_instructions_for_positions(start.target_point, end)

func _get_possible_instructions_for_positions(start: Vector2, end: Vector2) -> PlayerInstructions:
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
