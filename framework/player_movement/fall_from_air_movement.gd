extends PlayerMovement
class_name FallFromAirMovement

func _init(params: MovementParams).("fall_from_air", params) -> void:
    self.can_traverse_edge = false
    self.can_traverse_to_air = false
    self.can_traverse_from_air = true

func get_all_reachable_surface_instructions_from_air(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: PositionAlongSurface, start_velocity: Vector2) -> Array:
    # FIXME: B *** Model after JumpFromPlatformMovement to consider all reachable nodes
#    var displacement = end.target_point - start
#
#    # Solve a quadratic equation for duration.
#    var discriminant = start_velocity.y * start_velocity.y - 2 * params.gravity * -displacement.y
#    if discriminant < 0:
#        # We can't reach the end position with our start position and velocity.
#        return null
#    var discriminant_sqrt = sqrt(discriminant)
#    var duration = (-start_velocity.y + discriminant_sqrt) / params.gravity
#    if duration < 0:
#        duration = (-start_velocity.y - discriminant_sqrt) / params.gravity
#
#    var duration_for_horizontal_displacement = \
#            abs(displacement.x / params.max_horizontal_speed_default)
#
#    # Check whether the horizontal displacement is possible.
#    if duration < duration_for_horizontal_displacement:
#        return null
#
#    var horizontal_movement_input_name = "move_left" if displacement.x < 0 else "move_right"
#
#    # FIXME: Add support for maintaining horizontal speed when falling, and needing to push back
#    # the other way to slow it.
#    var instructions := [
#        # The horizontal movement.
#        PlayerInstruction.new(horizontal_movement_input_name, 0, true),
#        PlayerInstruction.new(horizontal_movement_input_name, duration_for_horizontal_displacement, false),
#    ]
#
#    return PlayerInstructions.new(instructions, duration, displacement.length())
    return []
