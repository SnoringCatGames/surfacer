# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

const NAME := "AirToSurfaceEdge"
const IS_TIME_BASED := true

var _start: Vector2
var end_position_along_surface: PositionAlongSurface

func _init(start: Vector2, end: PositionAlongSurface, calc_results: MovementCalcResults) \
        .(NAME, IS_TIME_BASED, _calculate_instructions(start, end, calc_results)) -> void:
    self._start = start
    self.end_position_along_surface = end

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    var just_landed_on_expected_surface: bool = surface_state.just_left_air and \
            surface_state.grabbed_surface == self.end_surface
    return just_landed_on_expected_surface

func _get_start() -> Vector2:
    return _start

func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func _get_start_surface() -> Surface:
    return null

func _get_end_surface() -> Surface:
    return end_position_along_surface.surface

func _get_start_string() -> String:
    return String(_start)

func _get_end_string() -> String:
    return end_position_along_surface.to_string()

static func _calculate_instructions( \
        position_start: Vector2, position_end: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            position_start, position_end.target_point, calc_results, false, \
            position_end.surface.side)
