# Information for how to move from a start position to an end position.
extends Reference
class_name Edge

var name: String

# Whether the instructions for moving along this edge are updated according to traversal time (vs
# according to surface state).
var is_time_based: bool

# Whether the movement along this edge transitions from grabbing a surface to being airborne.
var enters_air: bool

var instructions: MovementInstructions

var distance: float
var duration: float

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

var weight: float setget ,_get_weight

var start: Vector2 setget ,_get_start
var end: Vector2 setget ,_get_end

var start_surface: Surface setget ,_get_start_surface
var end_surface: Surface setget ,_get_end_surface

func _init(\
        name: String, \
        is_time_based: bool, \
        enters_air: bool, \
        start_position_along_surface: PositionAlongSurface, \
        end_position_along_surface: PositionAlongSurface, \
        calc_results: MovementCalcResults) -> void:
    self.name = name
    self.is_time_based = is_time_based
    self.enters_air = enters_air
    self.start_position_along_surface = start_position_along_surface
    self.end_position_along_surface = end_position_along_surface
    self.instructions = _calculate_instructions( \
            start_position_along_surface, end_position_along_surface, calc_results)
    self.distance = _calculate_distance( \
            start_position_along_surface, end_position_along_surface, instructions)
    self.duration = _calculate_duration( \
            start_position_along_surface, end_position_along_surface, instructions, distance)

func update_for_surface_state(surface_state: PlayerSurfaceState) -> void:
    # Do nothing unless the sub-class implements this.
    pass

func update_navigation_state(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> void:
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.end_surface
    navigation_state.just_left_air_unexpectedly = surface_state.just_left_air and \
            !is_grabbed_surface_expected and surface_state.collision_count > 0
    
    navigation_state.just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !navigation_state.is_expecting_to_enter_air
    
    navigation_state.just_interrupted_by_user_action = \
            UserActionSource.get_is_some_user_action_pressed()
    
    navigation_state.just_interrupted_navigation = navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    if surface_state.just_entered_air:
        navigation_state.is_expecting_to_enter_air = false
    
    navigation_state.just_reached_end_of_edge = _check_did_just_reach_destination( \
            navigation_state, surface_state, playback)

func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
    Utils.error("Abstract Edge._calculate_instructions is not implemented")
    return null

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    Utils.error("Abstract Edge._calculate_distance is not implemented")
    return INF

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, distance: float) -> float:
    Utils.error("Abstract Edge._calculate_duration is not implemented")
    return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    Utils.error("Abstract Edge._check_did_just_reach_destination is not implemented")
    return false

func _get_weight() -> float:
    # FIXME: LEFT OFF HERE: --------------------------A Incorporate smarter, configurable weights.
    return distance

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

func to_string() -> String:
    var format_string_template := "%s{ start: %s, end: %s, instructions: %s }"
    var format_string_arguments := [ \
            name, \
            _get_start_string(), \
            _get_end_string(), \
            instructions.to_string(), \
        ]
    return format_string_template % format_string_arguments

func to_string_with_newlines(indent_level: int) -> String:
    var indent_level_str := ""
    for i in range(indent_level):
        indent_level_str += "\t"
    
    var format_string_template := "%s{" + \
            "\n\t%sstart: %s," + \
            "\n\t%send: %s," + \
            "\n\t%sinstructions: %s," + \
        "\n%s}"
    var format_string_arguments := [ \
            name, \
            indent_level_str, \
            _get_start_string(), \
            indent_level_str, \
            _get_end_string(), \
            indent_level_str, \
            instructions.to_string_with_newlines(indent_level + 1), \
            indent_level_str, \
        ]
    
    return format_string_template % format_string_arguments

# This creates a PositionAlongSurface object with the given target point and a null Surface.
static func vector2_to_position_along_surface(target_point: Vector2) -> PositionAlongSurface:
    var position_along_surface := PositionAlongSurface.new()
    position_along_surface.target_point = target_point
    return position_along_surface

static func check_just_landed_on_expected_surface(surface_state: PlayerSurfaceState, \
        end_surface: Surface) -> bool:
    return surface_state.just_left_air and surface_state.grabbed_surface == end_surface

static func sum_distance_between_frames(frame_positions: PoolVector2Array) -> float:
    assert(frame_positions.size() > 1)
    var previous_position := frame_positions[0]
    var next_position: Vector2
    var sum := 0.0
    for i in range(1, frame_positions.size()):
        next_position = frame_positions[i]
        sum += previous_position.distance_to(next_position)
        previous_position = next_position
    return sum
