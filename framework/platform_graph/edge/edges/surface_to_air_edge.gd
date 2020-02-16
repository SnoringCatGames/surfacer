# Information for how to move from a surface to a position in the air.
extends Edge
class_name SurfaceToAirEdge

const NAME := "SurfaceToAirEdge"
const IS_TIME_BASED := true
const ENTERS_AIR := true

func _init(start: PositionAlongSurface, end: Vector2, calc_results: MovementCalcResults) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, start, Edge.vector2_to_position_along_surface(end), \
        calc_results) -> void:
    pass

func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            start.target_point, end.target_point, calc_results, true, end.surface.side)

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
