extends Reference
class_name CollisionCheckUtils

# Checks whether a collision would occur with any surface during the given
# instructions.
# 
# -   This is calculated by stepping through each discrete physics frame, which
#     should exactly emulate the actual Player trajectory that would be used.
# -   This also records some trajectory state.
static func check_instructions_discrete_frame_state( \
        edge_calc_params: EdgeCalcParams, \
        instructions: EdgeInstructions, \
        vertical_step: VerticalEdgeStep, \
        horizontal_steps: Array, \
        trajectory: EdgeTrajectory) -> SurfaceCollision:
    var collision_params := edge_calc_params.collision_params
    var movement_params := edge_calc_params.movement_params
    var current_instruction_index := -1
    var next_instruction: EdgeInstruction = instructions.instructions[0]
    var delta_sec := Time.PHYSICS_TIME_STEP_SEC
    var is_first_jump := true
    var previous_time: float = instructions.instructions[0].time
    var current_time := previous_time + delta_sec
    var end_time := vertical_step.time_step_end
    var is_pressing_left := false
    var is_pressing_right := false
    var is_pressing_jump := false
    var horizontal_acceleration_sign := 0
    var position := edge_calc_params.origin_waypoint.position
    var velocity := edge_calc_params.velocity_start
    var has_started_instructions := false
    var displacement := Vector2.INF
    var collision: SurfaceCollision
    
    var current_horizontal_step_index := 0
    var current_horizontal_step: EdgeStep = horizontal_steps[0]
    var continuous_horizontal_state: Array
    var continuous_vertical_state: Array
    var continuous_position := Vector2.INF
    var instruction_with_position: EdgeInstruction
    
    # Record positions for edge annotation debugging.
    var frame_discrete_positions := []
    trajectory.jump_instruction_end = null
    trajectory.horizontal_instructions = []
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < end_time:
        # Update position for this frame, according to the velocity from the
        # previous frame.
        delta_sec = Time.PHYSICS_TIME_STEP_SEC
        displacement = velocity * delta_sec
        
        # Iterate through the horizontal steps in order to calculate what the
        # frame positions would be according to our continuous movement
        # calculations.
        while current_horizontal_step.time_step_end < current_time:
            current_horizontal_step_index += 1
            current_horizontal_step = \
                    horizontal_steps[current_horizontal_step_index]
        continuous_horizontal_state = \
                HorizontalMovementUtils.calculate_horizontal_state_for_time( \
                        movement_params, \
                        current_horizontal_step, \
                        current_time)
        continuous_vertical_state = VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step( \
                        movement_params, \
                        vertical_step, \
                        current_time)
        continuous_position.x = continuous_horizontal_state[0]
        continuous_position.y = continuous_vertical_state[0]
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
            # - To debug why this is failing, try rendering only the failing
            #   path somehow.
#            collision = check_frame_for_collision( \
#                    collision_params, \
#                    position, \
#                    displacement)
            if collision != null:
                trajectory.frame_discrete_positions_from_test = \
                        PoolVector2Array(frame_discrete_positions)
                return collision
        else:
            # Don't check for collisions if we aren't moving anywhere.
            # We can assume that all frame starting positions are not colliding
            # with anything; otherwise, it should have been caught from the
            # motion of the previous frame. The collision margin could yield
            # collision results in the initial frame, but we want to ignore
            # these.
            collision = null
        
        # This point corresponds to when Player._physics_process would be
        # called:
        # - The position for the current frame has been calculated from the
        #   previous frame's velocity.
        # - Any collision state has been calculated.
        # - We can now check whether inputs have changed.
        # - We can now calculate the velocity for the current frame.
        
        while next_instruction != null and \
                next_instruction.time < current_time:
            current_instruction_index += 1
            
            # FIXME: --A:
            # - Think about at what point the velocity change from the step
            #   instruction happens.
            # - Is this at the right time?
            # - Is it too late?
            # - Does it reflect actual playback?
            # - Should initial jump_boost happen sooner?
            
            instruction_with_position = EdgeInstruction.new( \
                    next_instruction.input_key, \
                    next_instruction.time, \
                    next_instruction.is_pressed, \
                    continuous_position)
            
            match next_instruction.input_key:
                "jump":
                    is_pressing_jump = next_instruction.is_pressed
                    if is_pressing_jump:
                        velocity.y = movement_params.jump_boost
                    else:
                        # Record the positions of instruction starts and ends.
                        trajectory.jump_instruction_end = \
                                instruction_with_position
                "move_left":
                    horizontal_acceleration_sign = \
                            -1 if \
                            next_instruction.is_pressed else \
                            0
                    # Record the positions of instruction starts and ends.
                    trajectory.horizontal_instructions.push_back( \
                            instruction_with_position)
                "move_right":
                    horizontal_acceleration_sign = \
                            1 if \
                            next_instruction.is_pressed else \
                            0
                    # Record the positions of instruction starts and ends.
                    trajectory.horizontal_instructions.push_back( \
                            instruction_with_position)
                "grab_wall":
                    pass
                "face_left":
                    pass
                "face_right":
                    pass
                _:
                    Utils.error()
            
            next_instruction = \
                    instructions.instructions \
                            [current_instruction_index + 1] if \
                    current_instruction_index + 1 < \
                            instructions.instructions.size() else \
                    null
        
        # FIXME: ------------------------------:
        # - After implementing instruction execution, check whether it also
        #   does this, and whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction set, the current elapsed
#            # time of the instruction set will be less than a full frame. So
#            # we use a delta_sec that represents the actual time the
#            # instruction set should have been running for so far.
#            delta_sec = current_time - instructions.instructions[0].time
        
        # Record the position for edge annotation debugging.
        frame_discrete_positions.push_back(position)
        
        # Update state for the next frame.
        position += displacement
        velocity = MovementUtils.update_velocity_in_air( \
                velocity, \
                delta_sec, \
                is_pressing_jump, \
                is_first_jump, \
                horizontal_acceleration_sign, \
                movement_params)
        velocity = MovementUtils.cap_velocity( \
                velocity, \
                movement_params, \
                movement_params.max_horizontal_speed_default)
        previous_time = current_time
        current_time += delta_sec
    
    # Check the last frame that puts us up to end_time.
    delta_sec = end_time - current_time
    displacement = velocity * delta_sec
    # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
    # - To debug why this is failing, try rendering only the failing path
    #   somehow.
#    collision = check_frame_for_collision( \
#            collision_params, \
#            position, \
#            displacement)
    if collision != null:
        trajectory.frame_discrete_positions_from_test = \
                PoolVector2Array(frame_discrete_positions)
        return collision
    
    # Record the position for edge annotation debugging.
    frame_discrete_positions.push_back(position + displacement)
    trajectory.frame_discrete_positions_from_test = \
            PoolVector2Array(frame_discrete_positions)
    
    return null

# Checks whether a collision would occur with any surface during the given
# horizontal step. This is calculated by stepping through each physics frame,
# which should exactly emulate the actual Player trajectory that would be used.
# The main error with this approach is that successive steps will be tested
# with their start time perfectly aligned to a physics frame boundary, but when
# executing a resulting instruction set, the physics frame boundaries will line
# up at different times.
static func check_discrete_horizontal_step_for_collision( \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams, \
        horizontal_step: EdgeStep) -> SurfaceCollision:
    var collision_params := edge_calc_params.collision_params
    var movement_params := edge_calc_params.movement_params
    var delta_sec := Time.PHYSICS_TIME_STEP_SEC
    var is_first_jump := true
    # On average, an instruction set will start halfway through a physics
    # frame, so let's use that average here.
    var previous_time := horizontal_step.time_step_start - delta_sec * 0.5
    var current_time := previous_time + delta_sec
    var step_end_time := horizontal_step.time_step_end
    var position := horizontal_step.position_step_start
    var velocity := horizontal_step.velocity_step_start
    var has_started_instructions := false
    var jump_instruction_end_time := \
            step_calc_params.vertical_step.time_instruction_end
    var is_pressing_jump := jump_instruction_end_time > current_time
    var is_pressing_move_horizontal := \
            current_time > horizontal_step.time_instruction_start and \
            current_time < horizontal_step.time_instruction_end
    var horizontal_acceleration_sign := 0
    var displacement := Vector2.INF
    var collision: SurfaceCollision
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update state for the current frame.
        delta_sec = Time.PHYSICS_TIME_STEP_SEC
        displacement = velocity * delta_sec
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            collision = check_frame_for_collision( \
                    collision_params, \
                    position, \
                    displacement)
            if collision != null:
                return collision
        else:
            # Don't check for collisions if we aren't moving anywhere.
            # We can assume that all frame starting positions are not colliding
            # with anything; otherwise, it should have been caught from the
            # motion of the previous frame. The collision margin could yield
            # collision results in the initial frame, but we want to ignore
            # these.
            collision = null
        
        # Determine whether the jump button is still being pressed.
        is_pressing_jump = jump_instruction_end_time > current_time
        
        # Determine whether the horizontal movement button is still being
        # pressed.
        is_pressing_move_horizontal = \
                current_time > horizontal_step.time_instruction_start and \
                current_time < horizontal_step.time_instruction_end
        horizontal_acceleration_sign = \
                horizontal_step.horizontal_acceleration_sign if \
                is_pressing_move_horizontal else \
                0
        
        # FIXME: E: After implementing instruction execution, check whether it
        #           also does this, and whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction, the current elapsed
#            # time of the instruction will be less than a full frame. So we
#            # use a delta_sec that represents the actual time the instruction
#            # should have been running for so far.
#            delta_sec = current_time - horizontal_step.time_step_start
        
        # Update state for the next frame.
        position += displacement
        velocity = MovementUtils.update_velocity_in_air( \
                velocity, \
                delta_sec, \
                is_pressing_jump, \
                is_first_jump, \
                horizontal_acceleration_sign, \
                movement_params)
        velocity = MovementUtils.cap_velocity( \
                velocity, \
                movement_params, \
                movement_params.max_horizontal_speed_default)
        previous_time = current_time
        current_time += delta_sec
    
    # Check the last frame that puts us up to end_time.
    delta_sec = step_end_time - current_time
    displacement = velocity * delta_sec
    collision = check_frame_for_collision( \
            collision_params, \
            position, \
            displacement)
    if collision != null:
        return collision
    
    return null

# Checks whether a collision would occur with any surface during the given
# horizontal step. This is calculated by considering the continuous physics
# state according to the parabolic equations of motion. This does not
# necessarily accurately reflect the actual Player trajectory that would be
# used.
static func check_continuous_horizontal_step_for_collision( \
        step_result_metadata: EdgeStepCalcResultMetadata, \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams, \
        horizontal_step: EdgeStep) -> SurfaceCollision:
    Profiler.start( \
            ProfilerMetric.CHECK_CONTINUOUS_HORIZONTAL_STEP_FOR_COLLISION, \
            edge_calc_params.collision_params.thread_id)
    
    var collision_params := edge_calc_params.collision_params
    var movement_params := edge_calc_params.movement_params
    var vertical_step := step_calc_params.vertical_step
    var delta_sec := Time.PHYSICS_TIME_STEP_SEC
    var previous_time := horizontal_step.time_step_start
    var current_time := previous_time + delta_sec
    var step_end_time := horizontal_step.time_step_end
    var previous_position := horizontal_step.position_step_start
    var current_position := previous_position
    var current_velocity := horizontal_step.velocity_step_start
    var displacement: Vector2
    var horizontal_state: Array
    var vertical_state: Array
    var collision: SurfaceCollision
    
    ###########################################################################
    # Record some extra collision state when debugging an edge calculation.
    var collision_result_metadata: CollisionCalcResultMetadata
    if step_result_metadata != null:
        collision_result_metadata = CollisionCalcResultMetadata.new( \
                edge_calc_params, \
                step_calc_params, \
                horizontal_step)
        step_result_metadata.collision_result_metadata = \
                collision_result_metadata
    ###########################################################################
    
    # Record the positions and velocities for edge annotation debugging.
    var frame_positions := [current_position]
    horizontal_step.frame_positions = frame_positions
    var frame_velocities := [current_velocity]
    horizontal_step.frame_velocities = frame_velocities
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update state for the current frame.
        horizontal_state = \
                HorizontalMovementUtils.calculate_horizontal_state_for_time( \
                        movement_params, \
                        horizontal_step, \
                        current_time)
        vertical_state = VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step( \
                        movement_params, \
                        vertical_step, \
                        current_time)
        current_position.x = horizontal_state[0]
        current_position.y = vertical_state[0]
        current_velocity.x = horizontal_state[1]
        current_velocity.y = vertical_state[1]
        displacement = current_position - previous_position
        
        assert(displacement != Vector2.ZERO)
        
        # Check for collision.
        collision = check_frame_for_collision( \
                collision_params, \
                previous_position, \
                displacement)
        if collision != null:
            break
        
        # Update state for the next frame.
        previous_position = current_position
        previous_time = current_time
        current_time += delta_sec
        
        # Record the positions and velocities for edge annotation debugging.
        frame_positions.push_back(current_position)
        frame_velocities.push_back(current_velocity)
    
    # Check the last frame that puts us up to end_time.
    current_time = step_end_time
    if collision == null and \
            !Geometry.are_floats_equal_with_epsilon( \
                    previous_time, \
                    current_time):
        horizontal_state = \
                HorizontalMovementUtils.calculate_horizontal_state_for_time( \
                        movement_params, \
                        horizontal_step, \
                        current_time)
        vertical_state = VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step( \
                        movement_params, \
                        vertical_step, \
                        current_time)
        current_position.x = horizontal_state[0]
        current_position.y = vertical_state[0]
        current_velocity.x = horizontal_state[1]
        current_velocity.y = vertical_state[1]
        displacement = current_position - previous_position
        assert(displacement != Vector2.ZERO)
        
        collision = check_frame_for_collision( \
                collision_params, \
                previous_position, \
                displacement)
        
        if collision == null:
            # Record the positions and velocities for edge annotation
            # debugging.
            frame_positions.push_back(current_position)
            frame_velocities.push_back(current_velocity)
    
    if collision != null and collision_result_metadata != null:
        # Record some extra state from before/after/during collision for
        # debugging.
        collision_result_metadata.record_collision( \
                previous_position, \
                displacement, \
                collision)
    
    var edge_result_metadata := \
            step_result_metadata.edge_result_metadata if \
            step_result_metadata != null else \
            null
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric.CHECK_CONTINUOUS_HORIZONTAL_STEP_FOR_COLLISION, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    return collision

# Determines whether the given motion of the given shape would collide with a
# surface.
# 
# -   This often generates false negatives if the player is moving away from a
#     surface that they were already colliding with beforehand.
# -   If a collision would occur, this returns information about the collision.
static func check_frame_for_collision( \
        collision_params: CollisionCalcParams, \
        position_start: Vector2, \
        displacement: Vector2, \
        is_recursing := false) -> SurfaceCollision:
    collision_params.player.position = position_start
    var kinematic_collision := collision_params.player.move_and_collide( \
            displacement, \
            true, \
            true, \
            true)
    
    if kinematic_collision == null:
        # No collision found for this frame.
        return null
    
    var surface_collision := SurfaceCollision.new()
    surface_collision.position = kinematic_collision.position
    surface_collision.player_position = \
            position_start + kinematic_collision.travel
    
    var surface_side := \
            Utils.get_which_surface_side_collided(kinematic_collision)
    var is_touching_floor := surface_side == SurfaceSide.FLOOR
    var is_touching_ceiling := surface_side == SurfaceSide.CEILING
    var is_touching_left_wall := surface_side == SurfaceSide.LEFT_WALL
    var is_touching_right_wall := surface_side == SurfaceSide.RIGHT_WALL
    var tile_map: TileMap = kinematic_collision.collider
    var tile_map_result := CollisionTileMapCoordResult.new()
    Geometry.get_collision_tile_map_coord( \
            tile_map_result, \
            kinematic_collision.position, \
            tile_map, \
            is_touching_floor, \
            is_touching_ceiling, \
            is_touching_left_wall, \
            is_touching_right_wall)
    if !tile_map_result.is_godot_floor_ceiling_detection_correct:
        is_touching_floor = !is_touching_floor
        is_touching_ceiling = !is_touching_ceiling
        surface_side = tile_map_result.surface_side
    
    if tile_map_result.tile_map_coord == Vector2.INF:
        # Invalid collision state.
        if collision_params.movement_params \
                .asserts_no_preexisting_collisions_during_edge_calculations:
            Utils.error()
        surface_collision.is_valid_collision_state = false
        return null
    
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord( \
            tile_map_result.tile_map_coord, \
            tile_map)
    if !collision_params.surface_parser.has_surface_for_tile( \
            tile_map, \
            tile_map_index, \
            surface_side):
        # Invalid collision state.
        if collision_params.movement_params \
                .asserts_no_preexisting_collisions_during_edge_calculations:
            Utils.error()
        surface_collision.is_valid_collision_state = false
        return null
    
    var surface := collision_params.surface_parser.get_surface_for_tile( \
            tile_map, \
            tile_map_index, \
            surface_side)
    
    surface_collision.surface = surface
    surface_collision.is_valid_collision_state = true
    
    # Check whether this collision is with a surface that we're actually moving
    # away from.
    var is_moving_away_from_surface: bool 
    match surface.side:
        SurfaceSide.FLOOR:
            is_moving_away_from_surface = displacement.y < 0.0
        SurfaceSide.LEFT_WALL:
            is_moving_away_from_surface = displacement.x > 0.0
        SurfaceSide.RIGHT_WALL:
            is_moving_away_from_surface = displacement.x < 0.0
        SurfaceSide.CEILING:
            is_moving_away_from_surface = displacement.y > 0.0
        _:
            Utils.error()
    if is_moving_away_from_surface:
        if is_recursing:
            # Invalid collision state.
            if collision_params.movement_params \
                    .asserts_no_preexisting_collisions_during_edge_calculations:
                Utils.error()
            surface_collision.is_valid_collision_state = false
            return null
        
        # Try the collision check again with a reduced margin and a slight
        # offset.
        var old_margin := collision_params.player.get_safe_margin()
        collision_params.player.set_safe_margin(0.0)
        position_start += surface.normal * 0.001
        surface_collision = check_frame_for_collision( \
                collision_params, \
                position_start, \
                displacement, \
                true)
        collision_params.player.set_safe_margin(old_margin)
    
    return surface_collision
