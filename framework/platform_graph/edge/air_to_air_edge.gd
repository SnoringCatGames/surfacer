# Information for how to move through the air from a start position to an end position.
extends Edge
class_name AirToAirEdge

const NAME := "AirToAirEdge"
const IS_TIME_BASED := true
const ENTERS_AIR := false

func _init(start: Vector2, end: Vector2) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, Edge.vector2_to_position_along_surface(start), \
        Edge.vector2_to_position_along_surface(end), null) -> void:
    pass

func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
    # TODO: Implement
    return null

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return Edge.sum_distance_between_frames(instructions.frame_continous_positions_from_steps)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, distance: float) -> float:
    # FIXME: ----------
    return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return playback.is_finished
