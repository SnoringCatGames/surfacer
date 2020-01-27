# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

const NAME := "AirToSurfaceEdge"
const IS_TIME_BASED := true
const ENTERS_AIR := false

func _init(start: Vector2, end: PositionAlongSurface, calc_results: MovementCalcResults) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, Edge.vector2_to_position_along_surface(start), end, \
        _calculate_instructions(start, end, calc_results)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return Edge.check_expected_end_surface(surface_state, self.end_surface)

static func _calculate_instructions( \
        position_start: Vector2, position_end: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            position_start, position_end.target_point, calc_results, false, \
            position_end.surface.side)
