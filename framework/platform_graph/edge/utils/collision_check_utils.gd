extends Reference
class_name CollisionCheckUtils

# Checks whether a collision would occur with any surface during the given instructions.
# 
# -   This is calculated by stepping through each discrete physics frame, which should exactly
#     emulate the actual Player trajectory that would be used.
# -   This also records some trajectory state.
static func check_instructions_discrete_frame_state( \
        edge_calc_params: EdgeCalcParams, \
        instructions: EdgeInstructions, \
        vertical_step: VerticalEdgeStep, \
        horizontal_steps: Array, \
        trajectory: EdgeTrajectory) -> SurfaceCollision:
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
    var space_state := edge_calc_params.space_state
    var shape_query_params := edge_calc_params.shape_query_params
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
#    var frame_continuous_positions := [position] # FIXME: REMOVE
    trajectory.jump_instruction_end = null
    trajectory.horizontal_instructions = []
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < end_time:
        # Update position for this frame, according to the velocity from the previous frame.
        delta_sec = Time.PHYSICS_TIME_STEP_SEC
        displacement = velocity * delta_sec
        shape_query_params.transform = Transform2D(movement_params.collider_rotation, position)
        shape_query_params.motion = displacement
        
        # Iterate through the horizontal steps in order to calculate what the frame positions would
        # be according to our continuous movement calculations.
        while current_horizontal_step.time_step_end < current_time:
            current_horizontal_step_index += 1
            current_horizontal_step = horizontal_steps[current_horizontal_step_index]
        continuous_horizontal_state = \
                HorizontalMovementUtils.calculate_horizontal_state_for_time( \
                        movement_params, \
                        current_horizontal_step, \
                        current_time)
        continuous_vertical_state = \
                VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                        movement_params, \
                        vertical_step, \
                        current_time)
        continuous_position.x = continuous_horizontal_state[0]
        continuous_position.y = continuous_vertical_state[0]
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
            # - To debug why this is failing, try rendering only the failing path somehow.
#            collision = FrameCollisionCheckUtils.check_frame_for_collision(space_state, \
#                    shape_query_params, movement_params.collider_half_width_height, \
#                    movement_params.collider_rotation, edge_calc_params.surface_parser)
            if collision != null:
                trajectory.frame_discrete_positions_from_test = \
                        PoolVector2Array(frame_discrete_positions)
#                trajectory.frame_continuous_positions = \ # FIXME: REMOVE
#                        PoolVector2Array(frame_continuous_positions)
                return collision
        else:
            # Don't check for collisions if we aren't moving anywhere.
            # We can assume that all frame starting positions are not colliding with anything;
            # otherwise, it should have been caught from the motion of the previous frame. The
            # collision margin could yield collision results in the initial frame, but we want to
            # ignore these.
            collision = null
        
        # This point corresponds to when Player._physics_process would be called:
        # - The position for the current frame has been calculated from the previous frame's velocity.
        # - Any collision state has been calculated.
        # - We can now check whether inputs have changed.
        # - We can now calculate the velocity for the current frame.
        
        while next_instruction != null and \
                next_instruction.time < current_time:
            current_instruction_index += 1
            
            # FIXME: --A:
            # - Think about at what point the velocity change from the step instruction happens.
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
                    instructions.instructions[current_instruction_index + 1] if \
                    current_instruction_index + 1 < instructions.instructions.size() else \
                    null
        
        # FIXME: ------------------------------:
        # - After implementing instruction execution, check whether it also does this, and whether
        #   this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction set, the current elapsed time of the
#            # instruction set will be less than a full frame. So we use a delta_sec that represents the
#            # actual time the instruction set should have been running for so far.
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
        
        # Record the position for edge annotation debugging.
#        frame_continuous_positions.push_back(continuous_position) # FIXME: REMOVE
    
    # Check the last frame that puts us up to end_time.
    delta_sec = end_time - current_time
    displacement = velocity * delta_sec
    shape_query_params.transform = Transform2D( \
            movement_params.collider_rotation, \
            position)
    shape_query_params.motion = displacement
    continuous_horizontal_state = \
            HorizontalMovementUtils.calculate_horizontal_state_for_time( \
                    movement_params, \
                    current_horizontal_step, \
                    end_time)
    continuous_vertical_state = \
            VerticalMovementUtils.calculate_vertical_state_for_time_from_step( \
                    movement_params, \
                    vertical_step, \
                    end_time)
    continuous_position.x = continuous_horizontal_state[0]
    continuous_position.y = continuous_vertical_state[0]
    # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
    # - To debug why this is failing, try rendering only the failing path somehow.
#    collision = FrameCollisionCheckUtils.check_frame_for_collision(space_state, \
#            shape_query_params, movement_params.collider_half_width_height, \
#            movement_params.collider_rotation, edge_calc_params.surface_parser)
    if collision != null:
        trajectory.frame_discrete_positions_from_test = \
                PoolVector2Array(frame_discrete_positions)
#        trajectory.frame_continuous_positions = PoolVector2Array(frame_continuous_positions) # FIXME: REMOVE
        return collision
    
    # Record the position for edge annotation debugging.
    frame_discrete_positions.push_back(position + displacement)
#    frame_continuous_positions.push_back(continuous_position) # FIXME: REMOVE
    trajectory.frame_discrete_positions_from_test = \
            PoolVector2Array(frame_discrete_positions)
#    trajectory.frame_continuous_positions = PoolVector2Array(frame_continuous_positions) # FIXME: REMOVE
    
    return null

# Checks whether a collision would occur with any surface during the given horizontal step. This
# is calculated by stepping through each physics frame, which should exactly emulate the actual
# Player trajectory that would be used. The main error with this approach is that successive steps
# will be tested with their start time perfectly aligned to a physics frame boundary, but when
# executing a resulting instruction set, the physics frame boundaries will line up at different
# times.
static func check_discrete_horizontal_step_for_collision( \
        edge_calc_params: EdgeCalcParams, \
        step_calc_params: EdgeStepCalcParams, \
        horizontal_step: EdgeStep) -> SurfaceCollision:
    var movement_params := edge_calc_params.movement_params
    var delta_sec := Time.PHYSICS_TIME_STEP_SEC
    var is_first_jump := true
    # On average, an instruction set will start halfway through a physics frame, so let's use that
    # average here.
    var previous_time := horizontal_step.time_step_start - delta_sec * 0.5
    var current_time := previous_time + delta_sec
    var step_end_time := horizontal_step.time_step_end
    var position := horizontal_step.position_step_start
    var velocity := horizontal_step.velocity_step_start
    var has_started_instructions := false
    var jump_instruction_end_time := step_calc_params.vertical_step.time_instruction_end
    var is_pressing_jump := jump_instruction_end_time > current_time
    var is_pressing_move_horizontal := current_time > horizontal_step.time_instruction_start and \
            current_time < horizontal_step.time_instruction_end
    var horizontal_acceleration_sign := 0
    var space_state := edge_calc_params.space_state
    var shape_query_params := edge_calc_params.shape_query_params
    var displacement := Vector2.INF
    var collision: SurfaceCollision
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update state for the current frame.
        delta_sec = Time.PHYSICS_TIME_STEP_SEC
        displacement = velocity * delta_sec
        shape_query_params.transform = Transform2D(movement_params.collider_rotation, position)
        shape_query_params.motion = displacement
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            collision = FrameCollisionCheckUtils.check_frame_for_collision( \
                    space_state, \
                    shape_query_params, \
                    movement_params.collider_half_width_height, \
                    movement_params.collider_rotation, \
                    edge_calc_params.surface_parser)
            if collision != null:
                return collision
        else:
            # Don't check for collisions if we aren't moving anywhere.
            # We can assume that all frame starting positions are not colliding with anything;
            # otherwise, it should have been caught from the motion of the previous frame. The
            # collision margin could yield collision results in the initial frame, but we want to
            # ignore these.
            collision = null
        
        # Determine whether the jump button is still being pressed.
        is_pressing_jump = jump_instruction_end_time > current_time
        
        # Determine whether the horizontal movement button is still being pressed.
        is_pressing_move_horizontal = current_time > horizontal_step.time_instruction_start and \
                current_time < horizontal_step.time_instruction_end
        horizontal_acceleration_sign = \
                horizontal_step.horizontal_acceleration_sign if is_pressing_move_horizontal else 0
        
        # FIXME: E: After implementing instruction execution, check whether it also does this, and
        #           whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction, the current elapsed time of the instruction
#            # will be less than a full frame. So we use a delta_sec that represents the actual time the
#            # instruction should have been running for so far.
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
    shape_query_params.transform = Transform2D(movement_params.collider_rotation, position)
    shape_query_params.motion = displacement
    collision = FrameCollisionCheckUtils.check_frame_for_collision( \
            space_state, \
            shape_query_params, \
            movement_params.collider_half_width_height, \
            movement_params.collider_rotation, \
            edge_calc_params.surface_parser)
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
    
    var movement_params := edge_calc_params.movement_params
    var vertical_step := step_calc_params.vertical_step
    var collider_half_width_height := \
            movement_params.collider_half_width_height
    var surface_parser := edge_calc_params.surface_parser
    var delta_sec := Time.PHYSICS_TIME_STEP_SEC
    var previous_time := horizontal_step.time_step_start
    var current_time := previous_time + delta_sec
    var step_end_time := horizontal_step.time_step_end
    var previous_position := horizontal_step.position_step_start
    var current_position := previous_position
    var current_velocity := horizontal_step.velocity_step_start
    var space_state := edge_calc_params.space_state
    var shape_query_params := edge_calc_params.shape_query_params
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
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE:
#    if Geometry.are_points_equal_with_epsilon( \
#            previous_position, \
#            Vector2(64, -480), 10):
#        print("break")
    
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
        shape_query_params.transform = Transform2D( \
                movement_params.collider_rotation, \
                previous_position)
        shape_query_params.motion = current_position - previous_position
        
        assert(shape_query_params.motion != Vector2.ZERO)
        
        # FIXME: DEBUGGING: REMOVE:
        # if Geometry.are_points_equal_with_epsilon( \
        #         current_position, Vector2(686.626, -228.249), 0.001):
        #     print("yo")
        
        #######################################################################
        if collision_result_metadata != null:
            collision_result_metadata.frame_current_time = current_time
        #######################################################################
        
        # Check for collision.
        collision = FrameCollisionCheckUtils.check_frame_for_collision( \
                space_state, \
                shape_query_params, \
                collider_half_width_height, \
                movement_params.collider_rotation, \
                surface_parser, \
                false, \
                collision_result_metadata)
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
        shape_query_params.transform = Transform2D( \
                movement_params.collider_rotation, \
                previous_position)
        shape_query_params.motion = current_position - previous_position
        assert(shape_query_params.motion != Vector2.ZERO)
        
        collision = FrameCollisionCheckUtils.check_frame_for_collision( \
                space_state, \
                shape_query_params, \
                collider_half_width_height, \
                movement_params.collider_rotation, \
                surface_parser, \
                false, \
                collision_result_metadata)
        
        if collision == null:
            # Record the positions and velocities for edge annotation
            # debugging.
            frame_positions.push_back(current_position)
            frame_velocities.push_back(current_velocity)
    
    var edge_result_metadata := \
            step_result_metadata.edge_result_metadata if \
            step_result_metadata != null else \
            null
    Profiler.stop_with_optional_metadata( \
            ProfilerMetric.CHECK_CONTINUOUS_HORIZONTAL_STEP_FOR_COLLISION, \
            edge_calc_params.collision_params.thread_id, \
            edge_result_metadata)
    
    return collision
