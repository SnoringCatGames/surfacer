# Basic information for a hypothetical edge.
extends Reference
class_name EdgeAttempt

var edge_type := EdgeType.UNKNOWN

var edge_calc_result_type := EdgeCalcResultType.UNKNOWN

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

var velocity_start := Vector2.INF

# Whether this edge is calculated using extra jump duration from the start.
var includes_extra_jump_duration: bool

# Whether this edge is calculated using extra horizontal end velocity.
var includes_extra_wall_land_horizontal_speed: bool

var calculator

var start: Vector2 setget ,_get_start
var end: Vector2 setget ,_get_end

var start_surface: Surface setget ,_get_start_surface
var end_surface: Surface setget ,_get_end_surface

func _init( \
        edge_type: int, \
        edge_calc_result_type: int, \
        start_position_along_surface: PositionAlongSurface, \
        end_position_along_surface: PositionAlongSurface, \
        velocity_start: Vector2, \
        includes_extra_jump_duration: bool, \
        includes_extra_wall_land_horizontal_speed: bool, \
        calculator) -> void:
    self.edge_type = edge_type
    self.edge_calc_result_type = edge_calc_result_type
    self.start_position_along_surface = start_position_along_surface
    self.end_position_along_surface = end_position_along_surface
    self.velocity_start = velocity_start
    self.includes_extra_jump_duration = includes_extra_jump_duration
    self.includes_extra_wall_land_horizontal_speed = \
            includes_extra_wall_land_horizontal_speed
    self.calculator = calculator

func _get_start() -> Vector2:
    return start_position_along_surface.target_point
func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func _get_start_surface() -> Surface:
    return start_position_along_surface.surface
func _get_end_surface() -> Surface:
    return end_position_along_surface.surface
