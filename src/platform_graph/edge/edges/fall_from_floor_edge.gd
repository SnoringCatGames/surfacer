class_name FallFromFloorEdge
extends Edge
# Information for how to walk to and off the edge of a floor.
# 
# -   The instructions for this edge consist of a single sideways key press,
#     with no corresponding release.
# -   The start point for this edge corresponds to the surface-edge end point.
# -   This edge consists of a small portion for walking from the start point
#     to the fall-off point, and then another portion for falling from the
#     fall-off point to the landing point.


const TYPE := EdgeType.FALL_FROM_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true

var falls_on_left_side: bool
var fall_off_position: PositionAlongSurface
var time_fall_off: float


func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        distance := INF,
        duration := INF,
        includes_extra_wall_land_horizontal_speed := false,
        movement_params: MovementParameters = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null,
        edge_calc_result_type := EdgeCalcResultType.UNKNOWN,
        falls_on_left_side := false,
        fall_off_position: PositionAlongSurface = null,
        time_fall_off := INF) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        calculator,
        start,
        end,
        velocity_start,
        velocity_end,
        distance,
        duration,
        false,
        includes_extra_wall_land_horizontal_speed,
        movement_params,
        instructions,
        trajectory,
        edge_calc_result_type,
        0.0) -> void:
    self.falls_on_left_side = falls_on_left_side
    self.fall_off_position = fall_off_position
    self.time_fall_off = time_fall_off


func get_animation_state_at_time(
        result: SurfacerCharacterAnimationState,
        edge_time: float) -> void:
    result.character_position = get_position_at_time(edge_time)
    result.grabbed_surface = null
    result.grab_position = Vector2.INF
    result.animation_name = "JumpFall"
    result.animation_position = edge_time
    result.facing_left = \
            instructions.get_is_facing_left_at_time(
                    edge_time, falls_on_left_side) if \
            edge_time > time_fall_off else \
            falls_on_left_side


func _sync_expected_middle_surface_state(
        surface_state: CharacterSurfaceState,
        edge_time: float) -> void:
    var edge_frame_index := int(edge_time / ScaffolderTime.PHYSICS_TIME_STEP)
    var fall_off_index := int(time_fall_off / ScaffolderTime.PHYSICS_TIME_STEP)
    var is_on_start_floor := edge_frame_index < fall_off_index
    var did_just_release := edge_frame_index == fall_off_index
    var position := get_position_at_time(edge_time)
    var velocity := get_velocity_at_time(edge_time)
    var facing_left := falls_on_left_side
    
    if is_on_start_floor:
        surface_state.sync_state_for_surface_grab(
                get_start_surface(),
                position,
                false,
                facing_left)
    elif did_just_release:
        surface_state.sync_state_for_surface_release(
                get_start_surface(),
                position)
    else:
        surface_state.clear_current_state()
    
    surface_state.center_position = position
    surface_state.velocity = velocity


func _update_expected_position_along_surface(
        navigation_state: CharacterNavigationState,
        edge_time: float) -> void:
    var position := navigation_state.expected_position_along_surface
    if edge_time < time_fall_off:
        position.target_point = get_position_at_time(edge_time)
        position.surface = get_start_surface()
        position.update_target_projection_onto_surface()
    else:
        ._update_expected_position_along_surface(
                navigation_state,
                edge_time)


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    return check_just_landed_on_expected_surface(
            surface_state,
            self.get_end_surface(),
            playback)


# When walking off the end of a surface, Godot's underlying collision engine
# can trigger multiple extraneous launch/land events if the character's
# collision boundary is not square. So this function override adds logic to
# ignore any of these extra collisions with the starting surface.
func _update_navigation_state_edge_specific_helper(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        is_starting_navigation_retry: bool) -> void:
    if is_starting_navigation_retry:
        # This should never happen.
        Sc.logger.error("FallFromFloorEdge._update_navigation_state_edge_specific_helper")
        return
    
    var is_still_colliding_with_start_surface := \
            surface_state.grabbed_surface == self.get_start_surface()
    if is_still_colliding_with_start_surface:
        navigation_state.is_expecting_to_enter_air = true
    
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.get_end_surface() or \
            is_still_colliding_with_start_surface
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.contact_count > 0


func _load_edge_state_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    ._load_edge_state_from_json_object(json_object, context)
    falls_on_left_side = json_object.fl
    fall_off_position = \
            context.id_to_position_along_surface[int(json_object.fp)]
    time_fall_off = json_object.ft


func _edge_state_to_json_object(json_object: Dictionary) -> void:
    ._edge_state_to_json_object(json_object)
    json_object.fl = falls_on_left_side
    json_object.fp = fall_off_position.get_instance_id()
    json_object.ft = time_fall_off
    
