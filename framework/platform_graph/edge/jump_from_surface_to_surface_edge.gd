# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Edge
class_name JumpFromSurfaceToSurfaceEdge

const NAME := "JumpFromSurfaceToSurfaceEdge"
const IS_TIME_BASED := true

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        calc_results: MovementCalcResults).(NAME, IS_TIME_BASED, start, end, \
                _calculate_instructions(start, end, calc_results)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    var just_landed_on_expected_surface: bool = surface_state.just_left_air and \
            surface_state.grabbed_surface == self.end_surface
    return just_landed_on_expected_surface

static func _calculate_instructions( \
        position_start: PositionAlongSurface, position_end: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            position_start.target_point, position_end.target_point, calc_results, true, \
            position_end.surface.side)
