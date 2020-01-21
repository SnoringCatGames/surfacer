# Information for how to move from a surface to a position in the air.
extends Edge
class_name SurfaceToAirEdge

const NAME := "SurfaceToAirEdge"
const IS_TIME_BASED := true

var start_position_along_surface: PositionAlongSurface
var _end: Vector2

func _init(start: PositionAlongSurface, end: Vector2, calc_results: MovementCalcResults) \
        .(NAME, IS_TIME_BASED, _calculate_instructions(start, end, calc_results)) -> void:
    self.start_position_along_surface = start
    self._end = end

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return playback.is_finished

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return _end

func _get_start_surface() -> Surface:
    return start_position_along_surface.surface

func _get_end_surface() -> Surface:
    return null

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return String(_end)

static func _calculate_instructions( \
        position_start: PositionAlongSurface, end: Vector2, \
        calc_results: MovementCalcResults) -> MovementInstructions:
    return MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
            position_start.target_point, end, calc_results, true, SurfaceSide.NONE)
