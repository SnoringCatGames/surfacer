tool
class_name BehaviorController
extends Node2D


## -   Whether this should be the default initial behavior for the player.[br]
## -   At most one behavior should be marked `is_active_at_start = true`.[br]
export var is_active_at_start := false setget _set_is_active_at_start

var controller_name: String

var player

var is_active := false setget _set_is_active

var _is_ready := false
var _configuration_warning := ""


func _init(controller_name: String) -> void:
    self.controller_name = controller_name


func _enter_tree() -> void:
    _get_player_reference_from_parent()


func _ready() -> void:
    _is_ready = true
    if Engine.editor_hint:
        return
    if is_active_at_start:
        _set_is_active(true)


func _on_player_ready() -> void:
    pass


func _on_active() -> void:
    pass


func _on_inactive() -> void:
    pass


func _on_physics_process(delta: float) -> void:
    pass


func _on_attached_to_first_surface() -> void:
    pass


func _update_parameters() -> void:
    if !_is_ready:
        return
    
    if !Sc.utils.check_whether_sub_classes_are_tools(self):
        _set_configuration_warning(
                "Subclasses of BehaviorController must be marked as tool.")
        return
    
    _get_player_reference_from_parent()
    if _configuration_warning != "":
        return
    
    _set_configuration_warning("")


func _set_configuration_warning(value: String) -> void:
    _configuration_warning = value
    update_configuration_warning()
    property_list_changed_notify()
    if value != "" and \
            !Engine.editor_hint:
        Sc.logger.error(value)


func _get_configuration_warning() -> String:
    return _configuration_warning


func _get_player_reference_from_parent() -> void:
    if is_instance_valid(player):
        return
    
    var parent := get_parent()
    
    if !is_instance_valid(parent):
        return
    
    if !parent.is_in_group(Sc.players.GROUP_NAME_SURFACER_PLAYERS):
        _set_configuration_warning("Must define a SurfacerPlayer parent.")
    
    player = parent


func _set_is_active(value: bool) -> void:
    var was_active := is_active
    is_active = value
    if is_active != was_active:
        if is_active:
            if is_instance_valid(player.behavior_controller):
                player.behavior_controller.is_active = false
            player.behavior_controller = self
            _on_active()
        else:
            _on_inactive()
            # FIXME: ---------------------- Transition to the next BehaviorController
#            var rest_controller: BehaviorController = \
#                    player.get_behavior_controller("RestBehaviorController")
#            rest_controller.is_active = true


func _set_is_active_at_start(value: bool) -> void:
    is_active_at_start = value
    _update_parameters()
