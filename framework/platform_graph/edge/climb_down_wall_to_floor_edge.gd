# Information for how to climb down a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of a single downward key press, with no corresponding
# release. This will cause the player to climb down the wall, then grab the floor once they reach
# it.
extends Edge
class_name ClimbDownWallToFloorEdge

const NAME := "ClimbDownWallToFloorEdge"
const IS_TIME_BASED := false

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(NAME, IS_TIME_BASED, start, end, _calculate_instructions(start, end)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_grabbed_floor

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    assert(end.surface.side == SurfaceSide.FLOOR)
    
    var instruction := MovementInstruction.new("move_down", 0.0, true)
    
    var distance := start.target_point.distance_to(end.target_point)
    
    return MovementInstructions.new([instruction], INF, distance)
