tool
class_name RunAwayBehaviorController, \
"res://addons/surfacer/assets/images/editor_icons/run_away_behavior_controller.png"
extends BehaviorController
## -   When running away, the player finds and navigates to a destination that
##     is a given distance away from a given target.


# FIXME: -------------------------


const CONTROLLER_NAME := "run_away"
const IS_ADDED_MANUALLY := true

const RETRY_THRESHOLD_RATIO_FROM_INTENDED_DISTANCE := 0.5

## -   The ideal distance to run away from the target.
## -   An attempt will be made to find a destination that is close to the
##     appropriate distance, but the actual distance could be quite different.
export var run_distance := 384.0 \
        setget _set_run_distance

var target_to_run_from: Node2D

var _destination: PositionAlongSurface


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


#func _on_player_ready() -> void:
#    ._on_player_ready()


#func _on_attached_to_first_surface() -> void:
#    ._on_attached_to_first_surface()


#func _on_active() -> void:
#    ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    
    assert(is_instance_valid(target_to_run_from))
    
    _run_away()
    
    
func _run_away() -> void:
    var is_navigation_valid := _attempt_navigation()
    
    if !is_navigation_valid:
        Sc.logger.print(
            ("RunAwayBehaviorController: Unable to navigate: " +
            "player=%s, position=%s, run_from=%s") % [
                player.player_name,
                Sc.utils.get_vector_string(player.position),
                Sc.utils.get_vector_string(target_to_run_from.position),
            ])
        # FIXME: ----------------------------- Trigger next behavior
        pass


func _on_inactive() -> void:
    ._on_inactive()
    
    if is_instance_valid(_destination):
        _destination.reset()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    ._on_navigation_ended(did_navigation_finish)
    
    # FIXME: LEFT OFF HERE: --------------
    pass


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _attempt_navigation() -> bool:
    var min_distance_retry_threshold := \
            run_distance * \
            RETRY_THRESHOLD_RATIO_FROM_INTENDED_DISTANCE
    var max_distance_retry_threshold := \
            run_distance * \
            (2.0 - RETRY_THRESHOLD_RATIO_FROM_INTENDED_DISTANCE)
    var min_distance_squared_retry_threshold := \
            min_distance_retry_threshold * min_distance_retry_threshold
    var max_distance_squared_retry_threshold := \
            max_distance_retry_threshold * max_distance_retry_threshold
    
    # -   First, try the direction away from the target.
    # -   Then, try the two perpendicular alternate directions.
    # -   Try the upward alternate direction first.
    var away_direction := \
            target_to_run_from.position.direction_to(player.position)
    var directions := [away_direction]
    if away_direction.x > 0.0:
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
    else:
        directions.push_back(Vector2(-away_direction.y, away_direction.x))
        directions.push_back(Vector2(away_direction.y, -away_direction.x))
    
    var possible_destinations := []
    
    # FIXME: ---------------------------
    # - Consider max_distance_from_start_position.
    # - 
    
    # FIXME: ---------------------------
    # - Consider can_leave_start_surface.
    # - 
    
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
        var possible_destination := \
                SurfaceParser.find_closest_position_on_a_surface(
                        naive_target, player)
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
                    player.navigator.navigate_to_position(possible_destination)
            if is_navigation_valid:
                _destination = possible_destination
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
            _destination = closest_destination
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
