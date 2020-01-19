# Information for how to let go of a wall in order to fall.
# 
# The instructions for this edge consist of a single sideways key press, with no corresponding
# release.
extends Edge
class_name FallFromWallEdge

const NAME := "FallFromWallEdge"
const IS_TIME_BASED := false

var start_position_along_surface: PositionAlongSurface
var _end: Vector2

func _init(start: PositionAlongSurface, end: Vector2) \
        .(NAME, IS_TIME_BASED, _calculate_instructions(start, end)) -> void:
    self.start_position_along_surface = start
    self._end = end

static func _calculate_instructions(start: PositionAlongSurface, \
        end: Vector2) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    
    var sideways_input_key := \
            "move_right" if start.surface.side == SurfaceSide.LEFT_WALL else "move_left"
    var inward_instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    var instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    var distance_squared := start.target_point.distance_squared_to(end)
    return MovementInstructions.new([instruction], INF, distance_squared)

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_entered_air

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
