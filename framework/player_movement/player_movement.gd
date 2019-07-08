# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const MovementConstraint = preload("res://framework/player_movement/movement_constraint.gd")
const PlayerInstruction = preload("res://framework/player_movement/player_instruction.gd")

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD := 512.0
const DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING := 10000.0
const VERTEX_SIDE_NUDGE_OFFSET := 0.001

var JUMP_RELEASE_INSTRUCTION = PlayerInstruction.new("jump", -1, false)

var name: String
var params: MovementParams
var surfaces: Array
var surface_parser: SurfaceParser

var can_traverse_edge := false
var can_traverse_to_air := false
var can_traverse_from_air := false

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func set_surfaces(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            params.can_grab_walls, params.can_grab_ceilings, params.can_grab_floors)

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, surface: Surface) -> Array:
    Utils.error( \
            "Abstract PlayerMovement.get_all_edges_from_surface is not implemented")
    return []

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, start: PositionAlongSurface, \
        end: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_to_air is not implemented")
    return null

func get_all_reachable_surface_instructions_from_air(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: PositionAlongSurface, start_velocity: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []

static func update_velocity_in_air( \
        velocity: Vector2, delta: float, is_pressing_jump: bool, is_first_jump: bool, \
        horizontal_movement_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.slow_ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity_fast_fall * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += delta * movement_params.in_air_horizontal_acceleration * horizontal_movement_sign
    
    return velocity

static func cap_velocity(velocity: Vector2, movement_params: MovementParams) -> Vector2:
    # Cap horizontal speed at a max value.
    velocity.x = clamp(velocity.x, -movement_params.current_max_horizontal_speed, \
            movement_params.current_max_horizontal_speed)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -movement_params.min_horizontal_speed and \
            velocity.x < movement_params.min_horizontal_speed:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(velocity.y, -movement_params.max_vertical_speed, \
            movement_params.max_vertical_speed)
    
    # Kill vertical speed below a min value.
    if velocity.y > -movement_params.min_vertical_speed and \
            velocity.y < movement_params.min_vertical_speed:
        velocity.y = 0
    
    return velocity

# Checks whether a collision would occur with any surface during the given instructions. This
# is calculated by stepping through each discrete physics frame, which should exactly emulate the
# actual Player trajectory that would be used.
static func _check_instructions_for_collision(global_calc_params: MovementCalcGlobalParams, \
        instructions: PlayerInstructions, vertical_step: MovementCalcStep, \
        horizontal_steps: Array) -> SurfaceCollision:
    var movement_params := global_calc_params.movement_params
    var current_instruction_index := -1
    var next_instruction: PlayerInstruction = instructions.instructions[0]
    var delta := Utils.PHYSICS_TIME_STEP
    var is_first_jump := true
    # On average, an instruction set will start halfway through a physics frame, so let's use that
    # average here.
    var previous_time: float = instructions.instructions[0].time - delta / 2
    var current_time := previous_time + delta
    var duration := instructions.duration
    var is_pressing_left := false
    var is_pressing_right := false
    var is_pressing_jump := false
    var horizontal_movement_sign := 0
    var position := global_calc_params.position_start
    var velocity := Vector2.ZERO
    var has_started_instructions := false
    var space_state := global_calc_params.space_state
    var shape_query_params := global_calc_params.shape_query_params
    var displacement: Vector2
    var collision: SurfaceCollision
    
    var current_horizontal_step_index := 0
    var current_horizontal_step: MovementCalcStep = horizontal_steps[0]
    var continuous_horizontal_state: Vector2
    var continuous_vertical_state: Vector2
    var continuous_position: Vector2
    
    # Record the position for edge annotation debugging.
    var frame_discrete_positions := []
    var frame_continuous_positions := [position]
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < duration:
        # Update position for this frame, according to the velocity from the previous frame.
        delta = Utils.PHYSICS_TIME_STEP
        displacement = velocity * delta
        shape_query_params.transform = Transform2D(0.0, position)
        shape_query_params.motion = displacement
        
        # Iterate through the horizontal steps in order to calculate what the frame positions would
        # be according to our continuous movement calculations.
        while current_horizontal_step.time_step_end < current_time:
            current_horizontal_step_index += 1
            current_horizontal_step = horizontal_steps[current_horizontal_step_index]
        continuous_horizontal_state = _update_horizontal_end_state_for_time( \
                movement_params, current_horizontal_step, current_time)
        continuous_vertical_state = _update_vertical_end_state_for_time( \
                movement_params, vertical_step, current_time)
        continuous_position.x = continuous_horizontal_state.x
        continuous_position.y = continuous_vertical_state.x
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
            # - To debug why this is failing, try rendering only the failing path somehow.
#            collision = check_frame_for_collision(space_state, shape_query_params, \
#                    movement_params.collider_half_width_height, global_calc_params.surface_parser)
            if collision != null:
                instructions.frame_discrete_positions = PoolVector2Array(frame_discrete_positions)
                instructions.frame_continuous_positions = PoolVector2Array(frame_continuous_positions)
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
        
        while next_instruction != null and next_instruction.time < current_time:
            current_instruction_index += 1
            
            # FIXME: --A:
            # - Think about at what point the velocity change from the step instruction happens.
            # - Is this at the right time?
            # - Is it too late?
            # - Does it reflect actual playback?
            # - Should initial jump_boost happen sooner?
            
            match next_instruction.input_key:
                "jump":
                    is_pressing_jump = next_instruction.is_pressed
                    if is_pressing_jump:
                        velocity.y = movement_params.jump_boost
                "move_left":
                    is_pressing_left = next_instruction.is_pressed
                    horizontal_movement_sign = -1 if is_pressing_left else 0
                "move_right":
                    is_pressing_right = next_instruction.is_pressed
                    horizontal_movement_sign = 1 if is_pressing_right else 0
                _:
                    Utils.error()
            
            next_instruction = instructions.instructions[current_instruction_index + 1] if \
                    current_instruction_index + 1 < instructions.instructions.size() else null
        
        # FIXME: E: After implementing instruction execution, check whether it also does this, and
        #           whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction set, the current elapsed time of the
#            # instruction set will be less than a full frame. So we use a delta that represents the
#            # actual time the instruction set should have been running for so far.
#            delta = current_time - instructions.instructions[0].time
        
        # Record the position for edge annotation debugging.
        frame_discrete_positions.push_back(position)
        
        # Update state for the next frame.
        position += displacement
        velocity = update_velocity_in_air(velocity, delta, is_pressing_jump, is_first_jump, \
                horizontal_movement_sign, movement_params)
        velocity = cap_velocity(velocity, movement_params)
        previous_time = current_time
        current_time += delta
        
        # Record the position for edge annotation debugging.
        frame_continuous_positions.push_back(continuous_position)
    
    # Check the last frame that puts us up to end_time.
    delta = duration - current_time
    displacement = velocity * delta
    shape_query_params.transform = Transform2D(0.0, position)
    shape_query_params.motion = displacement
    continuous_horizontal_state = _update_horizontal_end_state_for_time( \
            movement_params, current_horizontal_step, duration)
    continuous_vertical_state = _update_vertical_end_state_for_time( \
            movement_params, vertical_step, duration)
    continuous_position.x = continuous_horizontal_state.x
    continuous_position.y = continuous_vertical_state.x
    # FIXME: LEFT OFF HERE: DEBUGGING: Add back in:
    # - To debug why this is failing, try rendering only the failing path somehow.
#    collision = check_frame_for_collision(space_state, shape_query_params, \
#            movement_params.collider_half_width_height, global_calc_params.surface_parser)
    if collision != null:
        instructions.frame_discrete_positions = PoolVector2Array(frame_discrete_positions)
        instructions.frame_continuous_positions = PoolVector2Array(frame_continuous_positions)
        return collision
    
    # Record the position for edge annotation debugging.
    frame_discrete_positions.push_back(position + displacement)
    frame_continuous_positions.push_back(continuous_position)
    instructions.frame_discrete_positions = PoolVector2Array(frame_discrete_positions)
    instructions.frame_continuous_positions = PoolVector2Array(frame_continuous_positions)
    
    return null

# Checks whether a collision would occur with any surface during the given horizontal step. This
# is calculated by stepping through each physics frame, which should exactly emulate the actual
# Player trajectory that would be used. The main error with this approach is that successive steps
# will be tested with their start time perfectly aligned to a physics frame boundary, but when
# executing a resulting instruction set, the physics frame boundaries will line up at different
# times.
static func _check_discrete_horizontal_step_for_collision( \
        global_calc_params: MovementCalcGlobalParams, local_calc_params: MovementCalcLocalParams, \
        horizontal_step: MovementCalcStep) -> SurfaceCollision:
    var movement_params := global_calc_params.movement_params
    var delta := Utils.PHYSICS_TIME_STEP
    var is_first_jump := true
    # On average, an instruction set will start halfway through a physics frame, so let's use that
    # average here.
    var previous_time := horizontal_step.time_start - delta / 2
    var current_time := previous_time + delta
    var step_end_time := horizontal_step.time_step_end
    var horizontal_instruction_end_time := horizontal_step.time_instruction_end
    var position := horizontal_step.position_start
    var velocity := horizontal_step.velocity_start
    var has_started_instructions := false
    var jump_instruction_end_time := local_calc_params.vertical_step.time_instruction_end
    var is_pressing_jump := jump_instruction_end_time > current_time
    var is_pressing_move_horizontal := horizontal_instruction_end_time > current_time
    var horizontal_movement_sign := 0
    var space_state := global_calc_params.space_state
    var shape_query_params := global_calc_params.shape_query_params
    var displacement: Vector2
    var collision: SurfaceCollision
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update state for the current frame.
        delta = Utils.PHYSICS_TIME_STEP
        displacement = velocity * delta
        shape_query_params.transform = Transform2D(0.0, position)
        shape_query_params.motion = displacement
        
        if displacement != Vector2.ZERO:
            # Check for collision.
            collision = check_frame_for_collision(space_state, shape_query_params, \
                    movement_params.collider_half_width_height, global_calc_params.surface_parser)
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
        is_pressing_move_horizontal = horizontal_instruction_end_time > current_time
        horizontal_movement_sign = \
                horizontal_step.horizontal_movement_sign if is_pressing_move_horizontal else 0
        
        # FIXME: E: After implementing instruction execution, check whether it also does this, and
        #           whether this should be uncommented.
#        if !has_started_instructions:
#            has_started_instructions = true
#            # When we start executing the instruction, the current elapsed time of the instruction
#            # will be less than a full frame. So we use a delta that represents the actual time the
#            # instruction should have been running for so far.
#            delta = current_time - horizontal_step.time_start
        
        # Update state for the next frame.
        position += displacement
        velocity = update_velocity_in_air(velocity, delta, is_pressing_jump, is_first_jump, \
                horizontal_movement_sign, movement_params)
        velocity = cap_velocity(velocity, movement_params)
        previous_time = current_time
        current_time += delta
    
    # Check the last frame that puts us up to end_time.
    delta = step_end_time - current_time
    displacement = velocity * delta
    shape_query_params.transform = Transform2D(0.0, position)
    shape_query_params.motion = displacement
    collision = check_frame_for_collision(space_state, shape_query_params, \
            movement_params.collider_half_width_height, global_calc_params.surface_parser)
    if collision != null:
        return collision
    
    return null

# Checks whether a collision would occur with any surface during the given horizontal step. This
# is calculated by considering the continuous physics state according to the parabolic equations of
# motion. This does not necessarily accurately reflect the actual Player trajectory that would be
# used.
static func _check_continuous_horizontal_step_for_collision( \
        global_calc_params: MovementCalcGlobalParams, local_calc_params: MovementCalcLocalParams, \
        horizontal_step: MovementCalcStep) -> SurfaceCollision:
    var movement_params := global_calc_params.movement_params
    var vertical_step := local_calc_params.vertical_step
    var collider_half_width_height := movement_params.collider_half_width_height
    var surface_parser := global_calc_params.surface_parser
    var delta := Utils.PHYSICS_TIME_STEP
    var previous_time := horizontal_step.time_start
    var current_time := previous_time + delta
    var step_end_time := horizontal_step.time_step_end
    var previous_position := horizontal_step.position_start
    var current_position := previous_position
    var space_state := global_calc_params.space_state
    var shape_query_params := global_calc_params.shape_query_params
    var horizontal_state: Vector2
    var vertical_state: Vector2
    var collision: SurfaceCollision
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update state for the current frame.
        horizontal_state = _update_horizontal_end_state_for_time( \
                movement_params, horizontal_step, current_time)
        vertical_state = _update_vertical_end_state_for_time( \
                movement_params, vertical_step, current_time)
        current_position.x = horizontal_state.x
        current_position.y = vertical_state.x
        shape_query_params.transform = Transform2D(0.0, previous_position)
        shape_query_params.motion = current_position - previous_position
        
        assert(shape_query_params.motion != Vector2.ZERO)
        
        # Check for collision.
        collision = check_frame_for_collision(space_state, shape_query_params, \
                collider_half_width_height, surface_parser)
        if collision != null:
            return collision
        
        # Update state for the next frame.
        previous_position = current_position
        previous_time = current_time
        current_time += delta
    
    # Check the last frame that puts us up to end_time.
    current_time = step_end_time
    if !Geometry.are_floats_equal_with_epsilon(previous_time, current_time):
        horizontal_state = _update_horizontal_end_state_for_time( \
                movement_params, horizontal_step, current_time)
        vertical_state = _update_vertical_end_state_for_time( \
                movement_params, vertical_step, current_time)
        current_position.x = horizontal_state.x
        current_position.y = vertical_state.x
        shape_query_params.transform = Transform2D(0.0, previous_position)
        shape_query_params.motion = current_position - previous_position
        assert(shape_query_params.motion != Vector2.ZERO)
        collision = check_frame_for_collision(space_state, shape_query_params, \
                collider_half_width_height, surface_parser)
        if collision != null:
            return collision
    
    return null

# Determines whether the given motion of the given shape would collide with a surface. If a
# collision would occur, this returns the surface; otherwise, this returns null.
static func check_frame_for_collision(space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters, collider_half_width_height: Vector2, \
        surface_parser: SurfaceParser, has_recursed := false) -> SurfaceCollision:
    # FIXME: B: Check whether all of the level setup must be called from within an early
    #   _physics_process callback (space might have a lock otherwise)?
    
    # FIXME: F:
    # - Move these diagrams out of ASCII and into InkScape.
    # - Include in markdown explanation docs.
    # - Reference markdown from relevant points in this function.
    # - Go through other interesting functions/edge-cases and create diagrams for them too.
    
    # ## How Physics2DDirectSpaceState.collide_shape works
    # 
    # If we have the two shapes below colliding, then the `o` characters below are the positions
    # that collide_shape will return:
    # 
    #                  +-------------------+
    #                  |                   |
    #                  |              o----o----+
    #                  |              |    |    | <-----
    #                  |              |    |    |
    #                  |              |    |    | <-----
    #                  |              o----o----+
    #                  |                   |
    #                  +-------------------+
    # 
    #                  +-------------------+
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |              o----o----+
    #                  |              |    |    | <-----
    #                  +--------------o----o    |
    #                                 |         | <-----
    #                                 +---------+
    # 
    # However, collide_shapes returns incorrect results with tunnelling:
    # 
    #              o-------------------o
    #              |                   |
    # +---------+  |                   |
    # |         | <----------------------------------
    # |         |  |                   |
    # |         | <----------------------------------
    # +---------+  o                   o <== Best option
    #              |                   |
    #              +-------------------+
    #
    # Our collision calculations still work even with the incorrect results from collide_shapes.
    # We always choose the one point of intersection that is valid.
    
    # ## Handing pre-existing collisions.
    # 
    # - These _should_ only happen due to increased margins around the actual Player shape, and at
    #   the start of the movement; otherwise, they should have been handled in a previous frame.
    # - We can ignore surfaces that we are moving away from, since we can assume that these aren't
    #   valid collisions.
    # - The valid collision points that we need to consider are any points that are in both the
    #   same x and y direction as movement from any corner of the Player's _actual_ shape (not
    #   considering the margin). The diagrams below illustrate this:
    # 
    # (Only the top three points are valid)
    #                                          `
    #                                  ..............
    #                                  .       `    .
    #                                  .    +--+    .
    #                  +-----------o---o---o|  |    .
    #            `   ` | `   `   `   ` . ` |+--+    .
    #                  |               .   |        .  __
    #                  |               o...o......... |\
    #                  |                   |   __       \
    #                  |                   |  |\         \
    #                  |                   |    \
    #                  |                   |     \
    #                  +-------------------+
    # 
    # (None of the points are valid)
    #                                       `
    #                  +-----------------o-o`
    #                  |               o...o.........
    #                  |           __  .   |`       .
    #                  |            /| .   |+--+    .
    #                  |           /   .   ||  |    .
    #                  |          /    .   |+--+  ` . `   `   `   `
    #                  |               .   |        .
    #                  |               o...o.........
    #                  +-------------------+  __
    #                                          /|
    #                                         /
    #                                        /
    
    # ## Choose the right side when colliding with a corner.
    # 
    # `space_state.intersect_ray` could return a normal from either side of an intersected corner.
    # However, only one side is correct. The correct side is determined by which dimension
    # intersected first. The following diagram helps illustrate this.
    #
    # Before collision: 
    #                  +-------------------+
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  +-------------------+
    #                                          +---------+
    #                                          |         |
    #                                          |         |
    #                                          |         |  __
    #                                          +---------+ |\
    #                                              __        \
    #                                             |\          \
    #                                               \
    #                                                \
    # 
    # After the shapes intersect along one dimension, but before they intersect along the other:
    #     (In this example, the shapes intersect along the y axis, and the correct side for the
    #     collision is the right side of the larger shape.)
    #                  +-------------------+
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |+---------+
    #                  +-------------------+|         |
    #                                       |         |
    #                                       |         |  __
    #                                       +---------+ |\
    #                                           __        \
    #                                          |\          \
    #                                            \
    #                                             \
    # 
    # After the shapes intersect along both dimensions.
    #                  +-------------------+
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                   |
    #                  |                 o-o-------+
    #                  |                 | |       |
    #                  |                 | |       |
    #                  +-----------------o-o       |  __
    #                                    +---------+ |\
    #                                        __        \
    #                                       |\          \
    #                                         \
    #                                          \
    
    var intersection_points := space_state.collide_shape(shape_query_params, 32)
    assert(intersection_points.size() < 32)
    if intersection_points.empty():
        return null
    
    var direction := shape_query_params.motion.normalized()
    var position_start := shape_query_params.transform.origin
    var x_min_start := position_start.x - collider_half_width_height.x
    var x_max_start := position_start.x + collider_half_width_height.x
    var y_min_start := position_start.y - collider_half_width_height.y
    var y_max_start := position_start.y + collider_half_width_height.y
    
    var current_projection_onto_motion: float
    var closest_projection_onto_motion: float = INF
    var current_intersection_point: Vector2
    var closest_intersection_point := Vector2.INF
    var other_closest_intersection_point := Vector2.INF
    
    # Use Physics2DDirectSpaceState.intersect_ray to get a bit more info about the collision--
    # specifically, the normal and the collider.
    var collision := {}
    
    var side := SurfaceSide.NONE
    var is_touching_floor := false
    var is_touching_ceiling := false
    var is_touching_left_wall := false
    var is_touching_right_wall := false
    # For nudging the ray-tracing a little so that it hits the correct side of the collider vertex.
    var perpendicular_offset: Vector2
    var should_try_without_perpendicular_nudge_first: bool
    
    var ray_trace_target: Vector2
    
    # FIXME: B: Update tests to provide bounding box; add new test for this "corner" case
    
    # FIXME: E:
    # - Problem: Single-point surfaces will fail here (empty collision Dictionary result).
    # - Solution:
    #   - Not sure.
    #   - Might be able to use another space_state method?
    #   - Or, might be able to estimate parameters from other sources:
    #     - Normal according to the direction of motion?
    #     - Position from closest_intersection_point
    #     - Collider from ...
    
    # FIXME: LEFT OFF HERE: DEBUGGING: Remove
    if true:
#    if intersection_points.size() == 2:
#        # `collide_shape` _seems_ to only return two points when we are clipping a corner on our
#        # way past. And it _seems_ as though the two points in these cases are always the corners
#        # of the tile and the Player at this frame time. If those two assumptions are correct, then
#        # we can use the midpoint between these two positions as the target for ray-casting, and
#        # that should get us the correct surface and normal.
#
#        ray_trace_target = \
#                intersection_points[0].linear_interpolate(intersection_points[1], 0.5)
#
#        perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
#        should_try_without_perpendicular_nudge_first = true
#    else:
        # Choose whichever point comes first, along the direction of the motion. If two points are
        # equally close, then choose whichever point is closest to the starting position.
        
        for i in intersection_points.size():
            current_intersection_point = intersection_points[i]
            
            # Ignore any points that we aren't moving toward. Those indicate pre-existing collisions,
            # which should only exist from the collision margin intersecting nearby surfaces at the
            # start of the Player's movement.
            if direction.x <= 0 and current_intersection_point.x >= x_max_start or \
                    direction.x >= 0 and current_intersection_point.x <= x_min_start or \
                    direction.y <= 0 and current_intersection_point.y >= y_max_start or \
                    direction.y >= 0 and current_intersection_point.y <= y_min_start:
                continue
            
            current_projection_onto_motion = direction.dot(current_intersection_point)
            
            if Geometry.are_floats_equal_with_epsilon(current_projection_onto_motion, \
                    closest_projection_onto_motion):
                # Two points are equally close, so record this so we can compare them afterward.
                other_closest_intersection_point = current_intersection_point
            elif current_projection_onto_motion < closest_projection_onto_motion:
                # We have a new closest point.
                closest_intersection_point = current_intersection_point
                closest_projection_onto_motion = current_projection_onto_motion
                other_closest_intersection_point = Vector2.INF
        
        if closest_intersection_point == Vector2.INF:
            # We are moving away from all of the intersection points, so we can assume that there are
            # no new collisions this frame.
            return null
        
        if other_closest_intersection_point != Vector2.INF:
            # Two points of intersection were equally close against the direction of motion, so choose
            # whichever point is closest to the starting position.
            var distance_a := closest_intersection_point.distance_squared_to(position_start)
            var distance_b := other_closest_intersection_point.distance_squared_to(position_start)
            closest_intersection_point = closest_intersection_point if distance_a < distance_b else \
                    other_closest_intersection_point
        
        ray_trace_target = closest_intersection_point
                    
        if direction.x == 0 or direction.y == 0:
            # Moving straight sideways or up-down.
    
            if direction.x == 0:
                if direction.y > 0:
                    side = SurfaceSide.FLOOR
                    is_touching_floor = true
                else: # direction.y < 0
                    side = SurfaceSide.CEILING
                    is_touching_ceiling = true
            elif direction.y == 0:
                if direction.x > 0:
                    side = SurfaceSide.RIGHT_WALL
                    is_touching_right_wall = true
                else: # direction.x < 0
                    side = SurfaceSide.LEFT_WALL
                    is_touching_left_wall = true
            
            perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
            should_try_without_perpendicular_nudge_first = true
        else:
            # Moving at an angle.
            
            var collision_ratios := space_state.cast_motion(shape_query_params)
            
            var position_just_before_collision: Vector2
            if collision_ratios.size() == 2:
                # An array of size 2 means that there was no pre-existing collision.
                
                # A value of 1 means that no collision was detected.
                assert(collision_ratios[0] < 1.0)
                
                position_just_before_collision = \
                        position_start + shape_query_params.motion * collision_ratios[0]
            else: # collision_ratios.size() == 0
                # An empty array means that we were already colliding even before any motion.
                # 
                # - We can assume that this collision actually involves the margin colliding and not
                #   the actual shape.
                # - We can assume that the closest_intersection_point is a point along the outside of a
                #   non-occluded surface, and that this surface is the closest in the direction of
                #   travel.
                
                assert(!has_recursed)
                
                var original_margin := shape_query_params.margin
                var original_motion := shape_query_params.motion
                
                # Remove margin, so we can determine which side the shape would actually collide
                # against.
                shape_query_params.margin = 0.0
                # Increase the motion, since we can't be sure the shape would otherwise collide without
                # the margin.
                shape_query_params.motion = direction * original_margin * 4
                # When the Player's shape rests against another collidable, that can be interpreted as
                # a collision, so we add a slight offset here.
                shape_query_params.transform = \
                        shape_query_params.transform.translated(-direction * 0.01)
                
                var result := check_frame_for_collision(space_state, shape_query_params, \
                        collider_half_width_height, surface_parser, true)
                
                shape_query_params.margin = original_margin
                shape_query_params.motion = original_motion
                shape_query_params.transform = Transform2D(0.0, position_start)
                
                return result
                
            var x_min_just_before_collision := \
                    position_just_before_collision.x - collider_half_width_height.x
            var x_max_just_before_collision := \
                    position_just_before_collision.x + collider_half_width_height.x
            var y_min_just_before_collision := \
                    position_just_before_collision.y - collider_half_width_height.y
            var y_max_just_before_collision := \
                    position_just_before_collision.y + collider_half_width_height.y
            
            var intersects_along_x := x_min_just_before_collision <= closest_intersection_point.x and \
                    x_max_just_before_collision >= closest_intersection_point.x
            var intersects_along_y := y_min_just_before_collision <= closest_intersection_point.y and \
                    y_max_just_before_collision >= closest_intersection_point.y
            
            if !intersects_along_x and !intersects_along_y:
                # Neither dimension intersects just before collision. This usually just means that
                # `cast_motion` is using too large of a time step.
                # 
                # Here is our workaround:
                # - Pick the closest corner of the non-margin shape. Project a line from it along the 
                #   motion direction.
                # - Determine which side of the line closest_intersection_point lies on.
                # - Choose a target point that is nudged from closest_intersection_point slightly
                #   toward the line.
                # - Use `intersect_ray` to cast a line into this nudged point and get the normal.
                
                var closest_corner_x := \
                        x_max_just_before_collision if direction.x > 0 else x_min_just_before_collision
                var closest_corner_y := \
                        y_max_just_before_collision if direction.y > 0 else y_min_just_before_collision
                var closest_corner := Vector2(closest_corner_x, closest_corner_y)
                var projected_corner := closest_corner + direction
                perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
                var perdendicular_point := closest_corner + perpendicular_offset
                
                var closest_point_side_of_ray := \
                        (projected_corner.x - closest_corner.x) * \
                        (closest_intersection_point.y - closest_corner.y) - \
                        (projected_corner.y - closest_corner.y) * \
                        (closest_intersection_point.x - closest_corner.x)
                var perpendicular_offset_side_of_ray := \
                        (projected_corner.x - closest_corner.x) * \
                        (perdendicular_point.y - closest_corner.y) - \
                        (projected_corner.y - closest_corner.y) * \
                        (perdendicular_point.x - closest_corner.x)
                
                perpendicular_offset = -perpendicular_offset if \
                        (closest_point_side_of_ray > 0) == \
                                (perpendicular_offset_side_of_ray > 0) else \
                        perpendicular_offset
                should_try_without_perpendicular_nudge_first = false
                
            if !intersects_along_x or !intersects_along_y:
                # If only one dimension intersects just before collision, then we use that to determine
                # which side we're colliding with.
                
                if intersects_along_x:
                    if direction.y > 0:
                        side = SurfaceSide.FLOOR
                        is_touching_floor = true
                    else: # direction.y < 0
                        side = SurfaceSide.CEILING
                        is_touching_ceiling = true
                    
                    if direction.x > 0:
                        perpendicular_offset = Vector2(VERTEX_SIDE_NUDGE_OFFSET, 0.0)
                    else: # direction.x < 0
                        perpendicular_offset = Vector2(-VERTEX_SIDE_NUDGE_OFFSET, 0.0)
                else: # intersects_along_y
                    if direction.x > 0:
                        side = SurfaceSide.RIGHT_WALL
                        is_touching_right_wall = true
                    else: # direction.x < 0
                        side = SurfaceSide.LEFT_WALL
                        is_touching_left_wall = true
                    
                    if direction.y > 0:
                        perpendicular_offset = Vector2(0.0, VERTEX_SIDE_NUDGE_OFFSET)
                    else: # direction.y < 0
                        perpendicular_offset = Vector2(0.0, -VERTEX_SIDE_NUDGE_OFFSET)
                
                should_try_without_perpendicular_nudge_first = false
            else:
                # If both dimensions intersect just before collision, then we use the direction of
                # motion to determine which side we're colliding with.
                # This can happen with Player shapes that don't just consist of axially-aligned edges.
                
                if abs(direction.angle_to(Geometry.DOWN)) <= Geometry.FLOOR_MAX_ANGLE:
                    side = SurfaceSide.FLOOR
                    is_touching_floor = true
                elif abs(direction.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
                    side = SurfaceSide.CEILING
                    is_touching_ceiling = true
                elif direction.x < 0:
                    side = SurfaceSide.LEFT_WALL
                    is_touching_left_wall = true
                else:
                    side = SurfaceSide.RIGHT_WALL
                    is_touching_right_wall = true
                
                perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
                should_try_without_perpendicular_nudge_first = true
    
    var from := ray_trace_target - direction * 0.001
    var to := ray_trace_target + direction * 1000000
    
    if should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray(from, to, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    # If the ray tracing didn't hit the collider, then try nudging it a little to either side.
    # This can happen when the point of intersection is a vertex of the collider.
    
    if collision.empty():
        collision = space_state.intersect_ray(from + perpendicular_offset, \
                to + perpendicular_offset, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    if !should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray(from, to, shape_query_params.exclude, \
                shape_query_params.collision_layer)
        
    if collision.empty():
        collision = space_state.intersect_ray(from - perpendicular_offset, \
                to - perpendicular_offset, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    assert(!collision.empty())
    
    # FIXME: Add back in?
#    assert(Geometry.are_points_equal_with_epsilon( \
#            collision.position, ray_trace_target, perpendicular_offset.length + 0.0001))
    
    # If we haven't yet defined the surface side, do that now, based off the collision normal.
    if side == SurfaceSide.NONE:
        if abs(collision.normal.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
            side = SurfaceSide.FLOOR
            is_touching_floor = true
        elif abs(collision.normal.angle_to(Geometry.DOWN)) <= Geometry.FLOOR_MAX_ANGLE:
            side = SurfaceSide.CEILING
            is_touching_ceiling = true
        elif collision.normal.x > 0:
            side = SurfaceSide.LEFT_WALL
            is_touching_left_wall = true
        else:
            side = SurfaceSide.RIGHT_WALL
            is_touching_right_wall = true

    var intersection_point: Vector2 = collision.position
    var tile_map: TileMap = collision.collider
    var tile_map_coord: Vector2 = Geometry.get_collision_tile_map_coord( \
            intersection_point, tile_map, is_touching_floor, is_touching_ceiling, \
            is_touching_left_wall, is_touching_right_wall, false)
    
    # If get_collision_tile_map_coord returns an invalid result, then it's because the motion is
    # moving away from that tile and not into it. This happens when the starting position is within
    # EDGE_MOVEMENT_TEST_MARGIN from a surface.
    if tile_map_coord == Vector2.INF:
        return null
    
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord(tile_map_coord, tile_map)
    
    var surface := surface_parser.get_surface_for_tile(tile_map, tile_map_index, side)
    
    return SurfaceCollision.new(surface, intersection_point)

static func _calculate_constraints( \
        colliding_surface: Surface, constraint_offset: Vector2) -> Array:
    var passing_point_a: Vector2
    var constraint_a: MovementConstraint
    var passing_point_b: Vector2
    var constraint_b: MovementConstraint
    
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            # Left end
            passing_point_a = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, true, false)
        SurfaceSide.CEILING:
            # Left end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, true, false)
        SurfaceSide.LEFT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, false, false)
        SurfaceSide.RIGHT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, false, false)
    
    return [constraint_a, constraint_b]

# Calculates the vertical component of position and velocity according to the given vertical
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
# FIXME: B: Fix unit tests to use the return value instead of output params.
static func _update_vertical_end_state_for_time(movement_params: MovementParams, \
        vertical_step: MovementCalcStep, time: float) -> Vector2:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    var slow_ascent_end_time := min(time, vertical_step.time_instruction_end)
    
    # Basic equations of motion.
    var slow_ascent_end_position := vertical_step.position_start.y + \
            vertical_step.velocity_start.y * slow_ascent_end_time + \
            0.5 * movement_params.gravity_slow_ascent * slow_ascent_end_time * slow_ascent_end_time
    var slow_ascent_end_velocity := vertical_step.velocity_start.y + \
            movement_params.gravity_slow_ascent * slow_ascent_end_time
    
    var position: float
    var velocity: float
    if vertical_step.time_instruction_end >= time:
        # We only need to consider the slow-ascent parabolic section.
        position = slow_ascent_end_position
        velocity = slow_ascent_end_velocity
    else:
        # We need to consider both the slow-ascent and fast-fall parabolic sections.
        
        var fast_fall_duration := time - slow_ascent_end_time
        
        # Basic equations of motion.
        position = slow_ascent_end_position + \
            slow_ascent_end_velocity * fast_fall_duration + \
            0.5 * movement_params.gravity_fast_fall * fast_fall_duration * fast_fall_duration
        velocity = slow_ascent_end_velocity + movement_params.gravity_fast_fall * fast_fall_duration
    
    return Vector2(position, velocity)

# Calculates the horizontal component of position and velocity according to the given horizontal
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
static func _update_horizontal_end_state_for_time(movement_params: MovementParams, \
        horizontal_step: MovementCalcStep, time: float) -> Vector2:
    assert(time >= horizontal_step.time_start - Geometry.FLOAT_EPSILON)
    assert(time <= horizontal_step.time_step_end + Geometry.FLOAT_EPSILON)
    
    var position: float
    var velocity: float
    if time > horizontal_step.time_instruction_end:
        var delta_time := time - horizontal_step.time_instruction_end
        velocity = horizontal_step.velocity_instruction_end.x
        # From basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_instruction_end.x + velocity * delta_time
    else:
        var delta_time := time - horizontal_step.time_start
        var acceleration := movement_params.in_air_horizontal_acceleration * \
                horizontal_step.horizontal_movement_sign
        # From basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position = horizontal_step.position_start.x + \
                horizontal_step.velocity_start.x * delta_time + \
                0.5 * acceleration * delta_time * delta_time
        # From basic equation of motion:
        #     v = v_0 + a*t
        velocity = horizontal_step.velocity_start.x + acceleration * delta_time
    
    assert(velocity <= movement_params.max_horizontal_speed_default + 0.001)
    
    return Vector2(position, velocity)

# Calculates the time at which the movement would travel through the given position given the
# given vertical_step.
# FIXME: B: Update unit tests to include min_end_time.
static func _calculate_end_time_for_jumping_to_position(movement_params: MovementParams, \
        vertical_step: MovementCalcStep, position: Vector2, min_end_time: float, \
        upcoming_constraint: MovementConstraint, destination_surface: Surface) -> float:
    var position_instruction_end := vertical_step.position_instruction_end
    var velocity_instruction_end := vertical_step.velocity_instruction_end
    
    var target_height := position.y
    var start_height := vertical_step.position_start.y
    
    var duration_of_slow_ascent: float
    var duration_of_fast_fall: float
    
    var surface := \
            upcoming_constraint.surface if upcoming_constraint != null else destination_surface
    
    var is_position_before_instruction_end: bool
    var is_position_before_peak: bool
    
    # We need to know whether the position corresponds to the rising or falling side of the jump
    # parabola, and whether the position correpsonds to before or after the jump button is
    # released.
    match surface.side:
        SurfaceSide.FLOOR:
            # Jump reaches the position after releasing the jump button (and after the peak).
            is_position_before_instruction_end = false
            is_position_before_peak = false
        SurfaceSide.CEILING:
            # Jump reaches the position before the peak.
            is_position_before_peak = true
            
            if target_height > start_height:
                return INF
            
            if target_height > position_instruction_end.y:
                # Jump reaches the position before releasing the jump button.
                is_position_before_instruction_end = true
            else:
                # Jump reaches the position after releasing the jump button (but before the
                # peak).
                is_position_before_instruction_end = false
        _: # A wall.
            if upcoming_constraint != null:
                # We are considering an intermediate constraint.
                if upcoming_constraint.should_stay_on_min_side:
                    # Passing over the top of the wall (jump reaches the position before the peak).
                    is_position_before_peak = true
                    
                    # FIXME: Double-check whether the vertical_step calculations will have actually
                    #        supported upward velocity at this point, or whether it will be forcing
                    #        downward?
                    
                    if target_height > position_instruction_end.y:
                        # We assume that we will always use upward velocity when passing over a
                        # wall.
                        # Jump reaches the position before releasing the jump button.
                        is_position_before_instruction_end = true
                    else:
                        # We assume that we will always use downward velocity when passing under a
                        # wall.
                        # Jump reaches the position after releasing the jump button.
                        is_position_before_instruction_end = false
                else:
                    # Passing under the bottom of the wall (jump reaches the position after
                    # releasing the jump button and after the peak).
                    is_position_before_instruction_end = false
                    is_position_before_peak = false
            else:
                # We are considering a destination surface.
                # We assume destination walls will always use downward velocity at the end.
                is_position_before_instruction_end = false
                is_position_before_peak = false
    
    if is_position_before_instruction_end:
        duration_of_slow_ascent = Geometry.solve_for_movement_duration(start_height, \
                target_height, movement_params.jump_boost, movement_params.gravity_slow_ascent, \
                true, min_end_time, false)
        if duration_of_slow_ascent == INF:
            return INF
        duration_of_fast_fall = 0.0
    else:
        duration_of_slow_ascent = vertical_step.time_instruction_end
        min_end_time = max(min_end_time - duration_of_slow_ascent, 0.0)
        duration_of_fast_fall = Geometry.solve_for_movement_duration( \
                position_instruction_end.y, target_height, velocity_instruction_end.y, \
                movement_params.gravity_fast_fall, is_position_before_peak, min_end_time, false)
        if duration_of_fast_fall == INF:
            return INF
    
    return duration_of_fast_fall + duration_of_slow_ascent

# Calculates the duration to accelerate over in order to reach the destination at the given time,
# given that velocity continues after acceleration stops and a new backward acceleration is
# applied.
static func _calculate_time_to_release_acceleration(time_start: float, time_step_end: float, \
        position_start: float, position_end: float, velocity_start: float, \
        acceleration_start: float, post_release_backward_acceleration: float, \
        returns_lower_result := true, expects_only_one_positive_result := false) -> float:
    var duration := time_step_end - time_start
    
    # Derivation:
    # - Start with basic equations of motion
    # - v_1 = v_0 + a_0*t_0
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - s_0 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - t_2 = t_0 + t_1
    # - Do some algebra...
    # - 0 = (1/2*(a_0 - a_1)) * t_0^2 + (t_2 * (a_1 - a_0)) * t_0 + (s_2 - s_0 - t_2 * (v_0 + 1/2*a_1*t_2))
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (acceleration_start - post_release_backward_acceleration)
    var b := duration * (post_release_backward_acceleration - acceleration_start)
    var c := position_end - position_start - duration * \
            (velocity_start + 0.5 * post_release_backward_acceleration * duration)
    
    # This would produce a divide-by-zero.
    assert(a != 0)
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b + discriminant_sqrt) / 2 / a
    var t2 := (-b - discriminant_sqrt) / 2 / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0 or t2 < 0)
    # Ensure that there are not two negative results.
    assert(t1 >= 0 or t2 >= 0)
    
    # Use only non-negative results.
    if t1 < 0:
        return t2
    elif t2 < 0:
        return t1
    else:
        if returns_lower_result:
            return min(t1, t2)
        else:
            return max(t1, t2)

# Calculates the minimum required time to reach the destination, considering a maximum velocity.
static func _calculate_min_time_to_reach_position(s_0: float, s: float, \
        v_0: float, speed_max: float, a: float) -> float:
    # FIXME: A: Check whether any of these asserts should be replaced with `return INF`.
    
    if s_0 == s:
        # The start position is the destination.
        return 0.0
    elif a == 0:
        # Handle the degenerate case with no acceleration.
        if v_0 == 0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (s - s_0 > 0) != (v_0 > 0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return (s - s_0) / v_0
    
    var velocity_max := speed_max if a > 0 else -speed_max
    
    var duration_to_reach_position_with_no_velocity_cap: float = \
            Geometry.solve_for_movement_duration(s_0, s, v_0, a, true, 0.0, true)
    
    if duration_to_reach_position_with_no_velocity_cap == INF:
        # We can't ever reach the destination.
        return INF
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_max_velocity := (velocity_max - v_0) / a
    assert(duration_to_reach_max_velocity > 0)
    
    if duration_to_reach_max_velocity >= duration_to_reach_position_with_no_velocity_cap:
        # We won't have hit the max velocity before reaching the destination.
        return duration_to_reach_position_with_no_velocity_cap
    else:
        # We will have hit the max velocity before reaching the destination.
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        var position_when_reaching_max_velocity := s_0 + v_0 * duration_to_reach_max_velocity + \
                0.5 * a * duration_to_reach_max_velocity * duration_to_reach_max_velocity
        
        # From a basic equation of motion:
        #     s = s_0 + v*t
        var duration_with_max_velocity := (s - position_when_reaching_max_velocity) / velocity_max
        assert(duration_with_max_velocity > 0)
        
        return duration_to_reach_max_velocity + duration_with_max_velocity













func _get_nearby_and_fallable_surfaces(origin_surface: Surface) -> Array:
    # FIXME: C
    # - remove the temporary return value of all surfaces
    # - _get_nearby_surfaces
    #   - Consider up-front-calculated max range according to horizontal acceleration/max and vertical acceleration/max
    # - For up-front edge calculations, we want to be more permissive and return more fallable surfaces
    # - For run-time finding-path-from-new-in-air-position calculations, we want to be more restrictive and just return the best handful (5? parameterize it)
    #   - Probably still the closest X
    #   - Consider initial velocity?
    # - Should either version consider occlusion at all? [no]
    # - Consider velocity changes due to gravity.
    return surfaces
    
    # FIXME: D: Update _get_closest_fallable_surface to support falling from the
    #        center of fall-through surfaces (consider the whole surface, rather than just the
    #        ends).

    # TODO: Prevent duplicate work from finding matching surfaces as both nearby and fallable.
    # var results := _get_nearby_surfaces(origin_surface, SURFACE_CLOSE_DISTANCE_THRESHOLD, surfaces)
    
    # var origin_vertex: Vector2
    # var closest_fallable_surface: Surface
    
    # origin_vertex = origin_surface.vertices[0]
    # closest_fallable_surface = _get_closest_fallable_surface(origin_vertex, surfaces, true)
    # if !results.has(closest_fallable_surface):
    #     results.push_back(closest_fallable_surface)
    
    # origin_vertex = origin_surface.vertices[origin_surface.vertices.size() - 1]
    # closest_fallable_surface = _get_closest_fallable_surface(origin_vertex, surfaces, true)
    # if !results.has(closest_fallable_surface):
    #     results.push_back(closest_fallable_surface)
    
    # return results

# Gets all other surfaces that are near the given surface.
static func _get_nearby_surfaces(target_surface: Surface, distance_threshold: float, \
        other_surfaces: Array) -> Array:
    var result := []
    for other_surface in other_surfaces:
        if _get_are_surfaces_close(target_surface, other_surface, distance_threshold) and \
                target_surface != other_surface:
            result.push_back(other_surface)
    return result

static func _get_are_surfaces_close(surface_a: Surface, surface_b: Surface, \
        distance_threshold: float) -> bool:
    var vertices_a := surface_a.vertices
    var vertices_b := surface_b.vertices
    var vertex_a_a: Vector2
    var vertex_a_b: Vector2
    var vertex_b_a: Vector2
    var vertex_b_b: Vector2
    
    var expanded_bounding_box_a = surface_a.bounding_box.grow(distance_threshold)
    if expanded_bounding_box_a.intersects(surface_b.bounding_box):
        var expanded_bounding_box_b = surface_b.bounding_box.grow(distance_threshold)
        var distance_squared_threshold = distance_threshold * distance_threshold
        
        # Compare each segment in A with each vertex in B.
        for i_a in range(vertices_a.size() - 1):
            vertex_a_a = vertices_a[i_a]
            vertex_a_b = vertices_a[i_a + 1]
            
            for i_b in range(vertices_b.size()):
                vertex_b_a = vertices_b[i_b]
                
                if expanded_bounding_box_a.has_point(vertex_b_a) and \
                        Geometry.get_distance_squared_from_point_to_segment( \
                                vertex_b_a, vertex_a_a, vertex_a_b) <= distance_squared_threshold:
                    return true
        
        # Compare each vertex in A with each segment in B.
        for i_a in range(vertices_a.size()):
            vertex_a_a = vertices_a[i_a]
            
            for i_b in range(vertices_b.size() - 1):
                vertex_b_a = vertices_b[i_b]
                vertex_b_b = vertices_b[i_b + 1]
                
                if expanded_bounding_box_b.has_point(vertex_a_a) and \
                        Geometry.get_distance_squared_from_point_to_segment( \
                                vertex_a_a, vertex_b_a, vertex_b_b) <= distance_squared_threshold:
                    return true
            
            # Handle the degenerate case of single-vertex surfaces.
            if vertices_b.size() == 1:
                if vertex_a_a.distance_squared_to(vertices_b[0]) <= distance_squared_threshold:
                    return true
    
    return false





# Gets the closest surface that can be reached by falling from the given point.
func _get_closest_fallable_surface(start: Vector2, surfaces: Array, \
        can_use_horizontal_distance := false) -> Surface:
    var end_x_distance = DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING * \
            params.max_horizontal_speed_default / \
            params.max_vertical_speed
    var end_y = start.y + DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING
    
    if can_use_horizontal_distance:
        var start_x_distance = params.max_horizontal_distance
        
        var leftmost_start = Vector2(start.x - start_x_distance, start.y)
        var rightmost_start = Vector2(start.x + start_x_distance, start.y)
        var leftmost_end = Vector2(leftmost_start.x - end_x_distance, end_y)
        var rightmost_end = Vector2(rightmost_start.x + end_x_distance, end_y)
        
        return _get_closest_fallable_surface_intersecting_polygon(start, \
                [leftmost_start, rightmost_start, rightmost_end, leftmost_end], \
                surfaces)
    else:
        var leftmost_end = Vector2(start.x - end_x_distance, end_y)
        var rightmost_end = Vector2(start.x + end_x_distance, end_y)
        
        return _get_closest_fallable_surface_intersecting_triangle(start, start, leftmost_end, \
                rightmost_end, surfaces)

static func _get_closest_fallable_surface_intersecting_triangle(target: Vector2, \
        triangle_a: Vector2, triangle_b: Vector2, triangle_c: Vector2, surfaces: Array) -> Surface:
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for current_surface in surfaces:
        current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                current_surface.bounding_box)
        if current_distance_squared < closest_distance_squared:
            if Geometry.do_polyline_and_triangle_intersect(current_surface.vertices, \
                    triangle_a, triangle_b, triangle_c):
                # FIXME: -B: ****
                # - Calculate instruction set (or determine whether it's not possible)
                # - Reconcile this with how PlayerMovement now works...
                current_distance_squared = \
                        Geometry.get_distance_squared_from_point_to_polyline( \
                                target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                        closest_distance_squared = current_distance_squared
                        closest_surface = current_surface
    
    return closest_surface

static func _get_closest_fallable_surface_intersecting_polygon(target: Vector2, polygon: Array, \
        surfaces: Array) -> Surface:
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for current_surface in surfaces:
        current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                current_surface.bounding_box)
        if current_distance_squared < closest_distance_squared:
            if Geometry.do_polyline_and_polygon_intersect(current_surface.vertices, polygon):
                # FIXME: -B: **** Copy above version
                current_distance_squared = \
                        Geometry.get_distance_squared_from_point_to_polyline( \
                                target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                        closest_distance_squared = current_distance_squared
                        closest_surface = current_surface
    
    return closest_surface
