tool
class_name RunAwayBehavior, \
"res://addons/surfacer/assets/images/editor_icons/run_away_behavior.png"
extends Behavior
## -   When running away, the character finds and navigates to a destination
##     that is a given distance away from a given target.


const NAME := "run_away"
const IS_ADDED_MANUALLY := true
const USES_MOVE_TARGET := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := true
const COULD_RETURN_TO_START_POSITION := true

## -   The ideal distance to run away from the target.
## -   An attempt will be made to find a destination that is close to the
##     appropriate distance, but the actual distance could be quite different.
export var run_distance := 384.0 \
        setget _set_run_distance

## -   A ratio of run_distance.[br]
## -   This defines the min and max acceptable distance for a run-away
##     navigation destination.
export(float, 0.0, 1.0) var retry_threshold_ratio_from_intended_distance := 0.5

## -   If this is true, the player wil keep re-navigating to run away from the
##     target as long as they still aren't far enough away.
## -   If this is false, the character will stop running away as soon as the
##     first run-away navigation completes.
export var keeps_running_until_far_enough_away := true \
        setget _set_keeps_running_until_far_enough_away

## -   This is the distance threshold used for
##     keeps_running_until_far_enough_away.
export var min_distance_from_target_to_stop_running := -1.0 \
        setget _set_min_distance_from_target_to_stop_running

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


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
    #._on_navigation_ended(did_navigation_finish)
    if !is_active:
        return
    
    var min_distance_squared_from_target_to_stop_running := \
            min_distance_from_target_to_stop_running * \
            min_distance_from_target_to_stop_running
    if !did_navigation_finish or \
            !keeps_running_until_far_enough_away or \
            character.surface_state.center_position.distance_squared_to(
                    _get_run_away_target_point()) >= \
            min_distance_squared_from_target_to_stop_running:
        _pause_post_movement()
    else:
        _pause_mid_movement()


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


func _move() -> int:
    var min_distance_retry_threshold := \
            run_distance * \
            retry_threshold_ratio_from_intended_distance
    var max_distance_retry_threshold := \
            run_distance * \
            (2.0 - retry_threshold_ratio_from_intended_distance)
    var min_distance_squared_retry_threshold := \
            min_distance_retry_threshold * min_distance_retry_threshold
    var max_distance_squared_retry_threshold := \
            max_distance_retry_threshold * max_distance_retry_threshold
    
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    var run_away_target_point := _get_run_away_target_point()
    
    # -   First, try the direction away from the target.
    # -   Then, try the two perpendicular alternate directions.
    #     -   Try the upward alternate direction first.
    # -   Then, try the direction into the target.
    var away_direction := run_away_target_point.direction_to(
            latest_move_start_position)
    var directions := [away_direction]
    if away_direction.x > 0.0:
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
    else:
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
    directions.push_back(-away_direction)
    
    var possible_destinations := []
    
    # TODO: Should we instead/also look at the distance for the resulting path?
    #       A close destination could require a long path.
    
    # Return the first possible destination that is within the correct range.
    for direction in directions:
        var naive_target: Vector2 = \
                run_away_target_point + direction * run_distance
        
        # Prevent straying too far the start position.
        if start_position_for_max_distance_checks.distance_squared_to(
                naive_target) > \
                max_distance_squared_from_start_position:
            naive_target = \
                    start_position_for_max_distance_checks + \
                    start_position_for_max_distance_checks.direction_to(
                            naive_target) * \
                    max_distance_from_start_position
            var target_distance_squared := \
                    run_away_target_point.distance_squared_to(naive_target)
            var is_target_too_far_from_intended := \
                    target_distance_squared < \
                            min_distance_squared_retry_threshold or \
                    target_distance_squared > \
                            max_distance_squared_retry_threshold
            if is_target_too_far_from_intended:
                continue
        
        var possible_destination: PositionAlongSurface
        if can_leave_start_surface:
            var surface_reachability := \
                    SurfaceReachability.REVERSIBLY_REACHABLE if \
                    only_navigates_reversible_paths else \
                    SurfaceReachability.REACHABLE
            possible_destination = \
                    SurfaceFinder.find_closest_position_on_a_surface(
                            naive_target,
                            character,
                            surface_reachability,
                            max_distance_squared_from_start_position,
                            start_position_for_max_distance_checks)
        if !is_instance_valid(possible_destination):
            possible_destination = PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            naive_target,
                            latest_move_start_surface,
                            character.movement_params.collider,
                            true,
                            false)
        
        # Ensure run-away target is the right distance away.
        var actual_distance_squared := \
                run_away_target_point.distance_squared_to(
                        possible_destination.target_point)
        var is_destination_too_far_from_intended := \
                actual_distance_squared < \
                        min_distance_squared_retry_threshold or \
                actual_distance_squared > \
                        max_distance_squared_retry_threshold
        
        if !is_destination_too_far_from_intended:
            var is_navigation_valid := _attempt_navigation_to_destination(
                    possible_destination,
                    _is_first_move_since_active)
            if is_navigation_valid:
                return BehaviorMoveResult.VALID_MOVE
        else:
            possible_destinations.push_back(possible_destination)
    
    while !possible_destinations.empty():
        # None of the destination options we considered are at the right
        # distance, so just use whichever one is closest to the right distance.
        var closest_destination: PositionAlongSurface
        var closest_destination_distance := INF
        for possible_destination in possible_destinations:
            var current_destination_distance := \
                    abs(run_distance - \
                            run_away_target_point.distance_to(
                                    possible_destination.target_point))
            if current_destination_distance < \
                    closest_destination_distance:
                closest_destination_distance = current_destination_distance
                closest_destination = possible_destination
        
        var is_navigation_valid := _attempt_navigation_to_destination(
                closest_destination,
                _is_first_move_since_active)
        if is_navigation_valid:
            return BehaviorMoveResult.VALID_MOVE
        else:
            possible_destinations.erase(closest_destination)
    
    return BehaviorMoveResult.INVALID_MOVE


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


func _get_run_away_target_point() -> Vector2:
    if move_target.navigation_state.is_currently_navigating:
        if anticipates_target_path:
            return move_target.navigator.path.destination.target_point
        elif anticipates_target_edge:
            return move_target.navigator.edge.end_position_along_surface \
                    .target_point
    return move_target.position


func _update_parameters() -> void:
    ._update_parameters()
    
    if _configuration_warning != "":
        return
    
    if run_distance > max_distance_from_start_position:
        _set_configuration_warning(
                "run_distance must be less than " +
                "max_distance_from_start_position.")
        return
    
    if keeps_running_until_far_enough_away and \
            min_distance_from_target_to_stop_running <= 0.0:
        _set_configuration_warning(
                "If keeps_running_until_far_enough_away is true, then " +
                "min_distance_from_target_to_stop_running must be greater " +
                "than zero.")
        return
    
    if min_distance_from_target_to_stop_running > \
            run_distance:
        _set_configuration_warning(
                "min_distance_from_target_to_stop_running must be less " +
                "than run_distance.")
        return
    
    _set_configuration_warning("")


func _set_run_distance(value: float) -> void:
    run_distance = value
    _update_parameters()


func _set_keeps_running_until_far_enough_away(value: bool) -> void:
    keeps_running_until_far_enough_away = value
    _update_parameters()


func _set_min_distance_from_target_to_stop_running(value: float) -> void:
    min_distance_from_target_to_stop_running = value
    if min_distance_from_target_to_stop_running >= 0.0:
        keeps_running_until_far_enough_away = true
    _update_parameters()


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
