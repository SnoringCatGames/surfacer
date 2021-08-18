tool
class_name RunAwayBehavior, \
"res://addons/surfacer/assets/images/editor_icons/run_away_behavior.png"
extends Behavior
## -   When running away, the character finds and navigates to a destination
##     that is a given distance away from a given target.


const NAME := "run_away"
const IS_ADDED_MANUALLY := true
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

## -   If this is true, the palyer wil keep re-navigating to run away from the
##     target as long as they still aren't far enough away.
## -   If this is false, the character will stop running away as soon as the
##     first run-away navigation completes.
export var keeps_running_until_far_enough_away := true \
        setget _set_keeps_running_until_far_enough_away

## -   This is the distance threshold used for
##     keeps_running_until_far_enough_away.
export var min_distance_from_target_to_stop_running := -1.0 \
        setget _set_min_distance_from_target_to_stop_running

# FIXME: ---------------------------
# - But also check whether the target destination has changed.
## -   FIXME: --
export var recomputes_nav_on_target_edge_change := true

var target_to_run_from: ScaffolderCharacter


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
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
    if !keeps_running_until_far_enough_away or \
            character.position.distance_squared_to(
                    target_to_run_from.position) >= \
            min_distance_squared_from_target_to_stop_running:
        _pause_post_movement()
    else:
        _pause_mid_movement()


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)
    
    
func _move() -> bool:
    assert(is_instance_valid(target_to_run_from))

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
    
    # -   First, try the direction away from the target.
    # -   Then, try the two perpendicular alternate directions.
    #     -   Try the upward alternate direction first.
    # -   Then, try the direction into the target.
    var away_direction := \
            target_to_run_from.position.direction_to(start_position)
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
                target_to_run_from.position + direction * run_distance
        
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
                    target_to_run_from.position.distance_squared_to(
                            naive_target)
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
                    SurfaceParser.find_closest_position_on_a_surface(
                            naive_target,
                            character,
                            surface_reachability)
        else:
            possible_destination = PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            naive_target,
                            start_surface,
                            character.movement_params \
                                    .collider_half_width_height,
                            true)
        
        # Prevent straying too far the start position.
        var is_destination_too_far_from_start_position := \
                start_position_for_max_distance_checks.distance_squared_to(
                        possible_destination.target_point) > \
                max_distance_squared_from_start_position
        
        if !is_destination_too_far_from_start_position:
            # Ensure run-away target is the right distance away.
            var actual_distance_squared := \
                    target_to_run_from.position.distance_squared_to(
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
                    return true
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
                            target_to_run_from.position.distance_to(
                                    possible_destination.target_point))
            if current_destination_distance < \
                    closest_destination_distance:
                closest_destination_distance = current_destination_distance
                closest_destination = possible_destination
        
        var is_navigation_valid := _attempt_navigation_to_destination(
                closest_destination,
                _is_first_move_since_active)
        if is_navigation_valid:
            return true
        else:
            possible_destinations.erase(closest_destination)
    
    return false


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
