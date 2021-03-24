# Information for how to move from a surface to a position in the air.
class_name JumpFromSurfaceToAirEdge
extends Edge

const TYPE := EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true
const INCLUDES_AIR_TRAJECTORY := true

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        includes_extra_jump_duration: bool, \
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
        start, \
        end, \
        velocity_start, \
        velocity_end, \
        includes_extra_jump_duration, \
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
