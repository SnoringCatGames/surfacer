extends PlayerMovement
class_name JumpFromPlatformMovement

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, a: Surface) -> Array:
    var player_half_width := params.collider_half_width_height.x
    var player_half_height := params.collider_half_width_height.y
    var a_start: Vector2 = a.vertices[0]
    var a_end: Vector2 = a.vertices[a.vertices.size() - 1]
    var b_start: Vector2
    var b_end: Vector2
    var a_near_end: Vector2
    var a_far_end: Vector2
    var a_closest_point: Vector2
    var b_near_end: Vector2
    var b_far_end: Vector2
    var b_closest_point: Vector2
    var possible_jump_points: Array
    var possible_land_points: Array
    var possible_jump_land_pairs := []
    var jump_point: Vector2
    var land_point: Vector2
    var jump_position := PositionAlongSurface.new()
    var land_position := PositionAlongSurface.new()
    var instructions: PlayerInstructions
    var weight: float
    var edges = []
    
    var possible_surfaces := _get_nearby_and_fallable_surfaces(a)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other PlayerMovement type, so we don't handle those
        # cases here.
        
        b_start = b.vertices[0]
        b_end = b.vertices[b.vertices.size() - 1]
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
        # nearer and farther.
        if Geometry.distance_squared_from_point_to_rect(a_start, b.bounding_box) < \
                Geometry.distance_squared_from_point_to_rect(a_end, b.bounding_box):
            a_near_end = a_start
            a_far_end = a_end
        else:
            a_near_end = a_end
            a_far_end = a_start
        if Geometry.distance_squared_from_point_to_rect(b_start, a.bounding_box) < \
                Geometry.distance_squared_from_point_to_rect(b_end, a.bounding_box):
            b_near_end = b_start
            b_far_end = b_end
        else:
            b_near_end = b_end
            b_far_end = b_start
        
        # The actual clostest points along each surface could be somewhere in the middle.
        a_closest_point = \
            Geometry.get_closest_point_on_polyline_to_polyline(a.vertices, b.vertices)
        b_closest_point = \
            Geometry.get_closest_point_on_polyline_to_polyline(b.vertices, a.vertices)
        
        # Only consider the far-end and closest points if they are distinct.
        possible_jump_points = [a_near_end]
        possible_land_points = [b_near_end]
        if a.vertices.size() > 1:
            possible_jump_points.push_back(a_far_end)
        if a_closest_point != a_near_end and a_closest_point != a_far_end:
            possible_jump_points.push_back(a_closest_point)
        if b.vertices.size() > 1:
            possible_land_points.push_back(b_far_end)
        if b_closest_point != b_near_end and b_closest_point != b_far_end:
            possible_land_points.push_back(b_closest_point)
        
        # Calculate the pairs of possible jump and land points to check.
        possible_jump_land_pairs.clear()
        for possible_jump_point in possible_jump_points:
            for possible_land_point in possible_land_points:
                possible_jump_land_pairs.push_back(possible_jump_point)
                possible_jump_land_pairs.push_back(possible_land_point)
        
        for i in range(possible_jump_land_pairs.size() - 1):
            jump_point = possible_jump_land_pairs[i]
            land_point = possible_jump_land_pairs[i + 1]
            
            jump_position.match_surface_target_and_collider(a, jump_point, \
                    params.collider_half_width_height)
            land_position.match_surface_target_and_collider(b, land_point, \
                    params.collider_half_width_height)
            instructions = _calculate_jump_instructions( \
                    space_state, jump_position.target_point, land_position.target_point, b)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        start_position: PositionAlongSurface, end_position: Vector2) -> PlayerInstructions:
    return _calculate_jump_instructions( \
            space_state, start_position.target_point, end_position, null)

func _calculate_jump_instructions(space_state: Physics2DDirectSpaceState, \
        start_position: Vector2, end_position: Vector2, \
        destination_surface: Surface) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: --A ********
    # - Figure out how to actually handle vertical movement calculations, after working out the
    #   backtracking for new max_heights from vertical constraints.
    var movement_section := \
            calculate_initial_movement_section_with_vertical_movement(start_position, end_position)
    
    if movement_section == null:
        # The destination is too high to jump to.
        return null
    
    var constraint_offset := params.collider_half_width_height + \
            Vector2(EDGE_MOVEMENT_ACTUAL_MARGIN, EDGE_MOVEMENT_ACTUAL_MARGIN)
    
    movement_section = _calculate_movement_section_from_next_constraint( \
            space_state, movement_section, end_position, constraint_offset, destination_surface)
    
    # FIXME: Add an assert checking that the instructions will end at the correct point, and
    #        without colliding into anything else.
    
    return movement_section.instructions if movement_section != null else null
    
    # FIXME: LEFT OFF HERE: ----A ********
    # - Will also want to record some other info for annotations/debugging:
    #   - Store on PlayerInstructions (but on _MovementSection first, during calculation?).
    #   - A polyline representation of the ultimate trajectory, including time-slice-testing and
    #     considering constraints.
    #   - The ultimate sequence of constraints that were used.
    
    # FIXME: LEFT OFF HERE: A ***************
    # - 
    # - Convert between iterative and recursive?
    # - Account for half-width/height offset needed to clear the edge of B (if possible).
    # - Also, account for the half-width/height offset needed to not fall onto A.
    # - Include a margin around constraints and land position.
    # - Allow for the player to bump into walls/ceiling if they could still reach the land point
    #   afterward (will need to update logic to not include margin when accounting for these hits).
    # - Update the instructions calculations to consider actual discrete timesteps rather than
    #   using continuous algorithms.
    # - Share per-frame state updates logic between the instruction calculations and actual Player
    #   movements.
    # - 
    # - Make the 144-cell diagram in InkScape and add to docs.
    # - Storing possibly 9 edges from A to B.
    
    # FIXME: Add support for maintaining horizontal speed when falling, and needing to push back
    # the other way to slow it.

func _calculate_movement_section_from_next_constraint(space_state: Physics2DDirectSpaceState, \
        previous_movement_section: _MovementSection, end_position: Vector2, \
        constraint_offset: Vector2, destination_surface: Surface) -> _MovementSection:
    var colliding_surface: Surface
    # Array<MovementConstraint>
    var constraints: Array
    
    var next_movement_section := update_movement_section_with_horizontal_movement( \
            previous_movement_section, end_position)
    
    if next_movement_section != null:
        # It might possible to reach the destination with this PlayerMovement (depending on whether
        # there are any intermediate Surfaces in the way).
        
        colliding_surface = \
                check_movement_section_for_collision(space_state, next_movement_section)
        
        # FIXME: LEFT OFF HERE: -A *******
        # - It's possible for the recursion to loop infinitely if constraints keep pushing the
        #   movement back and forth between repeated surfaces.
        #   - Add a list of all previously collided surfaces, and check the list before recursing.
        
        if colliding_surface != null and colliding_surface != destination_surface:
            # There is a Surface interfering with this PlayerMovement, so calculate constraints
            # to divert the movement around either side of the Surface, and test updated
            # instructions for those constraints.
            
            constraints = _calculate_constraints(colliding_surface, constraint_offset)
            
            # FIXME: Add heuristics to pick the "better" constraint.
            for constraint in constraints:
                # Recurse: Calculate movement to the constraint.
                next_movement_section = _calculate_movement_section_from_next_constraint( \
                        space_state, previous_movement_section, constraint.passing_point, \
                        constraint_offset, destination_surface)
                
                if next_movement_section == null:
                    continue
                
                # FIXME: LEFT OFF HERE: ------------A ****************
                # - Update these _MovementSection values when recursing (and with results):
                #   - instruction_index
                #   - active_inputs
                #   - all others...
                
#                    var is_pressing_jump: bool = next_movement_section.active_inputs.has("jump")
#                    if is_pressing_jump and next_movement_section.instructions.is_instruction_in_range( \
#                            JUMP_RELEASE_INSTRUCTION, previous_time, current_time):
#                        is_pressing_jump = false
#                        next_movement_section.active_inputs.erase("jump")
                
                # Recurse: Calculate movement from the constraint to the original destination.
                next_movement_section = _calculate_movement_section_from_next_constraint( \
                        space_state, next_movement_section, end_position, \
                        constraint_offset, destination_surface)
                
                # FIXME: LEFT OFF HERE: -----A *********
                #       - Handle vertical surface constraints:
                #         - For the "above" constraint branch:
                #           - If we cannot reach this height with our max range, then abort.
                #           - If we are not currently still pressing up, then we need to backtrack
                #             and re-calculate all constraints from the moment we had released up.
                #         - For the "below" constraint branch:
                
                if next_movement_section != null:
                    # We found movement that satisfies the constraint.
                    return next_movement_section
            
            # We weren't able to satisfy the constraints.
            return null
        
        else:
            # There is no Surface interfering with this PlayerMovement.
            return next_movement_section
    
    else:
        # It's impossible to reach the destination with this PlayerMovement.
        return null

# Initializes a new _MovementSection with instructions for just the vertical parts of the movement.
func calculate_initial_movement_section_with_vertical_movement( \
        start: Vector2, end: Vector2) -> _MovementSection:
    var total_displacement: Vector2 = end - start
    var max_vertical_displacement := get_max_upward_distance()
    var duration_to_peak := -params.jump_boost / params.gravity
    
    assert(duration_to_peak > 0)
    
    # Check whether the vertical displacement is possible.
    if max_vertical_displacement < total_displacement.y:
        return null
    
    var max_height = start.y + max_vertical_displacement
    var discriminant = \
            (end.y - max_height) * 2 / \
            params.gravity
    if discriminant < 0:
        # We can't reach the end position with our start position.
        return null
    var duration_from_peak_to_end = sqrt(discriminant)
    var duration = duration_to_peak + duration_from_peak_to_end
    
    var instructions_list := [
        # The vertical movement.
        PlayerInstruction.new("jump", 0, true),
        PlayerInstruction.new("jump", duration_to_peak, false),
    ]
    
    var instructions = PlayerInstructions.new(instructions_list, duration, total_displacement.length())
    
    var movement_section := _MovementSection.new()
    movement_section.instructions = instructions
    movement_section.time = 0.0
    movement_section.instruction_index = 0
    movement_section.active_inputs = {}
    movement_section.position = start
    movement_section.velocity = Vector2(0, params.jump_boost)
    movement_section.horizontal_movement_sign = 0
    movement_section.max_height = max_height
    
    return movement_section

# FIXME: Comment
func update_movement_section_with_horizontal_movement( \
        previous_movement_section: _MovementSection, end_position: Vector2) -> _MovementSection:
    var displacement: Vector2 = end_position - previous_movement_section.position
    
    var duration_for_horizontal_displacement := \
            abs(displacement.x / params.max_horizontal_speed_default)
    
    # Check whether the horizontal displacement is possible.
    if previous_movement_section.instructions.duration < duration_for_horizontal_displacement:
        return null
    
    var horizontal_movement_input_name: String
    var horizontal_movement_sign: int
    if displacement.x < 0:
        horizontal_movement_input_name = "move_left"
        horizontal_movement_sign = -1
    elif displacement.x > 0:
        horizontal_movement_input_name = "move_right"
        horizontal_movement_sign = 1
    else:
        horizontal_movement_input_name = "move_right"
        horizontal_movement_sign = 0
    
    var start_time := previous_movement_section.time
    var end_time := start_time + duration_for_horizontal_displacement
    
    var instruction_start := \
            PlayerInstruction.new(horizontal_movement_input_name, start_time, true)
    var instruction_end := PlayerInstruction.new(horizontal_movement_input_name, end_time, false)
    
    var next_movement_section := _MovementSection.new()
    next_movement_section.instructions = previous_movement_section.instructions.duplicate()
    var instruction_index := next_movement_section.instructions.insert(instruction_start)
    next_movement_section.instructions.insert(instruction_end)
    next_movement_section.instruction_index = instruction_index
    next_movement_section.time = end_time
    next_movement_section.active_inputs = previous_movement_section.active_inputs.duplicate()
    next_movement_section.position = end_position
    next_movement_section.velocity.x = params.max_horizontal_speed_default * horizontal_movement_sign
    next_movement_section.horizontal_movement_sign = horizontal_movement_sign
    next_movement_section.max_height = previous_movement_section.max_height
    
    
    
    # FIXME: LEFT OFF HERE: ---A **************
    # - Allow an optional future top-side constraint to be passed in?
    #   - Maybe not, since we might need to back track multiple steps once we've adjusted the
    #     max_height, so the redoing should be handled more directly...
    
    
    return next_movement_section


func get_max_upward_distance() -> float:
    return -(params.jump_boost * params.jump_boost) / 2 / params.gravity

func get_max_horizontal_distance() -> float:
    return -params.jump_boost / params.gravity * 2 * params.max_horizontal_speed_default
