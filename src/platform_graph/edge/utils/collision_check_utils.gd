class_name CollisionCheckUtils
extends Reference


# Checks whether a collision would occur with any surface during the given
# instructions.
# 
# -   This is calculated by stepping through each discrete physics frame, which
#     should exactly emulate the actual SurfacerCharacter trajectory that would
#     be used.
# -   This also records some trajectory state.
static func check_instructions_discrete_trajectory_state(
        edge_calc_params: EdgeCalcParams,
        instructions: EdgeInstructions,
        vertical_step: VerticalEdgeStep,
        horizontal_steps: Array,
        trajectory: EdgeTrajectory) -> SurfaceCollision:
    var collision_params := edge_calc_params.collision_params
    var movement_params := edge_calc_params.movement_params
    var current_instruction_index := -1
    var next_instruction: EdgeInstruction = instructions.instructions[0]
    var delta := Time.PHYSICS_TIME_STEP
    var is_first_jump := true
    var previous_time: float = instructions.instructions[0].time
    var current_time := previous_time + delta
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
    var continuous_position := Vector2.INF
    
    # Record positions for edge annotation debugging.
    var frame_discrete_positions := []
    trajectory.jump_instruction_end = null
    trajectory.horizontal_instructions = []
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < end_time:
        # Update position for this frame, according to the velocity from the
        # previous frame.
        delta = Time.PHYSICS_TIME_STEP
        displacement = velocity * delta
        
        # Iterate through the horizontal steps in order to calculate what the
        # frame positions would be according to our continuous movement
        # calculations.
        while current_horizontal_step.time_step_end < current_time:
            current_horizontal_step_index += 1
            current_horizontal_step = \
                    horizontal_steps[current_horizontal_step_index]
        var continuous_horizontal_state := \
                HorizontalMovementUtils.calculate_horizontal_state_for_time(
                        movement_params,
                        current_horizontal_step,
                        current_time)
        var continuous_vertical_state := VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step(
                        movement_params,
                        vertical_step,
                        current_time)
        continuous_position.x = continuous_horizontal_state[0]
        continuous_position.y = continuous_vertical_state[0]
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            # FIXME: Add back in: To debug why this is failing, try rendering
            #        only the failing path somehow.
#            collision = check_frame_for_collision(
#                    collision_params,
#                    position,
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
        
        # This point corresponds to when SurfacerCharacter._physics_process
        # would be called:
        # - The position for the current frame has been calculated from the
        #   previous frame's velocity.
        # - Any collision state has been calculated.
        # - We can now check whether inputs have changed.
        # - We can now calculate the velocity for the current frame.
        
        while next_instruction != null and \
                next_instruction.time < current_time:
            current_instruction_index += 1
            
            # FIXME:
            # - Think about at what point the velocity change from the step
            #   instruction happens.
            # - Is this at the right time?
            # - Is it too late?
            # - Does it reflect actual playback?
            # - Should initial jump_boost happen sooner?
            
            var instruction_with_position := EdgeInstruction.new(
                    next_instruction.input_key,
                    next_instruction.time,
                    next_instruction.is_pressed,
                    continuous_position)
            
            match next_instruction.input_key:
                "j":
                    is_pressing_jump = next_instruction.is_pressed
                    if is_pressing_jump:
                        velocity.y = movement_params.jump_boost
                    else:
                        # Record the positions of instruction starts and ends.
                        trajectory.jump_instruction_end = \
                                instruction_with_position
                "ml":
                    horizontal_acceleration_sign = \
                            -1 if \
                            next_instruction.is_pressed else \
                            0
                    # Record the positions of instruction starts and ends.
                    trajectory.horizontal_instructions.push_back(
                            instruction_with_position)
                "mr":
                    horizontal_acceleration_sign = \
                            1 if \
                            next_instruction.is_pressed else \
                            0
                    # Record the positions of instruction starts and ends.
                    trajectory.horizontal_instructions.push_back(
                            instruction_with_position)
                "mu", \
                "md", \
                "g", \
                "fl", \
                "fr":
                    pass
                _:
                    Sc.logger.error()
            
            next_instruction = \
                    instructions.instructions \
                            [current_instruction_index + 1] if \
                    current_instruction_index + 1 < \
                            instructions.instructions.size() else \
                    null
        
        # FIXME: Check whether instruction execution also does this, and
        #        whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction set, the current elapsed
#            # time of the instruction set will be less than a full frame. So
#            # we use a delta that represents the actual time the
#            # instruction set should have been running for so far.
#            delta = current_time - instructions.instructions[0].time
        
        # Record the position for edge annotation debugging.
        frame_discrete_positions.push_back(position)
        
        # Update state for the next frame.
        position += displacement
        velocity = MovementUtils.update_velocity_in_air(
                velocity,
                delta,
                is_pressing_jump,
                is_first_jump,
                horizontal_acceleration_sign,
                movement_params)
        velocity = MovementUtils.cap_velocity(
                velocity,
                movement_params,
                movement_params.max_horizontal_speed_default)
        previous_time = current_time
        current_time += delta
    
    # Check the last frame that puts us up to end_time.
    delta = end_time - current_time
    displacement = velocity * delta
    # FIXME: To debug why this is failing, try rendering only the failing path
    #        somehow.
#    collision = check_frame_for_collision(
#            collision_params,
#            position,
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
# horizontal step. This is calculated by considering the continuous physics
# state according to the parabolic equations of motion. This does not
# necessarily accurately reflect the actual SurfacerCharacter trajectory that
# would be used.
static func check_continuous_horizontal_step_for_collision(
        step_result_metadata: EdgeStepCalcResultMetadata,
        edge_calc_params: EdgeCalcParams,
        step_calc_params: EdgeStepCalcParams,
        horizontal_step: EdgeStep) -> SurfaceCollision:
    Sc.profiler.start(
            "check_continuous_horizontal_step_for_collision",
            edge_calc_params.collision_params.thread_id)
    
    var collision_params := edge_calc_params.collision_params
    var movement_params := edge_calc_params.movement_params
    var vertical_step := step_calc_params.vertical_step
    var delta := Time.PHYSICS_TIME_STEP
    var previous_time := horizontal_step.time_step_start
    var current_time := previous_time + delta
    var step_end_time := horizontal_step.time_step_end
    var previous_position := horizontal_step.position_step_start
    var current_position := previous_position
    var current_velocity := horizontal_step.velocity_step_start
    var displacement: Vector2
    var collision: SurfaceCollision
    
    ###########################################################################
    # Record some extra collision state when debugging an edge calculation.
    var collision_result_metadata: CollisionCalcResultMetadata
    if step_result_metadata != null:
        collision_result_metadata = CollisionCalcResultMetadata.new(
                edge_calc_params,
                step_calc_params,
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
        var horizontal_state := \
                HorizontalMovementUtils.calculate_horizontal_state_for_time(
                        movement_params,
                        horizontal_step,
                        current_time)
        var vertical_state := VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step(
                        movement_params,
                        vertical_step,
                        current_time)
        current_position.x = horizontal_state[0]
        current_position.y = vertical_state[0]
        current_velocity.x = horizontal_state[1]
        current_velocity.y = vertical_state[1]
        displacement = current_position - previous_position
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            collision = check_frame_for_collision(
                    collision_params,
                    previous_position,
                    displacement)
            if collision != null:
                break
        
        # Update state for the next frame.
        previous_position = current_position
        previous_time = current_time
        current_time += delta
        
        # Record the positions and velocities for edge annotation debugging.
        frame_positions.push_back(current_position)
        frame_velocities.push_back(current_velocity)
    
    # Check the last frame that puts us up to end_time.
    current_time = step_end_time
    if collision == null and \
            !Sc.geometry.are_floats_equal_with_epsilon(
                    previous_time,
                    current_time):
        var horizontal_state := \
                HorizontalMovementUtils.calculate_horizontal_state_for_time(
                        movement_params,
                        horizontal_step,
                        current_time)
        var vertical_state := VerticalMovementUtils \
                .calculate_vertical_state_for_time_from_step(
                        movement_params,
                        vertical_step,
                        current_time)
        current_position.x = horizontal_state[0]
        current_position.y = vertical_state[0]
        current_velocity.x = horizontal_state[1]
        current_velocity.y = vertical_state[1]
        displacement = current_position - previous_position
        
        # In very rare cases, displacement can be zero when previous_time is
        # very close to current_time.
        if displacement != Vector2.ZERO:
            collision = check_frame_for_collision(
                    collision_params,
                    previous_position,
                    displacement)
            
            if collision == null:
                # Record the positions and velocities for edge annotation
                # debugging.
                frame_positions.push_back(current_position)
                frame_velocities.push_back(current_velocity)
    
    # Include a frame for the final position and velocity at the moment of
    # collision.
    # **NOTE**: This frame corresponds to a shorter duration than all the other
    #           frames.
    if collision != null:
        frame_positions.push_back(collision.character_position)
        frame_velocities.push_back(current_velocity)
    
    if collision != null and \
            collision_result_metadata != null:
        # Record some extra state from before/after/during collision for
        # debugging.
        collision_result_metadata.record_collision(
                previous_position,
                displacement,
                collision)
    
    var edge_result_metadata := \
            step_result_metadata.edge_result_metadata if \
            step_result_metadata != null else \
            null
    Sc.profiler.stop_with_optional_metadata(
            "check_continuous_horizontal_step_for_collision",
            edge_calc_params.collision_params.thread_id,
            edge_result_metadata)
    
    return collision


# Determines whether the given motion of the given shape would collide with a
# surface.
# 
# -   This often generates false-negatives if the character is moving away from
#     a surface that they were already colliding with beforehand.
# -   If a collision would occur, this returns information about the collision.
static func check_frame_for_collision(
        collision_params: CollisionCalcParams,
        position_start: Vector2,
        displacement: Vector2,
        is_recursing := false) -> SurfaceCollision:
    var crash_test_dummy: KinematicBody2D = collision_params.crash_test_dummy
    
    crash_test_dummy.position = position_start
    var kinematic_collision := crash_test_dummy.move_and_collide(
            displacement,
            true,
            true,
            true)
    
    if kinematic_collision == null:
        # No collision found for this frame.
        return null
    
    var surface_collision := SurfaceCollision.new()
    surface_collision.position = kinematic_collision.position
    surface_collision.character_position = \
            position_start + kinematic_collision.travel
    surface_collision.time_from_start_of_frame = \
            (kinematic_collision.travel.y / displacement.y if \
            abs(displacement.y) > abs(displacement.x) else \
            kinematic_collision.travel.x / displacement.x) * \
            Time.PHYSICS_TIME_STEP
    if surface_collision.time_from_start_of_frame < 0.0:
        # -   This happens frequently.
        # -   It's unclear why Godot's collision engine produces negative
        #     results here.
        # -   Presumably, this implies that there was a pre-existing collision.
        # -   But if that were the case, the collision should have been
        #     detected in the previous frame.
        surface_collision.time_from_start_of_frame = 0.0
    
    var tile_map: SurfacesTileMap = kinematic_collision.collider
    var surface_side: int = \
            Sc.geometry.get_surface_side_for_normal(kinematic_collision.normal)
    var tile_map_result := CollisionSurfaceResult.new()
    
    # Is this collision with a surface that we're actually moving away from?
    var is_moving_away_from_surface: bool
    match surface_side:
        SurfaceSide.FLOOR:
            is_moving_away_from_surface = displacement.y < 0.0
        SurfaceSide.LEFT_WALL:
            is_moving_away_from_surface = displacement.x > 0.0
        SurfaceSide.RIGHT_WALL:
            is_moving_away_from_surface = displacement.x < 0.0
        SurfaceSide.CEILING:
            is_moving_away_from_surface = displacement.y > 0.0
        _:
            Sc.logger.error()
    
    # Are we likely to be looking at the wrong intersection point, according to
    # how oblique movement is relative to the surface tangent?
    var collision_normal := kinematic_collision.normal
    var displacement_aspect_ratio := \
            abs(displacement.x / displacement.y) if \
            displacement.y != 0.0 else \
            INF
    var collision_normal_aspect_ratio := \
            abs(collision_normal.x / collision_normal.y) if \
            collision_normal.y != 0.0 else \
            INF
    var threshold: float = crash_test_dummy.movement_params \
            .oblique_collison_normal_aspect_ratio_threshold_threshold
    var inverse_threshold := 1.0 / threshold
    var is_collision_normal_expected: bool = \
            !crash_test_dummy.movement_params \
            .checks_for_alt_intersection_points_for_oblique_collisions or \
            !(displacement_aspect_ratio > threshold and \
            collision_normal_aspect_ratio < inverse_threshold or \
            displacement_aspect_ratio < inverse_threshold and \
            collision_normal_aspect_ratio > threshold)
    
    if !is_moving_away_from_surface and \
            !is_collision_normal_expected:
        # Consider an alternate intersection point that might correspond to an
        # adjacent surface around a corner, and a less oblique collision.
        
        var space_rid := crash_test_dummy.get_world_2d().space
        var params := Physics2DShapeQueryParameters.new()
        
        params.set_shape(crash_test_dummy.movement_params.collider.shape)
        params.transform = Transform2D(
                crash_test_dummy.movement_params.collider.rotation,
                position_start)
        params.motion = displacement
        params.margin = crash_test_dummy.movement_params \
                .collision_margin_for_edge_calculations
        
        var intersection_points: Array = Su.space_state.collide_shape(params)
        
        if !intersection_points.empty():
            # Choose the intersection point that most likely corresponds to a
            # non-oblique collision.
            var expected_surface_side_for_displacement := SurfaceSide.NONE
            var most_likely_collision_point: Vector2
            if displacement_aspect_ratio > threshold and \
                    collision_normal_aspect_ratio < inverse_threshold:
                # Moving horizontally, but collided vertically.
                expected_surface_side_for_displacement = \
                        SurfaceSide.LEFT_WALL if \
                        displacement.x < 0.0 else \
                        SurfaceSide.RIGHT_WALL
                most_likely_collision_point = intersection_points[0]
                for i in range(1, intersection_points.size()):
                    var current_point: Vector2 = intersection_points[i]
                    if collision_normal.y < 0:
                        if current_point.y > most_likely_collision_point.y:
                            most_likely_collision_point = current_point
                    else:
                        if current_point.y < most_likely_collision_point.y:
                            most_likely_collision_point = current_point
            elif displacement_aspect_ratio < inverse_threshold and \
                    collision_normal_aspect_ratio > threshold:
                # Moving vertically, but collided horizontally.
                expected_surface_side_for_displacement = \
                        SurfaceSide.CEILING if \
                        displacement.y < 0.0 else \
                        SurfaceSide.FLOOR
                most_likely_collision_point = intersection_points[0]
                for i in range(1, intersection_points.size()):
                    var current_point: Vector2 = intersection_points[i]
                    if collision_normal.x < 0:
                        if current_point.x > most_likely_collision_point.x:
                            most_likely_collision_point = current_point
                    else:
                        if current_point.x < most_likely_collision_point.x:
                            most_likely_collision_point = current_point
            
            if expected_surface_side_for_displacement != SurfaceSide.NONE:
                SurfaceFinder.calculate_collision_surface(
                        tile_map_result,
                        collision_params.surface_store,
                        most_likely_collision_point,
                        expected_surface_side_for_displacement,
                        tile_map,
                        false,
                        true)
    
    if tile_map_result.surface == null:
        # Consider the default collision point returned from move_and_collide.
        tile_map_result.reset()
        SurfaceFinder.calculate_collision_surface(
                tile_map_result,
                collision_params.surface_store,
                kinematic_collision.position,
                kinematic_collision.normal,
                tile_map,
                true,
                false)
    
    if tile_map_result.surface == null:
        # Invalid collision state.
        if collision_params.movement_params \
                .asserts_no_preexisting_collisions_during_edge_calculations:
            Sc.logger.error()
        surface_collision.is_valid_collision_state = false
        return null
    
    var surface := tile_map_result.surface
    surface_side = tile_map_result.surface_side
    
    surface_collision.surface = surface
    surface_collision.is_valid_collision_state = true
    
    # Is this collision with a surface that we're actually moving away from.
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
            Sc.logger.error()
    
    if is_moving_away_from_surface:
        # The character is moving away from the collision point.
        # This means one of two things:
        # -   There was a pre-existing collision (happens infrequently).
        # -   The extra "safe_margin" used in calculating the collision extends
        #     into a surface the character is departing, even though the
        #     character wasn't directly colliding with the surface (happens
        #     frequently).
        
        if is_recursing:
            # Invalid collision state: Happens infrequently.
            if collision_params.movement_params \
                    .asserts_no_preexisting_collisions_during_edge_calculations:
                Sc.logger.error()
            surface_collision.is_valid_collision_state = false
            return null
        
        var surface_normal: Vector2
        match surface_side:
            SurfaceSide.FLOOR:
                surface_normal = Vector2.UP
            SurfaceSide.LEFT_WALL:
                surface_normal = Vector2.RIGHT
            SurfaceSide.RIGHT_WALL:
                surface_normal = Vector2.LEFT
            SurfaceSide.CEILING:
                surface_normal = Vector2.DOWN
            _:
                Sc.logger.error()
        
        # Try the collision check again with a reduced margin and a slight
        # offset.
        var old_margin := crash_test_dummy.get_safe_margin()
        crash_test_dummy.set_safe_margin(0.0)
        position_start += surface_normal * 0.001
        surface_collision = check_frame_for_collision(
                collision_params,
                position_start,
                displacement,
                true)
        crash_test_dummy.set_safe_margin(old_margin)
    
    return surface_collision
