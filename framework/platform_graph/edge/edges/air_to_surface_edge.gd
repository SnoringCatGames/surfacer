# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

const NAME := "AirToSurfaceEdge"
const IS_TIME_BASED := true
const ENTERS_AIR := false

func _init(start: Vector2, end: PositionAlongSurface, instructions: MovementInstructions) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, Edge.vector2_to_position_along_surface(start), end, \
        instructions) -> void:
    pass

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return Edge.sum_distance_between_frames(instructions.frame_continuous_positions_from_steps)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, distance: float) -> float:
    # FIXME: ----------
    return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return Edge.check_just_landed_on_expected_surface(surface_state, self.end_surface)
