# Information for how to let go of a wall in order to fall.
# 
# The instructions for this edge consist of a single sideways key press, with no corresponding
# release.
extends Edge
class_name FallFromWallEdge

const NAME := "FallFromWallEdge"
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true

func _init( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_end: Vector2, \
        movement_params: MovementParams, \
        instructions: MovementInstructions, \
        trajectory: MovementTrajectory) \
        .(NAME, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        start, \
        end, \
        Vector2.ZERO, \
        velocity_end, \
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
        movement_params: MovementParams, \
        distance: float) -> float:
    return instructions.duration

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return Edge.check_just_landed_on_expected_surface(surface_state, self.end_surface)
