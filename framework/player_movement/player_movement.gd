# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const MovementConstraint = preload("res://framework/player_movement/movement_constraint.gd")
const PlayerInstruction = preload("res://framework/player_movement/player_instruction.gd")

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD := 512.0
const DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING := 10000.0

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

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, surface: Surface) -> Array:
    Utils.error( \
            "Abstract PlayerMovement.get_all_edges_from_surface is not implemented")
    return []

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_to_air is not implemented")
    return null

func get_all_reachable_surface_instructions_from_air(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: PositionAlongSurface, start_velocity: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []

# FIXME: LEFT OFF HERE: C: Remove. Replace with an up-front calculation when the params are initialized.
func get_max_upward_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_upward_distance is not implemented")
    return 0.0

# FIXME: LEFT OFF HERE: C: Remove. Replace with an up-front calculation when the params are initialized.
func get_max_horizontal_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_horizontal_distance is not implemented")
    return 0.0

static func update_velocity_in_air( \
        velocity: Vector2, delta: float, is_pressing_jump: bool, is_first_jump: bool, \
        horizontal_movement_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += movement_params.in_air_horizontal_acceleration * horizontal_movement_sign
    
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

# Checks whether a collision would occur with any surface during the given horizontal step. This
# is calculated by stepping through each physics frame, which should exactly emulate the actual
# Player trajectory that would be used.
func _check_horizontal_step_for_collision( \
        global_calc_params: MovementCalcGlobalParams, local_calc_params: MovementCalcLocalParams, \
        horizontal_step: MovementCalcStep) -> Surface:
    var delta := Utils.PHYSICS_TIME_STEP
    var is_first_jump := true
    var previous_time := horizontal_step.time_start
    var current_time := horizontal_step.time_start
    var step_end_time := horizontal_step.time_step_end
    var horizontal_instruction_end_time := horizontal_step.time_instruction_end
    var position := horizontal_step.position_start
    var velocity := horizontal_step.velocity_start
    var jump_instruction_end_time := local_calc_params.vertical_step.time_instruction_end
    var is_pressing_jump := jump_instruction_end_time > current_time
    var is_pressing_move_horizontal := horizontal_instruction_end_time > current_time
    var space_state := global_calc_params.space_state
    var shape_query_params := global_calc_params.shape_query_params
    var displacement: Vector2
    var colliding_surface: Surface
    
    # Record the position for edge annotation debugging.
    horizontal_step.frame_positions.push_back(position)
    
    # Iterate through each physics frame, checking each for a collision.
    while current_time < step_end_time:
        # Update position for this frame.
        previous_time = current_time
        current_time += delta
        displacement = velocity * delta
        shape_query_params.transform = Transform2D(0.0, position)
        shape_query_params.motion = displacement
        
        # Check for collision.
        colliding_surface = check_frame_for_collision(space_state, shape_query_params)
        if colliding_surface != null:
            return colliding_surface
        
        position += displacement
        
        # Determine whether the jump button is still being pressed.
        is_pressing_jump = jump_instruction_end_time > current_time
        
        # Determine whether the horizontal movement button is still being pressed.
        is_pressing_move_horizontal = horizontal_instruction_end_time > current_time
        
        # Update velocity for the next frame.
        velocity = update_velocity_in_air(velocity, delta, is_pressing_jump, is_first_jump, \
                horizontal_step.horizontal_movement_sign, params)
        velocity = cap_velocity(velocity, params)
        
        # Record the position for edge annotation debugging.
        horizontal_step.frame_positions.push_back(position)
    
    # Check the last frame that puts us up to end_time.
    delta = step_end_time - current_time
    displacement = velocity * delta
    shape_query_params.transform = Transform2D(0.0, position)
    shape_query_params.motion = displacement
    colliding_surface = check_frame_for_collision(space_state, shape_query_params)
    if colliding_surface != null:
        return colliding_surface
    
    # Record the position for edge annotation debugging.
    horizontal_step.frame_positions.push_back(position + displacement)
    
    return null

# Determines whether the given motion of the given shape would collide with a surface. If a
# collision would occur, this returns the surface; otherwise, this returns null.
func check_frame_for_collision(space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters) -> Surface:
    # FIXME: B: Check whether all of the level setup must be called from within an early
    #   _physics_process callback (space might have a lock otherwise)?
    
    var collision_points := space_state.collide_shape(shape_query_params, 1)
    if collision_points.empty():
        return null
    
    var collision_point: Vector2 = collision_points[0]
    var direction := shape_query_params.motion.normalized()
    var from := collision_point - direction * 0.001
    var to := collision_point + direction * 1000000
    var collision := space_state.intersect_ray(from, to, shape_query_params.exclude, \
            shape_query_params.collision_layer)
    
    var side: int
    var is_touching_floor := false
    var is_touching_ceiling := false
    var is_touching_left_wall := false
    var is_touching_right_wall := false
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
    
    var tile_map: TileMap = collision.collider
    var tile_map_coord: Vector2 = Geometry.get_collision_tile_map_coord( \
            collision_point, tile_map, is_touching_floor, is_touching_ceiling, \
            is_touching_left_wall, is_touching_right_wall)
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord(tile_map_coord, tile_map)
    
    return surface_parser.get_surface_for_tile(tile_map, tile_map_index, side)

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
            constraint_a = MovementConstraint.new(passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_b = MovementConstraint.new(passing_point_b, true, false)
        SurfaceSide.CEILING:
            # Left end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_a = MovementConstraint.new(passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(passing_point_b, true, false)
        SurfaceSide.LEFT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(passing_point_b, false, false)
        SurfaceSide.RIGHT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(passing_point_b, false, false)
    
    return [constraint_a, constraint_b]

# Calculates the vertical component of position and velocity according to the given vertical
# movement state and the given time. These are then stored on either the given output step's
# step-end state or instruction-end state depending on is_step_end_time.
func _update_vertical_end_state_for_time(output_step: MovementCalcStep, \
        vertical_step: MovementCalcStep, time: float, is_step_end_time: bool) -> void:
    var slow_ascent_gravity := params.gravity * params.ascent_gravity_multiplier
    var slow_ascent_end_time := min(time, vertical_step.time_instruction_end)
    
    # Basic equations of motion.
    var slow_ascent_end_position := vertical_step.position_start.y + \
            vertical_step.velocity_start.y * slow_ascent_end_time + \
            0.5 * slow_ascent_gravity * slow_ascent_end_time * slow_ascent_end_time
    var slow_ascent_end_velocity := \
            vertical_step.velocity_start.y + slow_ascent_gravity * slow_ascent_end_time
    
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
            0.5 * params.gravity * fast_fall_duration * fast_fall_duration
        velocity = slow_ascent_end_velocity + params.gravity * fast_fall_duration
    
    if is_step_end_time:
        output_step.position_step_end.y = position
        output_step.velocity_step_end.y = velocity
    else:
        output_step.position_instruction_end.y = position
        output_step.velocity_instruction_end.y = velocity

# FIXME: LEFT OFF HERE: -----------------------------A ********
# - How to know whether we are ascending or descending when we hit this target position?
#   - Keep track of colliding surface in Constraint
#   - Save constraint that we are going toward on local_params
#   - pass local_parmas in to this function
#   - if local_calc_params.end_constraint.surface.side == "floor":
#     - Then we should return whichever time is before peak
#   - floors are after peak
#   - PROBLEM: what about walls?
#     - I guess we can know time-to-collide-with-wall from horizontal acceleration/velocity,
#       time_start of step, position_start of step, and position of constraint.
#     - time-to-collide-with-wall is the step-end time
#     - [ignore] But... wall's mean backtracking... or falling to the bottom constraint
#     - Actually, horizontal movement isn't good, since the constraint is actually forcing us to result in a period of straight up or down motion to get around a corner
#     - So, instead, we should just look at whether the wall constraint is at the top or bottom edge
#     - If top, then we should be travelling upward when we hit it
#     - If bottom, then we should be travelling downward when we hit it
func _calculate_end_time_for_jumping_to_position( \
        vertical_step: MovementCalcStep, position: Vector2) -> float:
    # if position.y < vertical_step.position_instruction_end.y:
    return INF

func _get_nearby_and_fallable_surfaces(origin_surface: Surface) -> Array:
    # TODO: Prevent duplicate work from finding matching surfaces as both nearby and fallable.
    var results := _get_nearby_surfaces(origin_surface, SURFACE_CLOSE_DISTANCE_THRESHOLD, surfaces)
    
    # FIXME: LEFT OFF HERE: D: Update _get_closest_fallable_surface to support falling from the
    #        center of fall-through surfaces (consider the whole surface, rather than just the
    #        ends).
    # TODO: Consider velocity changes due to gravity.
    # TODO: Add support for choosing the closest "non-occluded" surface to the destination, rather
    #       than the closest surface to the origin.
    # TODO: Add support for falling to surfaces other than just the closest one.
    
    var origin_vertex: Vector2
    var closest_fallable_surface: Surface
    
    origin_vertex = origin_surface.vertices[0]
    closest_fallable_surface = _get_closest_fallable_surface(origin_vertex, surfaces, true)
    if !results.has(closest_fallable_surface):
        results.push_back(closest_fallable_surface)
    
    origin_vertex = origin_surface.vertices[origin_surface.vertices.size() - 1]
    closest_fallable_surface = _get_closest_fallable_surface(origin_vertex, surfaces, true)
    if !results.has(closest_fallable_surface):
        results.push_back(closest_fallable_surface)
    
    return results

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
        var start_x_distance = get_max_horizontal_distance()
        
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
                # FIXME: LEFT OFF HERE: -B: ****
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
                # FIXME: LEFT OFF HERE: -B: **** Copy above version
                current_distance_squared = \
                        Geometry.get_distance_squared_from_point_to_polyline( \
                                target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                        closest_distance_squared = current_distance_squared
                        closest_surface = current_surface
    
    return closest_surface
