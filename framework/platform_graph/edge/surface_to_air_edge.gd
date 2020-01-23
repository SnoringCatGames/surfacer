# Information for how to move from a surface to a position in the air.
extends Edge
class_name SurfaceToAirEdge

const NAME := "SurfaceToAirEdge"
const IS_TIME_BASED := true

func _init(start: PositionAlongSurface, end: Vector2, calc_results: MovementCalcResults) \
        .(NAME, IS_TIME_BASED, start, Edge.vector2_to_position_along_surface(end), \
                _calculate_instructions(start, end, calc_results)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return playback.is_finished

static func _calculate_instructions( \
        position_start: PositionAlongSurface, end: Vector2, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            position_start.target_point, end, calc_results, true, SurfaceSide.NONE)
