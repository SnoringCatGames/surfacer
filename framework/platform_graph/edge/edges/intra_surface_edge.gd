# Information for how to move along a surface from a start position to an end position.
# 
# The instructions for an intra-surface edge consist of a single directional-key press step, with
# no corresponding release.
extends Edge
class_name IntraSurfaceEdge

const NAME := "IntraSurfaceEdge"
const IS_TIME_BASED := false
const ENTERS_AIR := false

const REACHED_DESTINATION_DISTANCE_SQUARED_THRESHOLD := 2.0

func _init( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        movement_params: MovementParams) \
        .(NAME, \
        IS_TIME_BASED, \
        SurfaceType.get_type_from_side(start.surface.side), \
        ENTERS_AIR, \
        start, \
        end, \
        velocity_start, \
        _calculate_velocity_end(start, end, velocity_start, movement_params), \
        movement_params, \
        _calculate_instructions(start, end)) -> void:
    pass

func update_for_surface_state(surface_state: PlayerSurfaceState) -> void:
    instructions = _calculate_instructions(surface_state.center_position_along_surface, \
            end_position_along_surface)

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return start.target_point.distance_to(end.target_point)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, movement_params: MovementParams, \
        distance: float) -> float:
    match surface_type:
        SurfaceType.FLOOR:
            return MovementUtils.calculate_time_to_walk(distance, 0.0, movement_params)
        SurfaceType.WALL:
            var is_climbing_upward := end.target_point.y < start.target_point.y
            return MovementUtils.calculate_time_to_climb( \
                    distance, is_climbing_upward, movement_params)
        _:
            Utils.error()
            return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    # Check whether we were on the other side of the destination in the previous frame.
    var target_point: Vector2 = self.end
    var was_less_than_end: bool
    var is_less_than_end: bool
    var diff: float
    if surface_state.is_grabbing_wall:
        was_less_than_end = surface_state.previous_center_position.y < target_point.y
        is_less_than_end = surface_state.center_position.y < target_point.y
        diff = target_point.y - surface_state.center_position.y
    else:
        was_less_than_end = surface_state.previous_center_position.x < target_point.x
        is_less_than_end = surface_state.center_position.x < target_point.x
        diff = target_point.x - surface_state.center_position.x
    return was_less_than_end != is_less_than_end or abs(diff) < \
            REACHED_DESTINATION_DISTANCE_SQUARED_THRESHOLD

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    var is_wall_surface := \
            end.surface.side == SurfaceSide.LEFT_WALL || end.surface.side == SurfaceSide.RIGHT_WALL
    
    var input_key: String
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
    
    var instruction := MovementInstruction.new(input_key, 0.0, true)
    
    return MovementInstructions.new([instruction], INF)

static func _calculate_velocity_end(start: PositionAlongSurface, end: PositionAlongSurface, \
        velocity_start: Vector2, movement_params: MovementParams) -> Vector2:
    var displacement := end.target_point - start.target_point
    
    if start.surface.side == SurfaceSide.FLOOR or start.surface.side == SurfaceSide.CEILING:
        # We need to calculate the end velocity, taking into account whether we will have had
        # enough distance to reach max horizontal speed.
        var acceleration := movement_params.walk_acceleration if displacement.x > 0.0 else \
                -movement_params.walk_acceleration
        var velocity_end_x: float = MovementUtils.calculate_velocity_end_for_displacement( \
                displacement.x, velocity_start.x, acceleration, \
                movement_params.max_horizontal_speed_default)
        return Vector2(velocity_end_x, 0.0)
    else:
        # We use a constant speed (no acceleration) when climbing.
        var velocity_end_y := movement_params.climb_up_speed if displacement.y < 0.0 else \
                movement_params.climb_down_speed
        return Vector2(0.0, velocity_end_y)
