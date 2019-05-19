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
        a_closest_point = Geometry.get_closest_point_on_polyline_to_polyline(a, b)
        b_closest_point = Geometry.get_closest_point_on_polyline_to_polyline(b, a)
        
        # Only consider the far-end and closest points if they are distinct.
        possible_jump_points = [a_near_end]
        possible_land_points = [b_near_end]
        if a.size() > 1:
            possible_jump_points.push_back(a_far_end)
        if a_closest_point != a_near_end and a_closest_point != a_far_end:
            possible_jump_points.push_back(a_closest_point)
        if b.size() > 1:
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
            instructions = _get_possible_instructions_for_positions( \
                    space_state, jump_position.target_point, land_position.target_point)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

func get_possible_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    return _get_possible_instructions_for_positions(space_state, start.target_point, end)

func _get_possible_instructions_for_positions(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: Vector2) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: A ***************
    # - Put all of this bit on hold for the moment, since we can first finish the infrastructure
    #   and test things with a bunch a false-positives from these simplistic jump-land pairs.
    # - 
    # - Handle movement constraints:
    #   - Try (test/emulate) the jump without any constraints.
    #     - HOW TO TEST:
    #       - Will need to implement custom time-slicing of the movement, while calculating the
    #         collider's position along the trajectory at each slice/frame.
    #         - This will use the same numerical approach used to calculate instruction sets.
    #         - So this won't necessarily match the actual player movement that results from
    #           discrete integration.
    #       - Will need to use some Godot collision checking utility to get the TileMap-based
    #         Collision.
    #       - Is there a way to know exactly what interval Godot will use for the physics
    #         timesteps? Or to explicitely tell it what interval to use?
    #         - Default is 1/60.0
    #       - (Follow-up) Does Godot have "ray-tracing" for arbitrary shapes?
    #         - More importantly, is this what they use under the hood when detecting collisions
    #           between frame positions?
    #         - Could be useful to solve tunneling problem between slices/frames?
    #   - If we hit a surface, then recursively try a constraint on either side of that surface and
    #     re-test.
    #     - (probably) DFS with intelligently picking "better" branches according to heuristics?
    #     - (probably not) Or should we check all branches, and return multiple possible edges?
    #   - If impossible, abort.
    #   - Calculate the constraints
    #   - If we hit a vertical surface:
    #     - For the "above" constraint branch:
    #       - If we cannot reach this height with our max range, then abort.
    #       - If we are not currently still pressing up, then we need to backtrack and re-calculate
    #         all constraints from the moment we had released up.
    #     - For the "below" constraint branch:
    #       - 
    #   - How to use the constraints:
    #     - It should be simple enough to modify the original parabolic movement calculations?
    #   - We should be able to re-use slice/frame state from the last verified constraint, rather
    #     than needing to re-compute everything from the start of the movement each time we
    #     consider a new constraint.
    #   - Will also want to record some other info for annotations/debugging:
    #     - Store on PlayerInstructions.
    #     - A polyline representation of the ultimate trajectory, including time-slice-testing and
    #       considering constraints.
    #     - The ultimate sequence of constraints that were used.
    # - 
    # - Account for half-width/height offset needed to clear the edge of B (if possible).
    # - Also, account for the half-width/height offset needed to not fall onto A.
    # - Include a margin around constraints and land position.
    # - 
    # - Make the 144-cell diagram in InkScape and add to docs.
    # - Storing possibly 9 edges from A to B.
    
    
    
#    var constraint_offset = params.collider_half_width_height + \
#            Vector2(EDGE_MOVEMENT_ACTUAL_MARGIN, EDGE_MOVEMENT_ACTUAL_MARGIN)
#
#    var shape_query_params := Physics2DShapeQueryParameters.new()
#    shape_query_params.collide_with_areas = false
#    shape_query_params.collide_with_bodies = true
#    shape_query_params.collision_layer = TILE_MAP_COLLISION_LAYER
#    shape_query_params.exclude = []
#    shape_query_params.margin = EDGE_MOVEMENT_TEST_MARGIN
#    shape_query_params.motion = Vector2.ZERO
#    shape_query_params.shape_rid = params.collider_shape.get_rid()
#    shape_query_params.transform = Transform2D.IDENTITY
#
#    var position_prev: Vector2
#    var position_next: Vector2
#    var colliding_surface: Surface
#    var constraints: Array
#
#    # FIXME: Setup iteration over time slices
#
#    position_prev = position_next
#    position_next = Vector2.INF # FIXME: Calculate position for the current time slice
#
#    shape_query_params.transform = Transform2D(0.0, position_prev)
#    shape_query_params.motion = position_next - position_prev
#
#    colliding_surface = test_movement(space_state, shape_query_params)
#
#    if colliding_surface:
#        constraints = _calculate_constraints(colliding_surface, constraint_offset)
#
#        for constraint in constraints:
#            # FIXME: Recurse
#            pass
    
    
    
    
    
    
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
