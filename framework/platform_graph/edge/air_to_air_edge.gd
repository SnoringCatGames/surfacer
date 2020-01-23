# Information for how to move through the air from a start position to an end position.
extends Edge
class_name AirToAirEdge

const NAME := "AirToAirEdge"
const IS_TIME_BASED := true

func _init(start: Vector2, end: Vector2) \
        .(NAME, IS_TIME_BASED, Edge.vector2_to_position_along_surface(start), \
        Edge.vector2_to_position_along_surface(end), _calculate_instructions(start, end)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return playback.is_finished

# TODO: Implement this
static func _calculate_instructions(start: Vector2, end: Vector2) -> MovementInstructions:
    return null
