extends PlayerMovement
class_name JumpFromPlatformMovement

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

# FIXME: Update other references to this API
func get_all_edges_from_surface(a: Surface) -> Array:
    var player_half_width := params.collider_half_width_height.x
    var player_half_height := params.collider_half_width_height.y
    var a_start: Vector2 = a.vertices[0]
    var a_end: Vector2 = a.vertices[a.vertices.size() - 1]
    var b_start: Vector2
    var b_end: Vector2
    # FIXME: Remove?
    var a_is_slope_positive := _get_is_slope_positive(a)
    # FIXME: Remove?
    var b_is_slope_positive: bool
    # FIXME: Remove?
    var x_overlap_type: int
    # FIXME: Remove?
    var y_overlap_type: int
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
        
        b_is_slope_positive = _get_is_slope_positive(b)
        
        x_overlap_type = _get_overlap_type(a, b, true)
        y_overlap_type = _get_overlap_type(a, b, false)
        
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
            instructions = \
                    _get_possible_instructions_for_positions(jump_position.target_point, land_position.target_point)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

# FIXME: Move to PlayerMovement or remove?
static func _get_is_slope_positive(surface: Surface) -> bool:
    var start: Vector2 = surface.vertices[0]
    var end: Vector2 = surface.vertices[surface.vertices.size() - 1]
    
    match surface.side:
        SurfaceSide.FLOOR:
            return start.y < end.y
        SurfaceSide.LEFT_WALL:
            return end.x < start.x
        SurfaceSide.RIGHT_WALL:
            return start.x < end.x
        SurfaceSide.CEILING:
            return end.y < start.y
        _:
            Utils.error("Invalid SurfaceSide: %s" % surface.side)
            return false

# FIXME: Move to PlayerMovement or remove?
class _Overlap:
    enum {
        NO_OVERLAP_A_SMALLER,
        NO_OVERLAP_B_SMALLER,
        PARTIAL_OVERLAP_A_SMALLER,
        PARTIAL_OVERLAP_B_SMALLER,
        COMPLETE_OVERLAP_A_SMALLER,
        COMPLETE_OVERLAP_B_SMALLER,
    }

# FIXME: Move to PlayerMovement or remove?
static func _get_overlap_type(a: Surface, b: Surface, check_horizontal: bool) -> int:
    var a_start: float
    var a_end: float
    var b_start: float
    var b_end: float
    
    if check_horizontal:
        a_start = a.vertices[0].x
        a_end = a.vertices[a.vertices.size() - 1].x
        b_start = b.vertices[0].x
        b_end = b.vertices[b.vertices.size() - 1].x
    else:
        a_start = a.vertices[0].y
        a_end = a.vertices[a.vertices.size() - 1].y
        b_start = b.vertices[0].y
        b_end = b.vertices[b.vertices.size() - 1].y
    
    var a_leftmost: float
    var a_rightmost: float
    var b_leftmost: float
    var b_rightmost: float
    
    if a_start <= a_end:
        a_leftmost = a_start
        a_rightmost = a_end
    else:
        a_leftmost = a_end
        a_rightmost = a_start
    
    if b_start <= b_end:
        b_leftmost = b_start
        b_rightmost = b_end
    else:
        b_leftmost = b_end
        b_rightmost = b_start
    
    if a_rightmost < b_leftmost:
        return _Overlap.NO_OVERLAP_A_SMALLER
    elif a_leftmost > b_rightmost:
        return _Overlap.NO_OVERLAP_B_SMALLER
    elif a_leftmost < b_leftmost:
        if a_rightmost < b_rightmost:
            return _Overlap.PARTIAL_OVERLAP_A_SMALLER
        else:
            return _Overlap.COMPLETE_OVERLAP_A_SMALLER
    else:
        if a_rightmost > b_rightmost:
            return _Overlap.PARTIAL_OVERLAP_B_SMALLER
        else:
            return _Overlap.COMPLETE_OVERLAP_B_SMALLER

func get_possible_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    return _get_possible_instructions_for_positions(start.target_point, end)

func _get_possible_instructions_for_positions(start: Vector2, end: Vector2) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: A ***************
    # - 
    # - A constraint consists of 4 pieces of information:
    #   - At THIS coordinate, along THIS axis, movement must be on THIS side of THIS coordinate along the other axis.
    # - 
    # - Constraints idea...
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
    #       - (Follow-up) Does Godot have "ray-tracing" for arbitrary shapes?
    #         - More importantly, is this what they use under the hood when detecting collisions
    #           between frame positions?
    #         - Could be useful to solve tunneling problem between slices/frames?
    #   - If we hit a surface, then recursively try a constraint on either side of that surface and
    #     re-test.
    #     - (probably) DFS with intelligently picking "better" branches accorrding to heuristics?
    #     - (probably not) Or should we check all branches, and return multiple possible edges?
    #   - If impossible, abort.
    #   - If we hit a vertical surface:
    #     - For the "above" constraint branch:
    #       - 
    #     - For the "below" constraint branch:
    #       - 
    #   - We should be able to re-use slice/frame state from the last verified constraint, rather
    #     than needing to re-compute everything from the start of the movement each time we
    #     consider a new constraint.
    #   - Will also want to record some other info for annotations/debugging:
    #     - Store on PlayerInstructions.
    #     - A polyline representation of the ultimate trajectory, including time-slice-testing and
    #       considering constraints.
    #     - The ultimate sequence of constraints that were used.
    # - 
    # - [ABORT] Figure out intermediate constraints
    #   - Assuming jump-from-floor...
    #   - If B.side == FLOOR:
    #     - if jump.y < land.y: # jumping up
    #       - if jump.x < land.x: # jumping right
    #         - if (A.start | B.start | A.end | B.end) is between jump and land:
    #           - # "between" means between both x and y coordinates
    #             - But we also need to consider an offset for the size of the collider
    #           - Add a constraint
    #           - Constraint depends on A.side, B.side, and which point is between
    #           - Constraints could need both a horizontal and a vertical component
    #     - Need to also calculate is_left_end, etc.
    # - 
    # - Account for half-width/height offset needed to clear the edge of B (if possible).
    # - Also, account for the half-width/height offset needed to not fall onto A.
    # - Include a margin around constraints and land position.
    # - 
    # - Make the 144-cell diagram in InkScape and add to docs.
    # - Storing possibly 9 edges from A to B.
    
    
    
    
    
    
    
    
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
