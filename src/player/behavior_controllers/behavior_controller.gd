tool
class_name BehaviorController
extends Node2D


signal finished

## -   Whether this should be the default initial behavior for the player.[br]
## -   At most one behavior should be marked `is_active_at_start = true`.[br]
export var is_active_at_start := false \
        setget _set_is_active_at_start

# FIXME: -----------------------
## -   If true, the player may leave the starting surface in order to run-away
##     far enough.
## -   If false, the player will only run, at the furthest, to the end of the
##     starting surface.
export var can_leave_start_surface := true \
        setget _set_can_leave_start_surface

# FIXME: -----------------------
## -   If true, the player will return to their starting position after the
##     run-away period has finished.
## -   If true, then `only_navigates_reversible_paths` must also be true.
export var returns_to_start_position := true \
        setget _set_returns_to_start_position

# FIXME: -----------------------
## -   If true, the player will not navigate to a destination if they cannot
##     afterward navigate back to their starting position.
export var only_navigates_reversible_paths := true \
        setget _set_only_navigates_reversible_paths

# FIXME: -----------------------
## -   The maximum distance from the starting position, which the player will
##     be limited to when running away.
## -   If negative, then no limit will be applied.
export var max_distance_from_start_position := -1.0 \
        setget _set_max_distance_from_start_position

# FIXME: -----------------------
## -   If true, the run-away will start with the player jumping away from the
##     target.
## -   This initial jump will respect `can_leave_start_surface`, and will only
##     send the player to a position from which they can return.
export var starts_with_a_jump := false \
        setget _set_starts_with_a_jump

# FIXME: -----------------------
## -   If `starts_with_a_jump = true`, then the initial jump will use this
##     value as the starting vertical speed.
export var start_jump_boost := 0.0 \
        setget _set_start_jump_boost

var controller_name: String
var is_added_manually: bool

var player

var is_active := false setget _set_is_active

var _is_ready := false
var _was_already_ready_to_move_this_frame := false
var _configuration_warning := ""


func _init(
        controller_name: String,
        is_added_manually: bool) -> void:
    self.controller_name = controller_name
    self.is_added_manually = is_added_manually


func _enter_tree() -> void:
    _get_player_reference_from_parent()
    if !is_added_manually and \
            Engine.editor_hint:
        Sc.logger.error(
                ("BehaviorController %s should not be added to your scene " +
                "manually.") % controller_name)


func _ready() -> void:
    _is_ready = true
    if Engine.editor_hint:
        return
    if is_active_at_start:
        _set_is_active(true)
    _check_ready_to_move()


# FIXME: -------- REMOVE?
func _on_player_ready() -> void:
    _check_ready_to_move()


func _on_attached_to_first_surface() -> void:
    _check_ready_to_move()


func _check_ready_to_move() -> void:
    if _is_ready and \
            player._is_ready and \
            player.start_surface != null and \
            is_active and \
            !_was_already_ready_to_move_this_frame:
        _was_already_ready_to_move_this_frame = true
        _on_ready_to_move()


func _on_active() -> void:
    pass


## This is called any frame any of the following is called, but only after all
## of them have been called at least once:[br]
## -   _ready[br]
## -   _on_player_ready[br]
## -   _on_attached_to_first_surface[br]
## -   _on_active[br]
func _on_ready_to_move() -> void:
    pass


func _on_inactive() -> void:
    pass


func _on_physics_process(delta: float) -> void:
    _was_already_ready_to_move_this_frame = false


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
    
    if returns_to_start_position and \
            !only_navigates_reversible_paths:
        _set_configuration_warning(
                "If returns_to_start_position is true, then " +
                "only_navigates_reversible_paths must also be true.")
        return
    
    if start_jump_boost < 0.0:
        _set_configuration_warning("start_jump_boost must be non-negative.")
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
            _check_ready_to_move()
        else:
            _on_inactive()
            # FIXME: ---------------------- Transition to the next BehaviorController
#            var rest_controller: BehaviorController = \
#                    player.get_behavior_controller("rest")
#            rest_controller.is_active = true


func _set_is_active_at_start(value: bool) -> void:
    is_active_at_start = value
    _update_parameters()


func _set_can_leave_start_surface(value: bool) -> void:
    can_leave_start_surface = value
    _update_parameters()


func _set_returns_to_start_position(value: bool) -> void:
    returns_to_start_position = value
    _update_parameters()


func _set_only_navigates_reversible_paths(value: bool) -> void:
    only_navigates_reversible_paths = value
    _update_parameters()


func _set_max_distance_from_start_position(value: float) -> void:
    max_distance_from_start_position = value
    _update_parameters()


func _set_starts_with_a_jump(value: bool) -> void:
    starts_with_a_jump = value
    _update_parameters()


func _set_start_jump_boost(value: float) -> void:
    start_jump_boost = value
    _update_parameters()
