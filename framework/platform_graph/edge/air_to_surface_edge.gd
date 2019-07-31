# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

var start: Vector2
var end: PositionAlongSurface

func _init(start: Vector2, end: PositionAlongSurface, calc_results: MovementCalcResults) \
        .(_calculate_instructions(start, end, calc_results)) -> void:
    self.start = start
    self.end = end

static func _calculate_instructions( \
        position_start: Vector2, position_end: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> PlayerInstructions:
    return PlayerMovement.convert_calculation_steps_to_player_instructions( \
            position_start, position_end.target_point, calc_results)
