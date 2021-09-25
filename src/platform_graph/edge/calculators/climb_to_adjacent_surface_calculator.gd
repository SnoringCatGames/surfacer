class_name ClimbToAdjacentSurfaceCalculator
extends EdgeCalculator


const NAME := "ClimbToAdjacentSurfaceCalculator"
const EDGE_TYPE := EdgeType.CLIMB_TO_ADJACENT_SURFACE_EDGE
const IS_A_JUMP_CALCULATOR := false
const IS_GRAPHABLE := true


func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR,
        IS_GRAPHABLE) -> void:
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
        needs_extra_wall_land_horizontal_speed := false,
        basis_edge: EdgeAttempt = null) -> Edge:
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
            collision_params.movement_params,
            instructions.duration)
    
    if trajectory.collided_early:
        var positions: PoolVector2Array = \
                trajectory.frame_continuous_positions_from_steps if \
                !trajectory.frame_continuous_positions_from_steps.empty() else \
                trajectory.frame_discrete_positions_from_test.empty()
        var early_end := \
                positions[positions.size() - 1] if \
                !positions.empty() else \
                Vector2.INF
        if early_end != Vector2.INF:
            position_end = PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            early_end,
                            position_end.surface,
                            collision_params.movement_params.collider,
                            false)
            var duration := (positions.size() - 1) * Time.PHYSICS_TIME_STEP
            instructions.duration = duration
    
    var velocity_end := _get_velocity_end(
            position_start,
            position_end,
            collision_params.movement_params)
    
    return ClimbToAdjacentSurfaceEdge.new(
            self,
            position_start,
            position_end,
            velocity_start,
            velocity_end,
            trajectory.distance_from_continuous_trajectory,
            instructions.duration,
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
    
    var start_target_point: Vector2
    var end_target_point: Vector2
    if is_convex:
        start_target_point = corner_point
        end_target_point = corner_point
    else:
        var target_x_offset := \
                -movement_params.collider.half_width_height.x if \
                is_left_side else \
                movement_params.collider.half_width_height.x
        var target_y_offset := \
                -movement_params.collider.half_width_height.y if \
                is_top_side else \
                movement_params.collider.half_width_height.y
        var target_point := \
                corner_point + Vector2(target_x_offset, target_y_offset)
        target_point = Sc.geometry.project_shape_onto_surface(
                target_point,
                movement_params.collider,
                neighbor,
                true)
        target_point = Sc.geometry.project_shape_onto_surface(
                target_point,
                movement_params.collider,
                origin_surface,
                true)
        
        if !(movement_params.collider.shape is RectangleShape2D):
            # Round shapes get closer to the correct target with each pair of
            # axially-aligned projections.
            target_point = Sc.geometry.project_shape_onto_surface(
                    target_point,
                    movement_params.collider,
                    neighbor,
                    true)
            target_point = Sc.geometry.project_shape_onto_surface(
                    target_point,
                    movement_params.collider,
                    origin_surface,
                    true)
        
        start_target_point = target_point
        end_target_point = target_point
    
    var start_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    start_target_point,
                    origin_surface,
                    movement_params.collider)
    var end_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    end_target_point,
                    neighbor,
                    movement_params.collider)
    
    var velocity_start := _get_velocity_start(
            start_position,
            end_position,
            movement_params)
    
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
        movement_params: MovementParameters,
        duration: float) -> EdgeTrajectory:
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    
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
    
    if !is_convex:
        _populate_concave_trajectory(
                trajectory,
                position_start,
                position_end,
                movement_params,
                duration)
    else:
        _populate_convex_trajectory(
                trajectory,
                position_start,
                position_end,
                movement_params,
                duration)
    
    return trajectory


func _populate_concave_trajectory(
        trajectory: EdgeTrajectory,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters,
        duration: float) -> void:
    var position := position_start.target_point
    var velocity := Vector2.ZERO
    
    var positions := [position]
    var velocities := [velocity]
    
    if movement_params.includes_discrete_trajectory_state:
        trajectory.frame_discrete_positions_from_test = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_positions:
        trajectory.frame_continuous_positions_from_steps = \
                PoolVector2Array(positions)
    if movement_params.includes_continuous_trajectory_velocities:
        trajectory.frame_continuous_velocities_from_steps = \
                PoolVector2Array(velocities)
    
    trajectory.distance_from_continuous_trajectory = 0.00001


func _populate_convex_trajectory(
        trajectory: EdgeTrajectory,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters,
        duration: float) -> void:
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
    var half_width := movement_params.collider.half_width_height.x
    var half_height := movement_params.collider.half_width_height.y
    
    var next_neighbor := \
            position_end.surface.clockwise_neighbor if \
            is_clockwise else \
            position_end.surface.counter_clockwise_neighbor
    var is_next_neighbor_concave := \
            next_neighbor == \
                    position_end.surface.clockwise_concave_neighbor or \
            next_neighbor == \
                    position_end.surface.counter_clockwise_concave_neighbor
    var next_neighbor_normal_side_override := SurfaceSide.NONE
    if is_next_neighbor_concave:
        match position_end.surface.side:
            SurfaceSide.FLOOR:
                next_neighbor_normal_side_override = \
                        SurfaceSide.RIGHT_WALL if \
                        is_clockwise else \
                        SurfaceSide.LEFT_WALL
            SurfaceSide.LEFT_WALL:
                next_neighbor_normal_side_override = \
                        SurfaceSide.FLOOR if \
                        is_clockwise else \
                        SurfaceSide.CEILING
            SurfaceSide.RIGHT_WALL:
                next_neighbor_normal_side_override = \
                        SurfaceSide.CEILING if \
                        is_clockwise else \
                        SurfaceSide.FLOOR
            SurfaceSide.CEILING:
                next_neighbor_normal_side_override = \
                        SurfaceSide.LEFT_WALL if \
                        is_clockwise else \
                        SurfaceSide.RIGHT_WALL
            _:
                Sc.logger.error()
    
    var frame_count := int(ceil(duration / Time.PHYSICS_TIME_STEP))
    
    var positions := []
    positions.resize(frame_count)
    var velocities := []
    velocities.resize(frame_count)
    
    var ran_into_concave_next_neighbor := false
    
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
        
        position = Vector2(INF, corner_position.y)
        position = Sc.geometry.project_shape_onto_surface(
                position,
                movement_params.rounding_corner_calc_shape,
                position_start.surface,
                true)
        if is_next_neighbor_concave:
            # This prevents collisions with concave next neighbors
            # (which can form tight cusps).
            var override: Vector2 = \
                    Sc.geometry.project_away_from_concave_neighbor(
                            position,
                            next_neighbor,
                            next_neighbor_normal_side_override,
                            movement_params.rounding_corner_calc_shape)
            if override != Vector2.INF:
                ran_into_concave_next_neighbor = true
                position = override
        
        if !ran_into_concave_next_neighbor:
            velocity.x = 0.0
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
                position = Sc.geometry \
                        .project_shape_onto_convex_corner_preserving_tangent_position( \
                                position,
                                movement_params.rounding_corner_calc_shape,
                                position_start.surface,
                                position_end.surface)
                
                is_character_past_end = \
                        position.y + half_height <= corner_position.y if \
                        is_top_side else \
                        position.y - half_height >= corner_position.y
                
                if is_next_neighbor_concave:
                    # This prevents collisions with concave next neighbors
                    # (which can form tight cusps).
                    var override: Vector2 = \
                            Sc.geometry.project_away_from_concave_neighbor(
                                    position,
                                    next_neighbor,
                                    next_neighbor_normal_side_override,
                                    movement_params.rounding_corner_calc_shape)
                    if override != Vector2.INF:
                        ran_into_concave_next_neighbor = true
                        position = override
                        if frame_index < frame_count:
                            positions[frame_index] = position
                            velocities[frame_index] = velocity
                        break
        
        if !ran_into_concave_next_neighbor:
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
            
            velocity.y = 0.0
            
            var is_rounding_corner_finished := false
            while !is_rounding_corner_finished and \
                    frame_index < frame_count:
                positions[frame_index] = position
                velocities[frame_index] = velocity
                
                frame_index += 1
                position.x += velocity.x * Time.PHYSICS_TIME_STEP
                position = Sc.geometry \
                        .project_shape_onto_convex_corner_preserving_tangent_position( \
                                position,
                                movement_params.rounding_corner_calc_shape,
                                position_end.surface,
                                position_start.surface)
                
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
                
                if is_next_neighbor_concave:
                    # This prevents collisions with concave next neighbors
                    # (which can form tight cusps).
                    var override: Vector2 = \
                            Sc.geometry.project_away_from_concave_neighbor(
                                    position,
                                    next_neighbor,
                                    next_neighbor_normal_side_override,
                                    movement_params.rounding_corner_calc_shape)
                    if override != Vector2.INF:
                        ran_into_concave_next_neighbor = true
                        position = override
                        if frame_index < frame_count:
                            positions[frame_index] = position
                            velocities[frame_index] = velocity
                        break
        
    else:
        # Rounding from a floor or ceiling.
        
        position = Vector2(corner_position.x, INF)
        position = Sc.geometry.project_shape_onto_surface(
                position,
                movement_params.rounding_corner_calc_shape,
                position_start.surface,
                true)
        if is_next_neighbor_concave:
            # This prevents collisions with concave next neighbors
            # (which can form tight cusps).
            var override: Vector2 = \
                    Sc.geometry.project_away_from_concave_neighbor(
                            position,
                            next_neighbor,
                            next_neighbor_normal_side_override,
                            movement_params.rounding_corner_calc_shape)
            if override != Vector2.INF:
                ran_into_concave_next_neighbor = true
                position = override
        
        if !ran_into_concave_next_neighbor:
            if is_top_side:
                # Assume that the character will have reached max speed by the time
                # they've walked to the end of a floor surface.
                velocity.x = \
                        -movement_params.max_horizontal_speed_default if \
                        is_left_side else \
                        movement_params.max_horizontal_speed_default
            else:
                velocity.x = \
                        -movement_params.ceiling_crawl_speed if \
                        is_left_side else \
                        movement_params.ceiling_crawl_speed
            velocity.y = 0.0
            
            var is_character_past_end := false
            while !is_character_past_end:
                positions[frame_index] = position
                velocities[frame_index] = velocity
                
                frame_index += 1
                position.x += velocity.x * Time.PHYSICS_TIME_STEP
                position = Sc.geometry \
                        .project_shape_onto_convex_corner_preserving_tangent_position( \
                                position,
                                movement_params.rounding_corner_calc_shape,
                                position_start.surface,
                                position_end.surface)
                
                is_character_past_end = \
                        position.x + half_width <= corner_position.x if \
                        is_left_side else \
                        position.x - half_width >= corner_position.x
                
                if is_next_neighbor_concave:
                    # This prevents collisions with concave next neighbors
                    # (which can form tight cusps).
                    var override: Vector2 = \
                            Sc.geometry.project_away_from_concave_neighbor(
                                    position,
                                    next_neighbor,
                                    next_neighbor_normal_side_override,
                                    movement_params.rounding_corner_calc_shape)
                    if override != Vector2.INF:
                        ran_into_concave_next_neighbor = true
                        position = override
                        if frame_index < frame_count:
                            positions[frame_index] = position
                            velocities[frame_index] = velocity
                        break
        
        if !ran_into_concave_next_neighbor:
            velocity.x = 0.0
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
                position = Sc.geometry \
                        .project_shape_onto_convex_corner_preserving_tangent_position( \
                                position,
                                movement_params.rounding_corner_calc_shape,
                                position_end.surface,
                                position_start.surface)
                
                is_rounding_corner_finished = \
                        position.y >= corner_position.y if \
                        is_top_side else \
                        position.y <= corner_position.y
                
                if is_next_neighbor_concave:
                    # This prevents collisions with concave next neighbors
                    # (which can form tight cusps).
                    var override: Vector2 = \
                            Sc.geometry.project_away_from_concave_neighbor(
                                    position,
                                    next_neighbor,
                                    next_neighbor_normal_side_override,
                                    movement_params.rounding_corner_calc_shape)
                    if override != Vector2.INF:
                        ran_into_concave_next_neighbor = true
                        position = override
                        if frame_index < frame_count:
                            positions[frame_index] = position
                            velocities[frame_index] = velocity
                        break
    
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
    
    trajectory.collided_early = ran_into_concave_next_neighbor


func _get_velocity_start(
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters) -> Vector2:
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    var is_moving_left: bool
    var is_moving_up: bool
    if is_convex:
        is_moving_left = \
                position_start.side == SurfaceSide.LEFT_WALL or \
                position_end.side == SurfaceSide.RIGHT_WALL
        is_moving_up = \
                position_start.side == SurfaceSide.CEILING or \
                position_end.side == SurfaceSide.FLOOR
    else:
        is_moving_left = \
                position_start.side == SurfaceSide.LEFT_WALL or \
                position_end.side == SurfaceSide.LEFT_WALL
        is_moving_up = \
                position_start.side == SurfaceSide.CEILING or \
                position_end.side == SurfaceSide.CEILING
    
    var velocity_x: float
    var velocity_y: float
    match position_start.side:
        SurfaceSide.FLOOR:
            # Assume that the character will have reached max speed by the time
            # they've walked to the end of the floor surface.
            velocity_x = \
                    -movement_params.max_horizontal_speed_default if \
                    is_moving_left else \
                    movement_params.max_horizontal_speed_default
            velocity_y = 0.0
        SurfaceSide.CEILING:
            velocity_x = \
                    -movement_params.ceiling_crawl_speed if \
                    is_moving_left else \
                    movement_params.ceiling_crawl_speed
            velocity_y = 0.0
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            velocity_x = 0.0
            velocity_y = \
                    movement_params.climb_up_speed if \
                    is_moving_up else \
                    movement_params.climb_down_speed
        _:
            Sc.logger.error()
    
    return Vector2(velocity_x, velocity_y)


func _get_velocity_end(
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        movement_params: MovementParameters) -> Vector2:
    var is_convex := \
            position_start.surface.clockwise_convex_neighbor == \
                    position_end.surface or \
            position_start.surface.counter_clockwise_convex_neighbor == \
                    position_end.surface
    
    var velocity_x: float
    var velocity_y: float
    match position_end.side:
        SurfaceSide.FLOOR:
            var is_starting_from_left_wall := \
                    position_start.side == SurfaceSide.LEFT_WALL
            if is_convex:
                var acceleration_x := movement_params.walk_acceleration
                var floor_component_distance: float = abs(Sc.geometry \
                        .calculate_displacement_x_for_vertical_distance_past_edge(
                                movement_params.collider.half_width_height.y,
                                is_starting_from_left_wall,
                                movement_params.rounding_corner_calc_shape))
                var floor_component_speed_x_start := 0.0
                
                # From a basic equation of motion:
                #     v^2 = v_0^2 + 2a(s - s_0)
                #     v = sqrt(v_0^2 + 2a(s - s_0))
                velocity_x = sqrt(
                        floor_component_speed_x_start * \
                        floor_component_speed_x_start + \
                        2 * acceleration_x * floor_component_distance)
                if is_starting_from_left_wall:
                    velocity_x = -velocity_x
                velocity_x = clamp(velocity_x,
                        -movement_params.max_horizontal_speed_default,
                        movement_params.max_horizontal_speed_default)
            else:
                velocity_x = 0.0
            
            velocity_y = 0.0
        SurfaceSide.CEILING:
            var is_starting_from_left_wall := \
                    position_start.side == SurfaceSide.LEFT_WALL
            if is_convex:
                velocity_x = \
                        -movement_params.ceiling_crawl_speed if \
                        is_starting_from_left_wall else \
                        movement_params.ceiling_crawl_speed
            else:
                velocity_x = 0.0
            velocity_y = 0.0
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_starting_from_floor := \
                    position_start.side == SurfaceSide.FLOOR
            var is_ending_on_left_wall := \
                    position_end.side == SurfaceSide.LEFT_WALL
            velocity_x = 0.0
            if is_convex:
                velocity_y = \
                        movement_params.climb_down_speed if \
                        is_starting_from_floor else \
                        movement_params.climb_up_speed
            else:
                velocity_y = 0.0
        _:
            Sc.logger.error()
    
    return Vector2(velocity_x, velocity_y)


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
    
    var speed_start := abs(
            movement_params.max_horizontal_speed_default if \
            start_side == SurfaceSide.FLOOR else \
            movement_params.ceiling_crawl_speed if \
            start_side == SurfaceSide.CEILING else \
            movement_params.climb_up_speed if \
            is_top_side else \
            movement_params.climb_down_speed)
    
    var distance_start := \
            movement_params.collider.half_width_height.y if \
            is_wall else \
            movement_params.collider.half_width_height.x
    
    var distance_end: float
    if is_wall:
        distance_end = abs(Sc.geometry \
                .calculate_displacement_x_for_vertical_distance_past_edge(
                        distance_start,
                        !is_left_side,
                        movement_params.rounding_corner_calc_shape))
    else:
        distance_end = abs(Sc.geometry \
                .calculate_displacement_y_for_horizontal_distance_past_edge(
                        distance_start,
                        is_top_side,
                        movement_params.rounding_corner_calc_shape))
    
    var duration_start := distance_start / speed_start
    
    var duration_end: float
    if end_side != SurfaceSide.FLOOR:
        var speed_end := abs(
                movement_params.max_horizontal_speed_default if \
                end_side == SurfaceSide.FLOOR else \
                movement_params.ceiling_crawl_speed if \
                end_side == SurfaceSide.CEILING else \
                movement_params.climb_down_speed if \
                is_top_side else \
                movement_params.climb_up_speed)
        duration_end = distance_end / speed_end
    else:
        # Account for acceleration-along-floor when climbing over a wall.
        var acceleration_x := movement_params.walk_acceleration
        var end_speed_x_start := 0.0
        # From a basic equation of motion:
        #     v^2 = v_0^2 + 2a(s - s_0)
        #     v = sqrt(v_0^2 + 2a(s - s_0))
        var end_speed_x_end := sqrt(
                end_speed_x_start * end_speed_x_start + \
                2 * acceleration_x * distance_end)
        
        if end_speed_x_end > movement_params.max_horizontal_speed_default:
            # We hit max speed before reaching the end, so we need to account
            # separately for the duration while acceleration and the duration
            # at max speed.
            
            end_speed_x_end = movement_params.max_horizontal_speed_default
            # From a basic equation of motion:
            #     v = v_0 + at
            #     t = (v - v_0) / a
            var acceleration_duration := \
                    (end_speed_x_end - end_speed_x_start) / acceleration_x
            # From a basic equation of motion:
            #     v^2 = v_0^2 + 2a(s - s_0)
            #     (s - s_0) = (v^2 - v_0^2) / 2 / a
            var acceleration_distance := \
                    (end_speed_x_end * end_speed_x_end - \
                    end_speed_x_start * end_speed_x_start) / \
                    2.0 / acceleration_x
            # From a basic equation of motion:
            #     s = s_0 + vt
            #     t = (s - s_0) / v
            var max_velocity_duration := \
                    (distance_end - acceleration_distance) / end_speed_x_end
            
            duration_end = acceleration_duration + max_velocity_duration
        else:
            # From a basic equation of motion:
            #     v = v_0 + at
            #     t = (v - v_0) / a
            duration_end = \
                    (end_speed_x_end - end_speed_x_start) / acceleration_x
    
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
