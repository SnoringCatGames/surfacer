# Basic information for a hypothetical edge.
class_name EdgeAttempt
extends Reference

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

func _init(
        edge_type: int,
        edge_calc_result_type: int,
        start_position_along_surface: PositionAlongSurface,
        end_position_along_surface: PositionAlongSurface,
        velocity_start: Vector2,
        includes_extra_jump_duration: bool,
        includes_extra_wall_land_horizontal_speed: bool,
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

func get_start() -> Vector2:
    return start_position_along_surface.target_point
func get_end() -> Vector2:
    return end_position_along_surface.target_point

func get_start_surface() -> Surface:
    return start_position_along_surface.surface
func get_end_surface() -> Surface:
    return end_position_along_surface.surface

func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    Gs.logger.error(
            "Abstract EdgeAttempt.load_from_json_object is not implemented")

func to_json_object() -> Dictionary:
    Gs.logger.error("Abstract EdgeAttempt.to_json_object is not implemented")
    return {}

func _load_edge_attempt_state_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    edge_type = json_object.t
    edge_calc_result_type = json_object.r
    start_position_along_surface = \
            context.id_to_position_along_surface[int(json_object.s)]
    end_position_along_surface = \
            context.id_to_position_along_surface[int(json_object.e)]
    velocity_start = Gs.utils.decode_vector2(json_object.v)
    includes_extra_jump_duration = json_object.d
    includes_extra_wall_land_horizontal_speed = json_object.h
    calculator = Surfacer.edge_movements[json_object.c]

func _edge_attempt_state_to_json_object(json_object: Dictionary) -> void:
    json_object.t = edge_type
    json_object.r = edge_calc_result_type
    json_object.s = start_position_along_surface.get_instance_id()
    json_object.e = end_position_along_surface.get_instance_id()
    json_object.v = Gs.utils.encode_vector2(velocity_start)
    json_object.d = includes_extra_jump_duration
    json_object.h = includes_extra_wall_land_horizontal_speed
    json_object.c = calculator.name
