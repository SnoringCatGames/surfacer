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
    var a_end: Vector2 = a.vertices[origin_surface.vertices.size() - 1]
    var b_start: Vector2
    var b_end: Vector2
    var a_is_slope_positive := _get_is_slope_positive(a)
    var b_is_slope_positive: bool
    var x_overlap_type: int
    var y_overlap_type: int
    var start_target_point: Vector2
    var end_target_point: Vector2
    var start := PositionAlongSurface.new()
    var end := PositionAlongSurface.new()
    var instructions: PlayerInstructions
    var edges = []
    
    var possible_surfaces := _get_nearby_and_fallable_surfaces(a)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other PlayerMovement type, so we don't handle those
        # cases here.
        
        b_start = destination_surface.vertices[0]
        b_end = destination_surface.vertices[b.vertices.size() - 1]
        
        b_is_slope_positive = _get_is_slope_positive(b)
        
        x_overlap_type = _get_overlap_type(a, b, true)
        y_overlap_type = _get_overlap_type(a, b, false)
        
        # FIXME: LEFT OFF HERE: A ***************
        # - For each, determine where the best jump-off point would be from the starting surface.
        #   - Use the vertical or horiontal extent of the collider shape as an ideal offset from
        #     the edge of the destination surface.
        # - no - OR, maybe just use three positions:
        #       - A.start
        #       - A.end
        #       - A.closest_to_B
        #       - Also, add some conditional logic before calling
        #         _get_possible_instructions_for_positions, to try to offset the x or y by half the
        #         width/height if possible while still staying in bounds of surface.
        #       - Add logic to first try one end of A, then the other end of A, then the closest point
        #         on A.
        #     - Then, think about how to actually handle the different surface alignment/overlap cases
        #       within _get_possible_instructions_for_positions:
        #       - Would it work to define a list of intermediate positions+side pairings, such that the
        #         player's movement has to be on that side of that point before hitting the next
        #         constraint or end?
        #     - Then, handle other surface-type pairings
        # - Enumerate all 2304 (6(x-overlap)*6(y-overlap)*2(a-slope)*2(b-slope)*4(a-side-type)*4(b-side-type))‬ possibilities of surface x/y overlap and surface slopes??:
        #   - Calculate which case the surface pair is.
        #   - 
        # - Account for half-width/height offset if possible
        # - 
        
        match a.side:
            SurfaceSide.FLOOR:
                match b.side:
                    SurfaceSide.FLOOR:
                        if a_end.x + player_half_width < b_start.x:
                            # The destination is far enough away that the player could jump from
                            # the closest point on the origin surface, and not need to have any
                            # backward movement in their jump trajectory.
                            start_target_point = Vector2(a_end.x, a_end_vertex.y)
                            end_target_point = Vector2(b_start.x, destination_surface_start.y)
                        elif a_start.x - player_half_width > b_end.x:
                            # The destination is far enough away that the player could jump from
                            # the closest point on the origin surface, and not need to have any
                            # backward movement in their jump trajectory.
                            start_target_point = Vector2(a_start.x, a_start_vertex.y)
                            end_target_point = Vector2(b_end.x, destination_surface_end.y)
                        elif a_start.x + player_half_width < b_start.x:
                            # The surfaces are aligned such that the player can jump vert
                        elif a_end.x - player_half_width > b_end.x:
                        elif false:
                    SurfaceSide.LEFT_WALL:
                        pass
                    SurfaceSide.RIGHT_WALL:
                        pass
                    SurfaceSide.CEILING:
                        pass
            SurfaceSide.LEFT_WALL:
                pass
            SurfaceSide.RIGHT_WALL:
                pass
            SurfaceSide.CEILING:
                pass
        
        start_target_point = 
        end_target_point = 
        
        start.match_surface_target_and_collider(a, start_target_point, \
                params.collider_half_width_height)
        end.match_surface_target_and_collider(b, end_target_point, \
                params.collider_half_width_height)
        instructions = \
                _get_possible_instructions_for_positions(start.target_point, end.target_point)
        if instructions != null:
            edges.push_back(PlatformGraphEdge.new(start, end, instructions))
    
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
