# Information for how to walk to and off the edge of a floor.
# 
# The instructions for this edge consist of a single sideways key press, with no corresponding
# release.
extends Edge
class_name FallFromFloorEdge

const NAME := "FallFromFloorEdge"
const IS_TIME_BASED := false
const ENTERS_AIR := true

var falls_on_left_side: bool

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, falls_on_left_side: bool) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, start, end, instructions) -> void:
    self.falls_on_left_side = falls_on_left_side

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
