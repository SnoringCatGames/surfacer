# Information for how to move along a surface from a start position to an end
# position.
# 
# The instructions for an intra-surface edge consist of a single
# directional-key press step, with no corresponding release.
class_name IntraSurfaceEdge
extends Edge

const TYPE := EdgeType.INTRA_SURFACE_EDGE
const IS_TIME_BASED := false
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := false

const REACHED_DESTINATION_DISTANCE_THRESHOLD := 3.0

var stopping_distance := INF
var is_backtracking_to_not_protrude_past_surface_end := false

func _init( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        movement_params: MovementParams) \
        .(TYPE, \
        IS_TIME_BASED, \
        SurfaceType.get_type_from_side(start.side), \
        ENTERS_AIR, \
        INCLUDES_AIR_TRAJECTORY, \
        null, \
        start, \
        end, \
        velocity_start, \
        _calculate_velocity_end( \
                start, \
                end, \
                velocity_start, \
                movement_params), \
        false, \
        false, \
        movement_params, \
        _calculate_instructions(start, end), \
        null, \
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP) -> void:
    # Intra-surface edges are never calculated and stored ahead of time;
    # they're only calculated at run time when navigating a specific path.
    self.is_optimized_for_path = true

func update_terminal( \
        is_start: bool, \
        target_point: Vector2) -> void:
    if is_start:
        start_position_along_surface = \
                MovementUtils.create_position_offset_from_target_point( \
                        target_point, \
                        start_position_along_surface.surface, \
                        movement_params.collider_half_width_height, \
                        true)
    else:
        end_position_along_surface = \
                MovementUtils.create_position_offset_from_target_point( \
                        target_point, \
                        end_position_along_surface.surface, \
                        movement_params.collider_half_width_height, \
                        true)
    velocity_end = _calculate_velocity_end( \
            start_position_along_surface, \
            end_position_along_surface, \
            velocity_start, \
            movement_params)
    distance = _calculate_distance( \
            start_position_along_surface, \
            end_position_along_surface, \
            null)
    duration = _calculate_duration( \
            start_position_along_surface, \
            end_position_along_surface, \
            instructions, \
            distance)

func update_for_surface_state( \
        surface_state: PlayerSurfaceState, \
        is_final_edge: bool) -> void:
    instructions = _calculate_instructions( \
            surface_state.center_position_along_surface, \
            end_position_along_surface)
    
    if is_final_edge:
        var displacement_to_end := \
                end_position_along_surface.target_point - \
                surface_state.center_position
        stopping_distance = _calculate_stopping_distance( \
                movement_params, \
                self, \
                surface_state.velocity, \
                displacement_to_end)
    else:
        stopping_distance = 0.0

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: EdgeTrajectory) -> float:
    return start.target_point.distance_to(end.target_point)

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    return calculate_duration_to_move_along_surface( \
            movement_params, \
            start, \
            end, \
            distance)

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    # Check whether we were on the other side of the destination in the
    # previous frame.
    
    var end := end_position_along_surface.target_point
    
    var was_less_than_end: bool
    var is_less_than_end: bool
    var diff: float
    var is_moving_away_from_destination: bool
    
    if surface_state.is_grabbing_wall:
        var is_moving_upward: bool = \
                instructions.instructions[0].input_key == "move_up"
        var position_y_instruction_end := \
                end.y + stopping_distance if \
                is_moving_upward else \
                end.y - stopping_distance
        was_less_than_end = surface_state.previous_center_position.y < \
                position_y_instruction_end
        is_less_than_end = surface_state.center_position.y < \
                position_y_instruction_end
        diff = position_y_instruction_end - surface_state.center_position.y
        is_moving_away_from_destination = (diff > 0) == is_moving_upward
        
    else:
        var is_moving_leftward: bool = \
                instructions.instructions[0].input_key == "move_left"
        var position_x_instruction_end := \
                end.x + stopping_distance if \
                is_moving_leftward else \
                end.x - stopping_distance
        was_less_than_end = surface_state.previous_center_position.x < \
                position_x_instruction_end
        is_less_than_end = surface_state.center_position.x < \
                position_x_instruction_end
        diff = position_x_instruction_end - surface_state.center_position.x
        is_moving_away_from_destination = (diff > 0) == is_moving_leftward
    
    var moved_across_destination := was_less_than_end != is_less_than_end
    var is_close_to_destination := \
            abs(diff) < REACHED_DESTINATION_DISTANCE_THRESHOLD
    
    return moved_across_destination or \
            is_close_to_destination or \
            is_moving_away_from_destination

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface) -> EdgeInstructions:
    var input_key: String
    var is_wall_surface := end.surface.normal.y == 0.0
    if is_wall_surface:
        if start.target_point.y < end.target_point.y:
            input_key = "move_down"
        else:
            input_key = "move_up"
    else:
        if start.target_point.x < end.target_point.x:
            input_key = "move_right"
        else:
            input_key = "move_left"
    
    var instruction := EdgeInstruction.new( \
            input_key, \
            0.0, \
            true)
    
    return EdgeInstructions.new( \
            [instruction], \
            INF)

static func _calculate_velocity_end( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        movement_params: MovementParams) -> Vector2:
    var displacement := end.target_point - start.target_point
    
    if start.side == SurfaceSide.FLOOR or \
            start.side == SurfaceSide.CEILING:
        # We need to calculate the end velocity, taking into account whether we
        # will have had enough distance to reach max horizontal speed.
        var acceleration := \
                movement_params.walk_acceleration if \
                displacement.x > 0.0 else \
                -movement_params.walk_acceleration
        var velocity_end_x: float = \
                MovementUtils.calculate_velocity_end_for_displacement( \
                        displacement.x, \
                        velocity_start.x, \
                        acceleration, \
                        movement_params.max_horizontal_speed_default)
        return Vector2(velocity_end_x, 0.0)
    else:
        # We use a constant speed (no acceleration) when climbing.
        var velocity_end_y := \
                movement_params.climb_up_speed if \
                displacement.y < 0.0 else \
                movement_params.climb_down_speed
        return Vector2(0.0, velocity_end_y)

# Calculate the distance from the end position at which the move button should
# be released, so that the player comes to rest at the desired end position
# after decelerating due to friction (and with accelerating, or coasting at
# max-speed, until starting deceleration).
static func _calculate_stopping_distance( \
        movement_params: MovementParams, \
        edge: IntraSurfaceEdge, \
        velocity_start: Vector2, \
        displacement_to_end: Vector2) -> float:
    if movement_params.forces_player_position_to_match_path_at_end:
        return 0.0
    
    if edge.end_surface.side == SurfaceSide.FLOOR:
        var friction_coefficient: float = \
                movement_params.friction_coefficient * \
                edge.end_surface.tile_map.collision_friction
        var stopping_distance := MovementUtils \
                .calculate_distance_to_stop_from_friction_with_acceleration_to_non_max_speed( \
                        movement_params, \
                        velocity_start.x, \
                        displacement_to_end.x, \
                        movement_params.gravity_fast_fall, \
                        friction_coefficient)
        return stopping_distance if \
                abs(displacement_to_end.x) - stopping_distance > \
                        REACHED_DESTINATION_DISTANCE_THRESHOLD else \
                max(abs(displacement_to_end.x) - \
                        REACHED_DESTINATION_DISTANCE_THRESHOLD - 2.0, 0.0)
        
    else:
        # TODO: Add support for acceleration and friction alongs walls and ceilings.
        
        if edge.end_surface.side == SurfaceSide.LEFT_WALL or \
                edge.end_surface.side == SurfaceSide.RIGHT_WALL:
            var climb_speed := \
                    abs(movement_params.climb_up_speed) if \
                    displacement_to_end.y < 0 else \
                    abs(movement_params.climb_down_speed)
            return climb_speed * Time.PHYSICS_TIME_STEP_SEC + 0.01
        
        return 0.0

static func calculate_duration_to_move_along_surface( \
        movement_params: MovementParams, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        distance: float) -> float:
    match start.side:
        SurfaceSide.FLOOR, \
        SurfaceSide.CEILING:
            return MovementUtils.calculate_time_to_walk( \
                    distance, \
                    0.0, \
                    movement_params)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_climbing_upward := end.target_point.y < start.target_point.y
            return MovementUtils.calculate_time_to_climb( \
                    distance, \
                    is_climbing_upward, \
                    movement_params)
        _:
            Gs.utils.error()
            return INF
