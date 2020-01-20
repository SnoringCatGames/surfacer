# Information for how to move from a start position to an end position.
extends Reference
class_name Edge

var start: Vector2 setget ,_get_start
var end: Vector2 setget ,_get_end

var start_surface: Surface setget ,_get_start_surface
var end_surface: Surface setget ,_get_end_surface

var name: String

# Whether the instructions for moving along this edge are updated according to traversal time (vs
# according to surface state).
var is_time_based: bool

var instructions: MovementInstructions

var weight: float setget ,_get_weight

func _init(name: String, is_time_based: bool, instructions: MovementInstructions) -> void:
    self.name = name
    self.is_time_based = is_time_based
    self.instructions = instructions

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

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    Utils.error("Abstract Edge._check_did_just_reach_destination is not implemented")
    return false

func _get_start() -> Vector2:
    Utils.error("Abstract Edge._get_start is not implemented")
    return Vector2.INF

func _get_end() -> Vector2:
    Utils.error("Abstract Edge._get_end is not implemented")
    return Vector2.INF

func _get_start_surface() -> Surface:
    Utils.error("Abstract Edge._get_start_surface is not implemented")
    return null

func _get_end_surface() -> Surface:
    Utils.error("Abstract Edge._get_end_surface is not implemented")
    return null

func _get_weight() -> float:
    return instructions.distance

func _get_start_string() -> String:
    Utils.error("Abstract Edge._get_start_string is not implemented")
    return ""

func _get_end_string() -> String:
    Utils.error("Abstract Edge._get_end_string is not implemented")
    return ""

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
