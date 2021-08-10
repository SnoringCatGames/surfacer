tool
class_name WanderBehaviorController, \
"res://addons/surfacer/assets/images/editor_icons/wander_behavior_controller.png"
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "wander"
const IS_ADDED_MANUALLY := true


## The minimum distance to travel during each navigation.
export var min_distance_per_movement := 32.0

## The maximum distance to travel during each navigation.
export var max_distance_per_movement := 512.0

## -   The probability of moving to another surface if there is another surface
##     within range, instead of just moving to another position on the current
##     surface.
## -   This is ignored is can_leave_start_surface is false.
export(float, 0.0, 1.0) var probability_of_leaving_surface_if_available := 0.5


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
    move()


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    ._on_navigation_ended(did_navigation_finish)
    
    # FIXME: ---------------------------
    # _get_pause_time()


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func move() -> void:
    var is_navigation_valid := _attempt_navigation()
    
    # FIXME: ---- Move nav success/fail logs into a parent method.
    pass


func _attempt_navigation() -> bool:
    if can_leave_start_surface and \
            _get_should_leave_surface_if_available():
        var is_navigation_valid := _attempt_inter_surface_navigation()
        if is_navigation_valid:
            return true
    
    return _attempt_intra_surface_navigation()


func _attempt_inter_surface_navigation() -> bool:
    var target_distance_unsigned := _get_movement_distance_unsigned()
    var target_distance_squared := \
            target_distance_unsigned * target_distance_unsigned
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    # Get a shuffled list of all inter-surface nodes that are reachable from
    # the player's current surface.
    var possible_destinations := []
    for origin in \
            player.graph.surfaces_to_outbound_nodes[player.start_surface]:
        Sc.utils.concat(
                possible_destinations,
                player.graph.nodes_to_nodes_to_edges[origin].keys())
    possible_destinations.shuffle()
    
    # Try to find an inter-surface node that is within range and navigable.
    for destination in possible_destinations:
        var is_within_range_of_current_movement := \
                player.position.distance_squared_to(
                        destination.target_point) < \
                        target_distance_squared
        var is_within_range_from_start_position := \
                max_distance_from_start_position < 0.0 or \
                player.start_position.distance_squared_to(
                        destination.target_point) < \
                        max_distance_squared_from_start_position
        if is_within_range_of_current_movement and \
                is_within_range_from_start_position:
            var is_navigation_valid: bool = \
                    player.navigator.navigate_to_position(destination)
            if is_navigation_valid:
                return true
    
    return false


func _attempt_intra_surface_navigation() -> bool:
    var target_distance_signed := _get_movement_distance_signed()
    
    var is_surface_horizontal: bool = \
            player.start_surface.side == SurfaceSide.FLOOR or \
            player.start_surface.side == SurfaceSide.CEILING
    
    var current_coord: float
    var min_coord: float
    var max_coord: float
    if is_surface_horizontal:
        current_coord = player.position.x
        min_coord = player.start_surface.bounding_box.position.x
        max_coord = player.start_surface.bounding_box.end.x
        if max_distance_from_start_position >= 0.0:
            min_coord = max(
                    min_coord,
                    player.start_position.x - max_distance_from_start_position)
            max_coord = min(
                    max_coord,
                    player.start_position.x + max_distance_from_start_position)
    else:
        current_coord = player.position.y
        min_coord = player.start_surface.bounding_box.position.y
        max_coord = player.start_surface.bounding_box.end.y
        if max_distance_from_start_position >= 0.0:
            min_coord = max(
                    min_coord,
                    player.start_position.y - max_distance_from_start_position)
            max_coord = min(
                    max_coord,
                    player.start_position.y + max_distance_from_start_position)
    
    var target_coord := current_coord + target_distance_signed
    target_coord = max(target_coord, min_coord)
    target_coord = min(target_coord, max_coord)
    # If we cannot move further in the chosen direction, then let's try the
    # other direction.
    if Sc.geometry.are_floats_equal_with_epsilon(
            target_coord, current_coord, 0.1):
        target_coord = current_coord - target_distance_signed
        target_coord = max(target_coord, min_coord)
        target_coord = min(target_coord, max_coord)
    
    var target := \
            Vector2(target_coord, player.start_position.y) if \
            is_surface_horizontal else \
            Vector2(player.start_position.x, target_coord)
    
    var destination := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    target,
                    player.start_surface,
                    player.movement_params.collider_half_width_height,
                    true)
    
    return player.navigator.navigate_to_position(destination)


#func _update_parameters() -> void:
#    ._update_parameters()
#
#    if _configuration_warning != "":
#        return
#
#    # FIXME: ----------------------------
#
#    _set_configuration_warning("")


func _get_movement_distance_unsigned() -> float:
    return randf() * (max_distance_per_movement - min_distance_per_movement) + \
            min_distance_per_movement


func _get_movement_distance_signed() -> float:
    var t := randf()
    t = \
            -t * 2.0 if \
            t < 0.5 else \
            (t - 0.5) * 2.0
    return t * (max_distance_per_movement - min_distance_per_movement) + \
            min_distance_per_movement


func _get_should_leave_surface_if_available() -> bool:
    return randf() < probability_of_leaving_surface_if_available
