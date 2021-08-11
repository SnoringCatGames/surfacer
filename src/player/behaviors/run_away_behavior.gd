tool
class_name RunAwayBehavior, \
"res://addons/surfacer/assets/images/editor_icons/run_away_behavior.png"
extends Behavior
## -   When running away, the player finds and navigates to a destination that
##     is a given distance away from a given target.


# FIXME: -------------------------


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

# FIXME: ---------------- Set this
var target_to_run_from: ScaffolderPlayer


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


#func _on_active() -> void:
#    ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    assert(is_instance_valid(target_to_run_from))
    _move()


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    # NOTE: This replaces the default behavior, rather than extending it.
    #._on_navigation_ended(did_navigation_finish)
    
    if is_active:
        # FIXME: LEFT OFF HERE: --------------
        # - _pause_mid_movement()
        # - _pause_post_movement()
        # - How far away are we from the target?
        pass


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)
    
    
func _move() -> bool:
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
            target_to_run_from.position.direction_to(player.position)
    var directions := [away_direction]
    if away_direction.x > 0.0:
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
    else:
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
    directions.push_back(-away_direction)
    
    var possible_destinations := []
    
    # FIXME: ---------------------------
    # - Consider starts_with_a_jump and start_jump_boost.
    # - Calculate the one-off jump onto the same surface.
    # - Then base the following navigation calculation off of the end-position
    #   of the initial jump.
    
    # FIXME: ---------------------------
    # - Consider only_navigates_reversible_paths.
    # - Use the new reachable/reverse-reachable set APIs that will be added in
    #   SurfaceNavigator.
    
    # TODO: Should we instead/also look at the distance for the resulting path?
    #       A close destination could require a long path.
    
    # Return the first possible destination that is within the correct range.
    for direction in directions:
        var naive_target: Vector2 = \
                target_to_run_from.position + direction * run_distance
        
        # Prevent straying too far the start position.
        if max_distance_from_start_position >= 0.0 and \
                player.start_position.distance_squared_to(naive_target) > \
                        max_distance_squared_from_start_position:
            naive_target = \
                    player.start_position + \
                    player.start_position.direction_to(naive_target) * \
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
            possible_destination = \
                    SurfaceParser.find_closest_position_on_a_surface(
                            naive_target, player)
        else:
            possible_destination = PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            naive_target,
                            player.start_surface,
                            player.movement_params.collider_half_width_height,
                            true)
        
        # Prevent straying too far the start position.
        var is_destination_too_far_from_start_position := \
                max_distance_from_start_position >= 0.0 and \
                player.start_position.distance_squared_to(
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
                var is_navigation_valid: bool = \
                        player.navigator.navigate_to_position(
                                possible_destination)
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
        
        var is_navigation_valid: bool = \
                player.navigator.navigate_to_position(closest_destination)
        if is_navigation_valid:
            return true
        else:
            possible_destinations.erase(closest_destination)
    
    return false


func _update_parameters() -> void:
    ._update_parameters()
    
    if _configuration_warning != "":
        return
    
    if run_distance > max_distance_from_start_position and \
            max_distance_from_start_position >= 0.0:
        _set_configuration_warning(
                "run_distance must be less than " +
                "max_distance_from_start_position.")
        return
    
    _set_configuration_warning("")


func _set_run_distance(value: float) -> void:
    run_distance = value
    _update_parameters()
