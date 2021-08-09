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

# FIXME: -----------------------
## -   The ideal distance to run away from the target.
## -   An attempt will be made to find a destination that is close to the
##     appropriate distance, but the actual distance could be quite different.
export var run_distance := 384.0 \
        setget _set_run_distance

var target_to_run_from: Node2D

var _destination := PositionAlongSurface.new()


func _init().(CONTROLLER_NAME, IS_ADDED_MANUALLY) -> void:
    pass


#func _on_player_ready() -> void:
#    ._on_player_ready()


#func _on_attached_to_first_surface() -> void:
#    ._on_attached_to_first_surface()


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


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
