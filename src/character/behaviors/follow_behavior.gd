tool
class_name FollowBehavior, \
"res://addons/surfacer/assets/images/editor_icons/follow_behavior.png"
extends Behavior


const NAME := "follow"
const IS_ADDED_MANUALLY := true
const USES_MOVE_TARGET := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := true
const COULD_RETURN_TO_START_POSITION := true

## -   The follower will stop moving when they are closer than this threshold
##     to the target.
export var close_enough_to_stop_moving_distance := 32.0 \
        setget _set_close_enough_to_stop_moving_distance

## -   The follower will start moving when they are further than this threshold
##     from the target.
export var far_enough_to_start_moving_distance := 64.0 \
        setget _set_far_enough_to_start_moving_distance

## -   The follower will stop following when they have fallen this far behind.
## -   If this is negative, the follower will always continue following.
export var detach_distance := -1.0 \
        setget _set_detach_distance

export var shows_exclamation_mark_on_detached := false

var is_close_enough_to_stop_moving := false
var is_far_enough_to_start_moving := false
var is_far_enough_to_detach := false


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        USES_MOVE_TARGET,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


func _on_inactive() -> void:
    ._on_inactive()
    is_close_enough_to_stop_moving = false
    is_far_enough_to_start_moving = false
    is_far_enough_to_detach = false


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: Overrides the parent version, so we don't have mid-movement pauses
    #       with re-navigation.
    #._on_navigation_ended(did_navigation_finish)
    pass


func _on_physics_process(delta_scaled: float) -> void:
    ._on_physics_process(delta_scaled)
    
    if !is_active or \
            get_is_paused():
        return
    
    var distance_squared_to_target: float = \
            character.surface_state.center_position.distance_squared_to(
                    move_target.position)
    
    var close_enough_to_stop_moving_distance_squared := \
            close_enough_to_stop_moving_distance * \
            close_enough_to_stop_moving_distance
    is_close_enough_to_stop_moving = \
            distance_squared_to_target < \
            close_enough_to_stop_moving_distance_squared
    
    var far_enough_to_start_moving_distance_squared := \
            far_enough_to_start_moving_distance * \
            far_enough_to_start_moving_distance
    is_far_enough_to_start_moving = \
            distance_squared_to_target > \
            far_enough_to_start_moving_distance_squared
    
    var detach_distance_squared := detach_distance * detach_distance
    is_far_enough_to_detach = \
            distance_squared_to_target > detach_distance_squared
    
    if is_far_enough_to_detach:
        on_detached()
        
    elif character.navigation_state.is_currently_navigating:
        if is_close_enough_to_stop_moving and \
                character.surface_state.is_grabbing_surface:
            # We are navigating, and we are close enough to the leader.
            character.navigator.stop(false)
            
        elif character.navigation_state.just_reached_end_of_edge and \
                    character.surface_state.just_left_air:
            # -   We are currently navigating, and we just landed on a new
            #     surface.
            # -   Update the navigation to point to the current leader
            #     position.
            var is_navigation_valid := _attempt_navigation()
            if !is_navigation_valid:
                _on_error(
                        ("FollowBehavior failed: " +
                        "Re-navigating between edges: " +
                        "behavior=%s, character=%s, position=%s") % [
                            behavior_name,
                            character.character_name,
                            Sc.utils.get_vector_string(
                                    character.surface_state.center_position),
                        ])
    else:
        if is_far_enough_to_start_moving:
            # We are not navigating, and we are far enough from the leader.
            var is_navigation_valid := _attempt_navigation()
            if !is_navigation_valid:
                _on_error(
                        ("FollowBehavior failed: " +
                        "Re-navigating due to distance from leader: " +
                        "behavior=%s, character=%s, position=%s") % [
                            behavior_name,
                            character.character_name,
                            Sc.utils.get_vector_string(
                                    character.surface_state.center_position),
                        ])


func on_detached() -> void:
    var move_target_str: String = \
            move_target.character_name if \
            move_target is ScaffolderCharacter else \
            str(move_target)
    character._log(
            "Fol detached",
            "from=%s" % move_target_str,
            CharacterLogType.BEHAVIOR,
            false)
    
    if shows_exclamation_mark_on_detached:
        character.show_exclamation_mark()
    
    if character.navigation_state.is_currently_navigating and \
            is_active:
        character.navigator.stop(false)
    
    _pause_post_movement()


func _move() -> int:
    return _attempt_navigation()


func _attempt_navigation() -> int:
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    var destination: PositionAlongSurface
    if move_target is ScaffolderCharacter:
        var position_type: int
        if move_target.surface_state.is_grabbing_surface:
            position_type = IntendedPositionType.CENTER_POSITION_ALONG_SURFACE
        elif move_target.navigation_state.is_currently_navigating:
            if move_target.navigator.edge.get_end_surface() != null:
                position_type = IntendedPositionType.EDGE_DESTINATION
            elif move_target.navigator.edge.get_start_surface() != null:
                position_type = IntendedPositionType.EDGE_ORIGIN
            else:
                position_type = IntendedPositionType.LAST_POSITION_ALONG_SURFACE
        elif move_target.surface_state.last_position_along_surface.surface != \
                null:
            position_type = IntendedPositionType.LAST_POSITION_ALONG_SURFACE
        else:
            return BehaviorMoveResult.ERROR
        
        var target_position: PositionAlongSurface = \
                move_target.get_intended_position(position_type)
        
        var surface := \
                target_position.surface if \
                can_leave_start_surface else \
                latest_activate_start_surface
        
        destination = PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        target_position.target_point,
                        surface,
                        character.collider,
                        true,
                        true)
        
    else:
        var surface_reachability := \
                SurfaceReachability.REVERSIBLY_REACHABLE if \
                only_navigates_reversible_paths else \
                SurfaceReachability.REACHABLE
        destination = SurfaceFinder.find_closest_position_on_a_surface(
                move_target.position,
                character,
                surface_reachability)
        if !is_instance_valid(destination):
            return BehaviorMoveResult.INVALID_MOVE
    
    if !destination.is_valid or \
            destination.target_point.distance_squared_to(
                    start_position_for_max_distance_checks) > \
            max_distance_squared_from_start_position:
        # The intended destination is too far away, so try a destination along
        # the current surface.
        destination = PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        destination.target_point,
                        character.surface_state.grabbed_surface,
                        character.collider,
                        true,
                        false)
        
        if destination.target_point.distance_squared_to(
                start_position_for_max_distance_checks) > \
                max_distance_squared_from_start_position:
            return BehaviorMoveResult.REACHED_MAX_DISTANCE
    
    return _attempt_navigation_to_destination(
            destination,
            _is_first_move_since_active)


func _on_reached_max_distance() -> void:
    # -   Do nothing.
    # -   The character will be detected as "detached" elsewhere.
    pass


func _update_parameters() -> void:
    ._update_parameters()
    
    if _configuration_warning != "":
        return
    
    if close_enough_to_stop_moving_distance <= 0.0:
        _set_configuration_warning(
                "close_enough_to_stop_moving_distance " +
                "must be greater than zero.")
        return
    
    if far_enough_to_start_moving_distance <= 0.0:
        _set_configuration_warning(
                "far_enough_to_start_moving_distance " +
                "must be greater than zero.")
        return
    
    if close_enough_to_stop_moving_distance >= \
            far_enough_to_start_moving_distance:
        _set_configuration_warning(
                "close_enough_to_stop_moving_distance must be less than " +
                "far_enough_to_start_moving_distance.")
        return
    
    if detach_distance > 0.0 and \
            (detach_distance <= close_enough_to_stop_moving_distance or \
            detach_distance <= far_enough_to_start_moving_distance):
        _set_configuration_warning(
                "detach_distance must be greater than " +
                "close_enough_to_stop_moving_distance and " +
                "far_enough_to_start_moving_distance.")
        return
    
    _set_configuration_warning("")


func _set_close_enough_to_stop_moving_distance(value: float) -> void:
    close_enough_to_stop_moving_distance = value
    _update_parameters()


func _set_far_enough_to_start_moving_distance(value: float) -> void:
    far_enough_to_start_moving_distance = value
    _update_parameters()


func _set_detach_distance(value: float) -> void:
    detach_distance = value
    _update_parameters()
