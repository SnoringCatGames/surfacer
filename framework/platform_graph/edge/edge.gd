# Information for how to move from a start position to an end position.
extends Reference
class_name Edge

var start: Vector2 setget ,_get_start
var end: Vector2 setget ,_get_end

var start_surface: Surface setget ,_get_start_surface
var end_surface: Surface setget ,_get_end_surface

var instructions: MovementInstructions

var weight: float setget ,_get_weight

func _init(instructions: MovementInstructions) -> void:
    self.instructions = instructions

func update_for_player_state(player) -> void:
    # Do nothing unless the sub-class implements this.
    pass

# FIXME: LEFT OFF HERE: ------------------------------------A:
# - Move this into Edge and edge sub-classes.
# - Start with IntraSurfaceEdge.
# 
# - Refactor Navigator to update edge/playback on each frame, and instead rely on them to signal
#   edge-end/interrupt and instruction updates.
#   - Refactor MovementInstructions into two separate sub-classes: time-based and event-based.
#     - Update InstructionsPlayback to be the place where event updates are pushed through.
#       - Split `update` into two separate methods: time-based and event-based.
#   - Update Playback to accept Edge rather than Instructions.
#   - Update InstructionsPlayback to handle the time-based and event-based instructions
#     differently.
# 
# - Then create the new Edge sub-classes after the infrastructure change is done.
func update_edge_navigation_state(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback: InstructionsPlayback) -> void:
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.end_surface
    var is_moving_along_intra_surface_edge := surface_state.is_grabbing_a_surface and \
            is_grabbed_surface_expected and !surface_state.just_left_air
    navigation_state.just_left_air_unexpectedly = surface_state.just_left_air and \
            !is_grabbed_surface_expected and surface_state.collision_count > 0
    navigation_state.just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !navigation_state.is_expecting_to_enter_air
    navigation_state.just_landed_on_expected_surface = surface_state.just_left_air and \
            surface_state.grabbed_surface == self.end_surface
    navigation_state.just_interrupted_by_user_action = \
            UserActionSource.get_is_some_user_action_pressed()
    navigation_state.just_interrupted_navigation = navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    if surface_state.just_entered_air:
        navigation_state.is_expecting_to_enter_air = false
    
    if is_moving_along_intra_surface_edge:
        var target_point: Vector2 = self.end
        var was_less_than_end: bool
        var is_less_than_end: bool
        if surface_state.is_grabbing_wall:
            was_less_than_end = surface_state.previous_center_position.y < target_point.y
            is_less_than_end = surface_state.center_position.y < target_point.y
        else:
            was_less_than_end = surface_state.previous_center_position.x < target_point.x
            is_less_than_end = surface_state.center_position.x < target_point.x
        
        navigation_state.just_reached_intra_surface_destination = \
                was_less_than_end != is_less_than_end
    else:
        navigation_state.just_reached_intra_surface_destination = false
    
    var is_moving_to_expected_in_air_destination: bool = \
            !surface_state.is_touching_a_surface and self.end_surface == null
    
    if is_moving_to_expected_in_air_destination:
        navigation_state.just_reached_in_air_destination = playback.is_finished
    else:
        navigation_state.just_reached_in_air_destination = false
    
    navigation_state.just_reached_end_of_edge = \
            navigation_state.just_reached_intra_surface_destination or \
            navigation_state.just_landed_on_expected_surface or \
            navigation_state.just_reached_in_air_destination

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
    return instructions.distance_squared

func _get_class_name() -> String:
    Utils.error("Abstract Edge._get_class_name is not implemented")
    return ""

func _get_start_string() -> String:
    Utils.error("Abstract Edge._get_start_string is not implemented")
    return ""

func _get_end_string() -> String:
    Utils.error("Abstract Edge._get_end_string is not implemented")
    return ""

func to_string() -> String:
    var format_string_template := "%s{ start: %s, end: %s, instructions: %s }"
    var format_string_arguments := [ \
            _get_class_name(), \
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
            _get_class_name(), \
            indent_level_str, \
            _get_start_string(), \
            indent_level_str, \
            _get_end_string(), \
            indent_level_str, \
            instructions.to_string_with_newlines(indent_level + 1), \
            indent_level_str, \
        ]
    
    return format_string_template % format_string_arguments
