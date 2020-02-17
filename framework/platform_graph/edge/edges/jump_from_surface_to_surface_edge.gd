# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Edge
class_name JumpFromSurfaceToSurfaceEdge

const NAME := "JumpFromSurfaceToSurfaceEdge"
const IS_TIME_BASED := true
const ENTERS_AIR := true

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, start, end, instructions) -> void:
    pass

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return Edge.sum_distance_between_frames(instructions.frame_continous_positions_from_steps)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, distance: float) -> float:
    # FIXME: ----------
    return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return Edge.check_just_landed_on_expected_surface(surface_state, self.end_surface)
