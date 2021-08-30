class_name ClimbToNeighborSurfaceCalculator
extends EdgeCalculator


const NAME := "ClimbToNeighborSurfaceCalculator"
const EDGE_TYPE := EdgeType.CLIMB_TO_NEIGHBOR_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := false


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR) -> void:
    pass


func get_can_traverse_from_surface(
        surface: Surface,
        collision_params: CollisionCalcParams) -> bool:
    if !is_instance_valid(surface):
        return false
    
    var movement_params := collision_params.movement_params
    
    var can_grab_surface := \
            surface.side == SurfaceSide.FLOOR and \
            movement_params.can_grab_floors or \
            surface.side == SurfaceSide.CEILING and \
            movement_params.can_grab_ceilings or \
            (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL) and \
            movement_params.can_grab_walls
    
    return can_grab_surface and \
            (_get_can_grab_neighbor(surface, true, movement_params) or \
            _get_can_grab_neighbor(surface, false, movement_params))


func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    for is_clockwise in [true, false]:
        var can_grab_neighbor := _get_can_grab_neighbor(
                origin_surface,
                is_clockwise,
                collision_params.movement_params)
        if !can_grab_neighbor:
            continue
        
        var jump_land_positions := _calculate_jump_land_positions(
                origin_surface,
                is_clockwise,
                collision_params.movement_params)
        
        ########################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation(
                collision_params.debug_params,
                jump_land_positions.jump_position,
                jump_land_positions.land_position,
                null):
            return
        ########################################################################
        
        var inter_surface_edges_result := InterSurfaceEdgesResult.new(
                origin_surface,
                jump_land_positions.land_position.surface,
                edge_type,
                [jump_land_positions])
        inter_surface_edges_results.push_back(inter_surface_edges_result)
        
        var edge := calculate_edge(
                null,
                collision_params,
                jump_land_positions.jump_position,
                jump_land_positions.land_position,
                jump_land_positions.velocity_start)
        inter_surface_edges_result.valid_edges.push_back(edge)


func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    if edge_result_metadata != null:
        edge_result_metadata.edge_calc_result_type = \
                EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP
        edge_result_metadata.waypoint_validity = \
                WaypointValidity.WAYPOINT_VALID
    var instructions := _calculate_instructions(
            position_start,
            position_end,
            collision_params.movement_params)
    var trajectory := _calculate_trajectory(
            position_start,
            position_end,
            collision_params.movement_params)
    return ClimbToNeighborSurfaceEdge.new(
            self,
            position_start,
            position_end,
            velocity_start,
            collision_params.movement_params,
            instructions,
            trajectory)


func _calculate_jump_land_positions(
        origin_surface: Surface,
        is_clockwise: bool,
        movement_params: MovementParameters) -> JumpLandPositions:
    var neighbor := \
            origin_surface.clockwise_neighbor if \
            is_clockwise else \
            origin_surface.counter_clockwise_neighbor
    var is_convex := _get_is_neighbor_convex(
            origin_surface,
            is_clockwise)
    var corner_point := \
            origin_surface.last_point if \
            is_clockwise else \
            origin_surface.first_point
    var is_left_side := \
            origin_surface.side == SurfaceSide.RIGHT_WALL or \
            neighbor.side == SurfaceSide.RIGHT_WALL
    var is_top_side := \
            origin_surface.side == SurfaceSide.FLOOR or \
            neighbor.side == SurfaceSide.FLOOR
    
    var target_x_offset := \
            -movement_params.collider_half_width_height.x if \
            is_left_side else \
            movement_params.collider_half_width_height.x
    var target_y_offset := \
            -movement_params.collider_half_width_height.y if \
            is_top_side else \
            movement_params.collider_half_width_height.y
    
    var start_target_point: Vector2
    var end_target_point: Vector2
    if is_convex:
        var is_wall := \
                origin_surface.side == SurfaceSide.LEFT_WALL or \
                origin_surface.side == SurfaceSide.RIGHT_WALL
        var start_target_offset := \
                Vector2(target_x_offset, 0.0) if \
                is_wall else \
                Vector2(0.0, target_y_offset)
        var end_target_offset := \
                Vector2(0.0, target_y_offset) if \
                is_wall else \
                Vector2(target_x_offset, 0.0)
        start_target_point = corner_point + start_target_offset
        end_target_point = corner_point + end_target_offset
    else:
        var target_point := \
                corner_point + Vector2(target_x_offset, target_y_offset)
        start_target_point = target_point
        end_target_point = target_point
    
    var start_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    start_target_point,
                    origin_surface,
                    movement_params.collider_half_width_height)
    var end_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    end_target_point,
                    neighbor,
                    movement_params.collider_half_width_height)
    
    var velocity_start: Vector2
    if origin_surface.side == SurfaceSide.FLOOR:
        # Assume that the character will have reached max speed by the time
        # they've walked to the end of the floor surface.
        var velocity_x := \
                movement_params.max_horizontal_speed_default if \
                is_clockwise else \
                -movement_params.max_horizontal_speed_default
        velocity_start = Vector2(velocity_x, 0.0)
    else:
        # Non-floor surfaces use constant velocity, so we don't need to
        # bother with setting the initial velocity
        velocity_start = Vector2.ZERO
    
    return JumpLandPositions.new(
            start_position,
            end_position,
            velocity_start,
            false,
            false,
            false)


func _calculate_instructions(
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters) -> EdgeInstructions:
    var start_side := position_start.side
    var end_side := position_end.side
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    var is_left_side := \
            start_side == SurfaceSide.RIGHT_WALL or \
            end_side == SurfaceSide.RIGHT_WALL
    var is_top_side := \
            start_side == SurfaceSide.FLOOR or \
            end_side == SurfaceSide.FLOOR
    var is_wall := \
            start_side == SurfaceSide.LEFT_WALL or \
            start_side == SurfaceSide.RIGHT_WALL
    
    var instructions: Array
    
    if is_convex:
        var input_key_move: String
        var input_key_grab: String
        if is_wall:
            if is_top_side:
                input_key_move = "mu"
            else:
                input_key_move = "md"
            
            if is_left_side:
                input_key_grab = "mr"
            else:
                input_key_grab = "ml"
        else:
            if is_left_side:
                input_key_move = "ml"
            else:
                input_key_move = "mr"
            
            if is_top_side:
                input_key_grab = "md"
            else:
                input_key_grab = "mu"
        
        var grab_instruction := EdgeInstruction.new(
                input_key_grab,
                0.0,
                true)
        var move_instruction := EdgeInstruction.new(
                input_key_move,
                0.0,
                true)
        
        instructions = [grab_instruction, move_instruction]
        
    else:
        var input_key: String
        if is_wall:
            if is_top_side:
                input_key = "md"
            else:
                input_key = "mu"
        else:
            if is_left_side:
                input_key = "mr"
            else:
                input_key = "ml"
        
        var move_instruction := EdgeInstruction.new(
                input_key,
                0.0,
                true)
        
        instructions = [move_instruction]
    
    var duration := _calculate_duration(
            position_start,
            position_end,
            movement_params)
    
    return EdgeInstructions.new(
            instructions,
            duration,
            false)


func _calculate_trajectory(
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters) -> EdgeTrajectory:
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    
    if !is_convex:
        return null
    
    var trajectory := EdgeTrajectory.new()
    
    trajectory.waypoint_positions = [
        position_start.target_point,
        position_end.target_point,
    ]
    
    if !movement_params.includes_discrete_trajectory_state and \
            !movement_params \
                    .includes_continuous_trajectory_positions and \
            !movement_params.includes_continuous_trajectory_velocities:
        return trajectory
    
    var start_side := position_start.side
    var end_side := position_end.side
    var is_clockwise := \
            position_start.surface.clockwise_neighbor == position_end.surface
    var is_left_side := \
            start_side == SurfaceSide.RIGHT_WALL or \
            end_side == SurfaceSide.RIGHT_WALL
    var is_top_side := \
            start_side == SurfaceSide.FLOOR or \
            end_side == SurfaceSide.FLOOR
    var is_wall := \
            start_side == SurfaceSide.LEFT_WALL or \
            start_side == SurfaceSide.RIGHT_WALL
    var corner_position := \
            position_start.surface.last_point if \
            is_clockwise else \
            position_start.surface.first_point
    var half_width := movement_params.collider_half_width_height.x
    var half_height := movement_params.collider_half_width_height.y
    
    var duration := _calculate_duration(
            position_start,
            position_end,
            movement_params)
    
    var frame_count := int(ceil(duration / Time.PHYSICS_TIME_STEP))
    
    var positions := []
    positions.resize(frame_count)
    var velocities := []
    velocities.resize(frame_count)
    
    var frame_index := 0
    var position: Vector2
    var velocity: Vector2
    
    # -   Movement around a convex corner is comprised of two parts:
    #     -   a part based on the start surface,
    #     -   and a part based on the end surface.
    # -   The transition between these two parts happens when the character's
    #     bounding box is completely past the end of the start surface.
    # -   The overall rounding-the-corner-edge-movement starts when the
    #     character's center is past the end of the start surface, and ends
    #     when the character's center is no longer past the end of the end
    #     surface.
    
    if is_wall:
        # Rounding a corner from a wall.
        
        position.x = \
                corner_position.x - half_width if \
                is_left_side else \
                corner_position.x + half_width
        position.y = corner_position.y
        
        velocity.x = \
                CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION if \
                is_left_side else \
                -CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION
        velocity.y = \
                movement_params.climb_up_speed if \
                is_top_side else \
                movement_params.climb_down_speed
        
        var is_character_past_end := false
        while !is_character_past_end:
            positions[frame_index] = position
            velocities[frame_index] = velocity
            
            frame_index += 1
            position.y += velocity.y * Time.PHYSICS_TIME_STEP
            var distance_past_edge := \
                    corner_position.y - position.y if \
                    is_top_side else \
                    position.y - corner_position.y
            position.x = corner_position.x + Sc.geometry \
                    .calculate_displacement_x_for_vertical_distance_past_edge(
                            distance_past_edge,
                            !is_left_side,
                            movement_params.rounding_corner_calc_shape,
                            movement_params.rounding_corner_calc_shape_rotation)
            is_character_past_end = \
                    position.y + half_height <= corner_position.y if \
                    is_top_side else \
                    position.y - half_height >= corner_position.y
        
        var acceleration_x: float
        if !is_top_side:
            velocity.x = \
                    movement_params.ceiling_crawl_speed if \
                    is_left_side else \
                    -movement_params.ceiling_crawl_speed
            acceleration_x = 0.0
        else:
            acceleration_x = \
                    movement_params.walk_acceleration if \
                    is_left_side else \
                    -movement_params.walk_acceleration
        
        velocity.y = \
                CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION if \
                is_top_side else \
                -CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
        
        var is_rounding_corner_finished := false
        while !is_rounding_corner_finished and \
                frame_index < frame_count:
            positions[frame_index] = position
            velocities[frame_index] = velocity
            
            frame_index += 1
            position.x += velocity.x * Time.PHYSICS_TIME_STEP
            var distance_past_edge := \
                    corner_position.x - position.x if \
                    is_left_side else \
                    position.x - corner_position.x
            position.y = corner_position.y + Sc.geometry \
                    .calculate_displacement_y_for_horizontal_distance_past_edge(
                            distance_past_edge,
                            is_top_side,
                            movement_params.rounding_corner_calc_shape,
                            movement_params.rounding_corner_calc_shape_rotation)
            # Account for acceleration along the floor.
            velocity.x += acceleration_x * Time.PHYSICS_TIME_STEP
            velocity.x = clamp(
                    velocity.x,
                    -movement_params.max_horizontal_speed_default,
                    movement_params.max_horizontal_speed_default)
            is_rounding_corner_finished = \
                    position.x >= corner_position.x if \
                    is_left_side else \
                    position.x <= corner_position.x
        
    else:
        # Rounding a from a floor or ceiling.
        
        position.x = corner_position.x
        position.y = \
                corner_position.y - half_height if \
                is_top_side else \
                corner_position.y + half_height
        
        # Assume that the character will have reached max speed by the time
        # they've walked to the end of a floor surface.
        velocity.x = \
                -movement_params.max_horizontal_speed_default if \
                is_left_side else \
                movement_params.max_horizontal_speed_default
        velocity.y = \
                CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION if \
                is_top_side else \
                -CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION
        
        var is_character_past_end := false
        while !is_character_past_end:
            positions[frame_index] = position
            velocities[frame_index] = velocity
            
            frame_index += 1
            position.x += velocity.x * Time.PHYSICS_TIME_STEP
            var distance_past_edge := \
                    corner_position.x - position.x if \
                    is_left_side else \
                    position.x - corner_position.x
            position.y = corner_position.y + Sc.geometry \
                    .calculate_displacement_y_for_horizontal_distance_past_edge(
                            distance_past_edge,
                            is_top_side,
                            movement_params.rounding_corner_calc_shape,
                            movement_params.rounding_corner_calc_shape_rotation)
            is_character_past_end = \
                    position.x + half_width <= corner_position.x if \
                    is_left_side else \
                    position.x - half_width >= corner_position.x
        
        velocity.x = \
                CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION if \
                is_left_side else \
                -CharacterActionHandler \
                        .MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION
        velocity.y = \
                movement_params.climb_down_speed if \
                is_top_side else \
                movement_params.climb_up_speed
        
        var is_rounding_corner_finished := false
        while !is_rounding_corner_finished and \
                frame_index < frame_count:
            positions[frame_index] = position
            velocities[frame_index] = velocity
            
            frame_index += 1
            position.y += velocity.y * Time.PHYSICS_TIME_STEP
            var distance_past_edge := \
                    corner_position.y - position.y if \
                    is_top_side else \
                    position.y - corner_position.y
            position.x = corner_position.x + Sc.geometry \
                    .calculate_displacement_x_for_vertical_distance_past_edge(
                            distance_past_edge,
                            !is_left_side,
                            movement_params.rounding_corner_calc_shape,
                            movement_params.rounding_corner_calc_shape_rotation)
            is_rounding_corner_finished = \
                    position.y >= corner_position.y if \
                    is_top_side else \
                    position.y <= corner_position.y
    
    # In case the movement reached the destination before the expected number
    # of frames, we remove any trailing frames.
    positions.resize(frame_index)
    velocities.resize(frame_index)
    
    if movement_params.includes_discrete_trajectory_state:
        trajectory.frame_discrete_positions_from_test = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_positions:
        trajectory.frame_continuous_positions_from_steps = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_velocities:
        trajectory.frame_continuous_velocities_from_steps = \
                PoolVector2Array(velocities)
    
    # Update the trajectory distance.
    trajectory.distance_from_continuous_trajectory = \
            EdgeTrajectoryUtils.sum_distance_between_frames(positions)
    
    return trajectory


func _calculate_duration(
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters) -> float:
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    
    if !is_convex:
        return 0.0
    
    var start_side := position_start.side
    var end_side := position_end.side
    var is_clockwise := \
            position_start.surface.clockwise_neighbor == position_end.surface
    var is_left_side := \
            start_side == SurfaceSide.RIGHT_WALL or \
            end_side == SurfaceSide.RIGHT_WALL
    var is_top_side := \
            start_side == SurfaceSide.FLOOR or \
            end_side == SurfaceSide.FLOOR
    var is_wall := \
            start_side == SurfaceSide.LEFT_WALL or \
            start_side == SurfaceSide.RIGHT_WALL
    var corner_position := \
            position_start.surface.last_point if \
            is_clockwise else \
            position_start.surface.first_point
    
    # -   Movement around a convex corner is comprised of two parts:
    #     -   a part based on the start surface,
    #     -   and a part based on the end surface.
    # -   The transition between these two parts happens when the character's
    #     bounding box is completely past the end of the start surface.
    # -   The overall rounding-the-corner-edge-movement starts when the
    #     character's center is past the end of the start surface, and ends
    #     when the character's center is no longer past the end of the end
    #     surface.
    
    var speed_start := \
            movement_params.max_horizontal_speed_default if \
            start_side == SurfaceSide.FLOOR else \
            movement_params.ceiling_crawl_speed if \
            start_side == SurfaceSide.CEILING else \
            movement_params.climb_up_speed if \
            is_top_side else \
            movement_params.climb_down_speed
    var speed_end := \
            movement_params.max_horizontal_speed_default if \
            end_side == SurfaceSide.FLOOR else \
            movement_params.ceiling_crawl_speed if \
            end_side == SurfaceSide.CEILING else \
            movement_params.climb_down_speed if \
            is_top_side else \
            movement_params.climb_up_speed
    
    var distance_start := \
            movement_params.collider_half_width_height.y if \
            is_wall else \
            movement_params.collider_half_width_height.x
    
    var distance_end: float
    if is_wall:
        distance_end = Sc.geometry \
                .calculate_displacement_x_for_vertical_distance_past_edge(
                        distance_start,
                        !is_left_side,
                        movement_params.rounding_corner_calc_shape,
                        movement_params.rounding_corner_calc_shape_rotation)
    else:
        distance_end = Sc.geometry \
                .calculate_displacement_y_for_horizontal_distance_past_edge(
                        distance_start,
                        is_top_side,
                        movement_params.rounding_corner_calc_shape,
                        movement_params.rounding_corner_calc_shape_rotation)
    
    var duration_start := abs(distance_start / speed_start)
    # FIXME: ----- Account for acceleration-along-floor when climbing over wall.
    var duration_end := abs(distance_end / speed_end)
    
    return duration_start + duration_end


func _get_can_grab_neighbor(
        surface: Surface,
        is_clockwise: bool,
        movement_params: MovementParameters) -> bool:
    var neighbor := \
            surface.clockwise_neighbor if \
            is_clockwise else \
            surface.counter_clockwise_neighbor
    return neighbor.side == SurfaceSide.FLOOR and \
            movement_params.can_grab_floors or \
            neighbor.side == SurfaceSide.CEILING and \
            movement_params.can_grab_ceilings or \
            (neighbor.side == SurfaceSide.LEFT_WALL or \
            neighbor.side == SurfaceSide.RIGHT_WALL) and \
            movement_params.can_grab_walls


func _get_is_neighbor_convex(
        surface: Surface,
        is_clockwise: bool) -> bool:
    return is_instance_valid(surface.clockwise_convex_neighbor) if \
            is_clockwise else \
            is_instance_valid(surface.counter_clockwise_convex_neighbor)
