# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

const TYPE := EdgeType.AIR_TO_SURFACE_EDGE
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := false

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        includes_extra_wall_land_horizontal_speed: bool, \
        movement_params: MovementParams, \
        instructions: EdgeInstructions, \
        trajectory: EdgeTrajectory) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        calculator, \
        start, \
        end, \
        velocity_start, \
        velocity_end, \
        false, \
        includes_extra_wall_land_horizontal_speed, \
        movement_params, \
        instructions, \
        trajectory) -> void:
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
    return Edge.check_just_landed_on_expected_surface(surface_state, self.end_surface)
