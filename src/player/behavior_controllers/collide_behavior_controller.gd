tool
class_name CollideBehaviorController, \
"res://addons/surfacer/assets/images/editor_icons/collide_behavior_controller.png"
extends BehaviorController


# FIXME: -------------------------


const CONTROLLER_NAME := "collide"
const IS_ADDED_MANUALLY := true

# FIXME: ------------------------
## -   If true, the collide trajectory will end with the player jumping onto
##     the destination.
export var ends_with_a_jump := false

# FIXME: -----------------------
## -   If true, the player will return to their starting position after this
##     behavior controller has finished.
## -   If true, then `only_navigates_reversible_paths` must also be true.
export var returns_to_start_position := true \
        setget _set_returns_to_start_position

## The minimum amount of time to pause after the last movement, before starting
## the next behavior controller.
export var min_pause_after_movements := 0.0
## The maximum amount of time to pause after the last movement, before starting
## the next behavior controller.
export var max_pause_after_movements := 0.0

# FIXME: ---------------- Set this
var collision_target: ScaffolderPlayer

var _post_movement_pause_timeout_id := -1


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
    assert(is_instance_valid(collision_target))
    move()


#func _on_inactive() -> void:
#    ._on_inactive()


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    ._on_navigation_ended(did_navigation_finish)
    
    if is_active:
        # FIXME: LEFT OFF HERE: --------------
        # - _pause_mid_movement()
        # - Continue colliding.
        pass


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func move() -> void:
    var is_navigation_valid := _attempt_navigation()
    
    # FIXME: ---- Move nav success/fail logs into a parent method.
    pass


func on_collided() -> void:
    # FIXME: LEFT OFF HERE: -------------------------------------------------
    _pause_post_movement()
    
    if player.navigation_state.is_currently_navigating and \
            is_active:
        player.navigator.stop()


func _attempt_navigation() -> bool:
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    var destination: PositionAlongSurface = \
            collision_target.surface_state.center_position_along_surface if \
            collision_target.surface_state.is_grabbing_a_surface else \
            SurfaceParser.find_closest_position_on_a_surface(
                    collision_target.position, self)
    
    # Prevent straying too far the start position.
    if player.start_position.distance_squared_to(destination.target_point) <= \
            max_distance_squared_from_start_position:
        var is_navigation_valid: bool = \
                player.navigator.navigate_to_position(destination)
        if is_navigation_valid:
            return true
    
    var original_destination := destination
    var original_distance := \
            player.position.distance_to(original_destination.target_point)
    var direction := \
            (player.position - original_destination.target_point) / \
            original_distance
    
    # If the original destination is too far from the start position, then try
    # moving the player slightly less far from their current position.
    for ratio in [0.5, 0.25]:
        var target: Vector2 = \
                player.position + \
                direction * ratio * original_distance
        destination = SurfaceParser.find_closest_position_on_a_surface(
                target, self)
        
        # Prevent straying too far the start position.
        if player.start_position.distance_squared_to(
                destination.target_point) <= \
                max_distance_squared_from_start_position:
            var is_navigation_valid: bool = \
                    player.navigator.navigate_to_position(destination)
            if is_navigation_valid:
                return true
    
    return false


func _pause_post_movement() -> void:
    _clear_timeouts()
    _post_movement_pause_timeout_id = Sc.time.set_timeout(
            funcref(self, "_on_post_movement_pause_finished"),
            _get_post_movement_pause_time())


func _on_post_movement_pause_finished() -> void:
    assert(is_active)
    _on_finished()


func _clear_timeouts() -> void:
    ._clear_timeouts()
    Sc.time.clear_timeout(_post_movement_pause_timeout_id)


func _update_parameters() -> void:
    ._update_parameters()
    
    if _configuration_warning != "":
        return
    
    if returns_to_start_position and \
            !only_navigates_reversible_paths:
        _set_configuration_warning(
                "If returns_to_start_position is true, then " +
                "only_navigates_reversible_paths must also be true.")
        return
    
    # FIXME: ----------------------------
    
    _set_configuration_warning("")


func _get_default_next_behavior_controller() -> BehaviorController:
    return player.get_behavior_controller(ReturnBehaviorController) if \
            returns_to_start_position else \
            player.active_at_start_controller


func get_is_paused() -> bool:
    return .get_is_paused() or \
            _post_movement_pause_timeout_id > 0


# FIXME: --------------------------
func _get_post_movement_pause_time() -> float:
    return randf() * \
            (max_pause_after_movements - min_pause_after_movements) + \
            min_pause_after_movements


func _set_returns_to_start_position(value: bool) -> void:
    returns_to_start_position = value
    _update_parameters()
