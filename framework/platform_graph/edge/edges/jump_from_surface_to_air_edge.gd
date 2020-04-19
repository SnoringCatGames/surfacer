# Information for how to move from a surface to a position in the air.
extends Edge
class_name JumpFromSurfaceToAirEdge

const NAME := "JumpFromSurfaceToAirEdge"
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        includes_extra_jump_duration: bool, \
        movement_params: MovementParams, \
        instructions: MovementInstructions, \
        trajectory: MovementTrajectory) \
        .(NAME, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        calculator, \
        start, \
        end, \
        velocity_start, \
        velocity_end, \
        includes_extra_jump_duration, \
        false, \
        movement_params, \
        instructions, \
        trajectory) -> void:
    pass

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: MovementTrajectory) -> float:
    return trajectory.distance_from_continuous_frames

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: MovementInstructions, \
        distance: float) -> float:
    return instructions.duration

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return playback.is_finished
