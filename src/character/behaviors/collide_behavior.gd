tool
class_name CollideBehavior, \
"res://addons/surfacer/assets/images/editor_icons/collide_behavior.png"
extends Behavior


const NAME := "collide"
const IS_ADDED_MANUALLY := true
const USES_MOVE_TARGET := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := true
const COULD_RETURN_TO_START_POSITION := true

## -   If true, the character will navigate based on the target's current edge
##     destination rather than to the target's current position.
export var anticipates_target_edge := true \
        setget _set_anticipates_target_edge

## -   If true, the character will navigate based on the target's current path
##     destination rather than to the target's current position.
export var anticipates_target_path := false \
        setget _set_anticipates_target_path

## -   If true, the character will adjust their navigation each time the target
##     starts a new edge during their own navigation.
export var recomputes_nav_on_target_edge_change := true

var _last_target_edge: Edge
var _last_target_destination: PositionAlongSurface


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


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


func _on_physics_process(delta: float) -> void:
    ._on_physics_process(delta)
    if !is_instance_valid(move_target):
        return
    _update_target_edge()


func _on_target_edge_change(
        next_target_edge: Edge,
        previous_target_edge: Edge,
        next_target_destination: PositionAlongSurface,
        previous_target_destination: PositionAlongSurface) -> void:
    if recomputes_nav_on_target_edge_change and \
            !anticipates_target_path or \
            next_target_destination != \
            previous_target_destination:
        trigger(false)


func on_collided() -> void:
    character._log(
            "Col collided",
            "with=%s" % move_target.character_name,
            CharacterLogType.BEHAVIOR,
            false)
    
    _pause_post_movement()
    
    if character.navigation_state.is_currently_navigating and \
            is_active:
        character.navigator.stop()


func _move() -> int:
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    var surface_reachability := \
            SurfaceReachability.REVERSIBLY_REACHABLE if \
            only_navigates_reversible_paths else \
            SurfaceReachability.REACHABLE
    
    var destination := _get_collide_target_position()
    
    if !can_leave_start_surface and \
            destination.surface != latest_move_start_surface:
        destination = PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        destination.target_point,
                        latest_move_start_surface,
                        character.movement_params.collider,
                        true,
                        false)
    
    # Prevent straying too far the start position.
    if start_position_for_max_distance_checks.distance_squared_to(
            destination.target_point) <= \
            max_distance_squared_from_start_position:
        var is_navigation_valid := _attempt_navigation_to_destination(
                destination,
                _is_first_move_since_active)
        if is_navigation_valid:
            return BehaviorMoveResult.VALID_MOVE
    
    var original_destination := destination
    var original_distance := latest_move_start_position.distance_to(
            original_destination.target_point)
    var direction := \
            (latest_move_start_position - original_destination.target_point) / \
            original_distance
    
    # If the original destination is too far from the start position, then try
    # moving the character slightly less far from their current position.
    for ratio in [0.5, 0.25]:
        var target: Vector2 = \
                latest_move_start_position + \
                direction * ratio * original_distance
        destination = SurfaceFinder.find_closest_position_on_a_surface(
                target,
                character,
                surface_reachability)
        if !is_instance_valid(destination):
            continue
        
        # Prevent straying too far the start position.
        if start_position_for_max_distance_checks.distance_squared_to(
                destination.target_point) <= \
                max_distance_squared_from_start_position:
            var is_navigation_valid := _attempt_navigation_to_destination(
                    destination,
                    _is_first_move_since_active)
            if is_navigation_valid:
                return BehaviorMoveResult.VALID_MOVE
    
    return BehaviorMoveResult.REACHED_MAX_DISTANCE


func _update_target_edge() -> void:
    var previous_target_edge := _last_target_edge
    var previous_target_destination := _last_target_destination
    _last_target_edge = move_target.navigator.edge
    _last_target_destination = \
            move_target.navigator.path.destination if \
            move_target.navigation_state.is_currently_navigating else \
            null
    if _last_target_edge != previous_target_edge:
        _on_target_edge_change(
                _last_target_edge,
                previous_target_edge,
                _last_target_destination,
                previous_target_destination)


func _get_collide_target_position() -> PositionAlongSurface:
    if move_target.navigation_state.is_currently_navigating:
        if anticipates_target_path:
            return move_target.navigator.path.destination
        elif anticipates_target_edge:
            return move_target.navigator.edge.end_position_along_surface
    
    if move_target.surface_state.is_grabbing_surface:
        return move_target.surface_state.center_position_along_surface
    else:
        var surface_reachability := \
                SurfaceReachability.REVERSIBLY_REACHABLE if \
                only_navigates_reversible_paths else \
                SurfaceReachability.REACHABLE
        var max_distance_squared_from_start_position := \
                max_distance_from_start_position * \
                max_distance_from_start_position
        var result := SurfaceFinder.find_closest_position_on_a_surface(
                move_target.position,
                character,
                surface_reachability,
                max_distance_squared_from_start_position,
                start_position_for_max_distance_checks)
        if result != null:
            return result
        else:
            return move_target.surface_state.last_position_along_surface


func _set_anticipates_target_edge(value: bool) -> void:
    anticipates_target_edge = value
    if anticipates_target_edge:
        anticipates_target_path = false


func _set_anticipates_target_path(value: bool) -> void:
    anticipates_target_path = value
    if anticipates_target_path:
        anticipates_target_edge = false


func _set_move_target(value: Node2D) -> void:
    ._set_move_target(value)
    _update_target_edge()
