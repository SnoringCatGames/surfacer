# Information for how to move through the air from a start position to an end position.
class_name AirToAirEdge
extends Edge

const TYPE := EdgeType.AIR_TO_AIR_EDGE
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := true

func _init( \
        calculator, \
        start: Vector2, \
        end: Vector2, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        movement_params: MovementParams, \
        instructions: EdgeInstructions, \
        trajectory: EdgeTrajectory, \
        edge_calc_result_type: int) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        INCLUDES_AIR_TRAJECTORY, \
        calculator, \
        Edge.vector2_to_position_along_surface(start), \
        Edge.vector2_to_position_along_surface(end), \
        velocity_start, \
        velocity_end, \
        false, \
        false, \
        movement_params, \
        instructions, \
        trajectory, \
        edge_calc_result_type) -> void:
    pass

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: EdgeTrajectory) -> float:
    return trajectory.distance_from_continuous_frames

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    return instructions.duration

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return playback.is_finished
