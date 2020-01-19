# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Edge
class_name InterSurfaceEdge

const NAME := "InterSurfaceEdge"
const IS_TIME_BASED := true

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions).(NAME, IS_TIME_BASED, instructions) -> void:
    self.start_position_along_surface = start
    self.end_position_along_surface = end

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    var just_landed_on_expected_surface: bool = surface_state.just_left_air and \
            surface_state.grabbed_surface == self.end_surface
    return just_landed_on_expected_surface

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func _get_start_surface() -> Surface:
    return start_position_along_surface.surface

func _get_end_surface() -> Surface:
    return end_position_along_surface.surface

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return end_position_along_surface.to_string()
