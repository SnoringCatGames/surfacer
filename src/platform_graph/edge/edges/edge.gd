# Information for how to move from a start position to an end position.
class_name Edge
extends EdgeAttempt

# Whether the instructions for moving along this edge are updated according to
# traversal time (vs according to surface state).
var is_time_based: bool

var surface_type: int

# Whether the movement along this edge transitions from grabbing a surface to
# being airborne.
var enters_air: bool

var includes_air_trajectory: bool

var movement_params: MovementParams

# Whether this edge was created by the navigator for a specific path at
# run-time, rather than ahead of time when initially parsing the platform
# graph.
var is_optimized_for_path := false

var instructions: EdgeInstructions

var trajectory: EdgeTrajectory

var velocity_end := Vector2.INF

# In pixels.
var distance: float
# In seconds.
var duration: float

var name: String setget ,_get_name

var should_end_by_colliding_with_surface: bool setget \
        ,_get_should_end_by_colliding_with_surface

func _init( \
        edge_type: int, \
        is_time_based: bool, \
        surface_type: int, \
        enters_air: bool, \
        includes_air_trajectory: bool, \
        calculator, \
        start_position_along_surface: PositionAlongSurface, \
        end_position_along_surface: PositionAlongSurface, \
        velocity_start: Vector2, \
        velocity_end: Vector2, \
        includes_extra_jump_duration: bool, \
        includes_extra_wall_land_horizontal_speed: bool, \
        movement_params: MovementParams, \
        instructions: EdgeInstructions, \
        trajectory: EdgeTrajectory, \
        edge_calc_result_type: int \
        ).( \
        edge_type, \
        edge_calc_result_type, \
        start_position_along_surface, \
        end_position_along_surface, \
        velocity_start, \
        includes_extra_jump_duration, \
        includes_extra_wall_land_horizontal_speed, \
        calculator \
        ) -> void:
    self.is_time_based = is_time_based
    self.surface_type = surface_type
    self.enters_air = enters_air
    self.includes_air_trajectory = includes_air_trajectory
    self.movement_params = movement_params
    self.velocity_end = velocity_end
    self.instructions = instructions
    self.trajectory = trajectory
    self.distance = _calculate_distance( \
            start_position_along_surface, \
            end_position_along_surface, \
            trajectory)
    self.duration = _calculate_duration( \
            start_position_along_surface, \
            end_position_along_surface, \
            instructions, \
            distance)

func update_for_surface_state( \
        surface_state: PlayerSurfaceState, \
        is_final_edge: bool) -> void:
    # Do nothing unless the sub-class implements this.
    pass

func update_navigation_state( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback, \
        just_started_new_edge: bool, \
        is_starting_navigation_retry: bool) -> void:
    # When retrying navigation, we need to ignore whatever surface state in the 
    # current frame led to the previous navigation being interrupted.
    if is_starting_navigation_retry:
        navigation_state.just_left_air_unexpectedly = false
        navigation_state.just_entered_air_unexpectedly = false
        navigation_state.just_interrupted_by_user_action = false
        navigation_state.just_interrupted_navigation = false
        navigation_state.just_reached_end_of_edge = false
        return
    
    var still_grabbing_start_surface_at_start := \
            just_started_new_edge and \
            surface_state.grabbed_surface == self.start_surface
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.end_surface
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.collision_count > 0 and \
            !still_grabbing_start_surface_at_start
    
    navigation_state.just_entered_air_unexpectedly = \
            surface_state.just_entered_air and \
            !navigation_state.is_expecting_to_enter_air
    
    navigation_state.just_interrupted_by_user_action = \
            navigation_state.is_human_player and \
            UserActionSource.get_is_some_user_action_pressed()
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    if surface_state.just_entered_air:
        navigation_state.is_expecting_to_enter_air = false
    
    navigation_state.just_reached_end_of_edge = \
            _check_did_just_reach_destination( \
                    navigation_state, \
                    surface_state, \
                    playback)

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: EdgeTrajectory) -> float:
    Gs.utils.error("Abstract Edge._calculate_distance is not implemented")
    return INF

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    Gs.utils.error("Abstract Edge._calculate_duration is not implemented")
    return INF

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    Gs.utils.error( \
            "Abstract Edge._check_did_just_reach_destination is not " + \
            "implemented")
    return false

func get_weight() -> float:
    # Use either the distance or the duration as the weight for the edge.
    var weight := duration if \
            movement_params \
                    .uses_duration_instead_of_distance_for_edge_weight else \
            distance
    
    # Apply a multiplier to the weight according to the type of edge.
    weight *= _get_weight_multiplier()
    
    # Give a constant extra weight for each additional edge in a path.
    weight += movement_params.additional_edge_weight_offset
    
    return weight

func _get_weight_multiplier() -> float:
    match surface_type:
        SurfaceType.FLOOR:
            return movement_params.walking_edge_weight_multiplier
        SurfaceType.WALL:
            return movement_params.climbing_edge_weight_multiplier
        SurfaceType.AIR:
            return movement_params.air_edge_weight_multiplier
        _:
            Gs.utils.error()
            return INF

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

func _get_name() -> String:
    return EdgeType.get_string(edge_type)

func _get_should_end_by_colliding_with_surface() -> bool:
    return end_position_along_surface.surface != \
            start_position_along_surface.surface and \
            end_position_along_surface.surface != null

func to_string() -> String:
    var format_string_template := \
            "%s{ " + \
            "start: %s, " + \
            "end: %s, " + \
            "velocity_start: %s, " + \
            "velocity_end: %s, " + \
            "distance: %s, " + \
            "duration: %s, " + \
            "is_optimized_for_path: %s, " + \
            "instructions: %s " + \
            "}"
    var format_string_arguments := [ \
            _get_name(), \
            _get_start_string(), \
            _get_end_string(), \
            str(velocity_start), \
            str(velocity_end), \
            distance, \
            duration, \
            is_optimized_for_path, \
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
            "\n\t%svelocity_start: %s," + \
            "\n\t%svelocity_end: %s," + \
            "\n\t%sdistance: %s," + \
            "\n\t%sduration: %s," + \
            "\n\t%sis_optimized_for_path: %s," + \
            "\n\t%sinstructions: %s," + \
        "\n%s}"
    var format_string_arguments := [ \
            _get_name(), \
            indent_level_str, \
            _get_start_string(), \
            indent_level_str, \
            _get_end_string(), \
            indent_level_str, \
            str(velocity_start), \
            indent_level_str, \
            str(velocity_end), \
            indent_level_str, \
            distance, \
            indent_level_str, \
            duration, \
            indent_level_str, \
            is_optimized_for_path, \
            indent_level_str, \
            instructions.to_string_with_newlines(indent_level + 1), \
            indent_level_str, \
        ]
    
    return format_string_template % format_string_arguments

# This creates a PositionAlongSurface object with the given target point and a
# null Surface.
static func vector2_to_position_along_surface(target_point: Vector2) -> \
        PositionAlongSurface:
    var position_along_surface := PositionAlongSurface.new()
    position_along_surface.target_point = target_point
    return position_along_surface

static func check_just_landed_on_expected_surface( \
        surface_state: PlayerSurfaceState, \
        end_surface: Surface) -> bool:
    return surface_state.just_left_air and \
            surface_state.grabbed_surface == end_surface
