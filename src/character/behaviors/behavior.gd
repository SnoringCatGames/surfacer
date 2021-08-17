tool
class_name Behavior
extends Node2D


signal activated
signal deactivated


## -   Whether this should be the default initial behavior for the
##     character.[br]
## -   At most one behavior should be marked `is_active_at_start = true`.[br]
export var is_active_at_start := false \
        setget _set_is_active_at_start

# FIXME: -----------------------
## -   If true, the character may leave the starting surface in order to
##     run-away far enough.
## -   If false, the character will only run, at the furthest, to the end of the
##     starting surface.
export var can_leave_start_surface := true \
        setget _set_can_leave_start_surface

# FIXME: -----------------------
## -   If true, the character will not navigate to a destination if they cannot
##     afterward navigate back to their starting position.
export var only_navigates_reversible_paths := true \
        setget _set_only_navigates_reversible_paths

## -   The maximum distance from the position when this behavior started, which
##     the character will be limited to when running away.
## -   If negative, then no limit will be applied.
export var max_distance_from_behavior_start_position := -1.0 \
        setget _set_max_distance_from_behavior_start_position

## -   The maximum distance from the original character starting position, which
##     the character will be limited to when running away.
## -   If negative, then no limit will be applied.
export var max_distance_from_character_start_position := -1.0 \
        setget _set_max_distance_from_character_start_position

# This will be automatically set to match either
# max_distance_from_behavior_start_position or
# max_distance_from_character_start_position.
var max_distance_from_start_position := INF

# FIXME: -----------------------
## -   If true, the run-away will start with the character jumping away from the
##     target.
## -   This initial jump will respect `can_leave_start_surface`, and will only
##     send the character to a position from which they can return.
export var starts_with_a_jump := false \
        setget _set_starts_with_a_jump

# FIXME: -----------------------
## -   If `starts_with_a_jump = true`, then the initial jump will use this
##     value, multiplied by the character's normal jump boost, as the starting
##     vertical speed.
export var start_jump_boost_multiplier := 1.0 \
        setget _set_start_jump_boost_multiplier

## -   If true, the character will return to their starting position after this
##     behavior has finished.
## -   If true, then `only_navigates_reversible_paths` must also be true.
var returns_to_character_start_position := true \
        setget _set_returns_to_character_start_position

## -   If true, after this behavior has finished, the character will return to
##     the position they were at before triggering this behavior.
## -   If true, then `only_navigates_reversible_paths` must also be true.
var returns_to_pre_behavior_position := false \
        setget _set_returns_to_pre_behavior_position

## The minimum amount of time to pause between movements.
var min_pause_between_movements := 0.0 \
        setget _set_min_pause_between_movements
## The maximum amount of time to pause between movements.
var max_pause_between_movements := 0.0 \
        setget _set_max_pause_between_movements

## The minimum amount of time to pause after the last movement, before starting
## the next behavior.
var min_pause_after_movements := 0.0 \
        setget _set_min_pause_after_movements
## The maximum amount of time to pause after the last movement, before starting
## the next behavior.
var max_pause_after_movements := 0.0 \
        setget _set_max_pause_after_movements

var behavior_name: String
var is_added_manually: bool
var includes_mid_movement_pause: bool
var includes_post_movement_pause: bool
var could_return_to_start_position: bool

var character: ScaffolderCharacter
var start_position: Vector2
var start_surface: Surface
var start_position_along_surface: PositionAlongSurface
var start_position_for_max_distance_checks: Vector2
var next_behavior: Behavior
var is_active := false setget _set_is_active
var _reached_max_distance := false

var _mid_movement_pause_timeout_id := -1
var _post_movement_pause_timeout_id := -1

var _is_ready := false
var _is_ready_to_move := false
var _was_already_ready_to_move_this_frame := false
var _configuration_warning := ""
var _property_list_addendum := []


func _init(
        behavior_name: String,
        is_added_manually: bool,
        includes_mid_movement_pause: bool,
        includes_post_movement_pause: bool,
        could_return_to_start_position: bool) -> void:
    self.behavior_name = behavior_name
    self.is_added_manually = is_added_manually
    self.includes_mid_movement_pause = includes_mid_movement_pause
    self.includes_post_movement_pause = includes_post_movement_pause
    self.could_return_to_start_position = could_return_to_start_position
    
    if could_return_to_start_position:
        self._property_list_addendum.push_back({
                name = "returns_to_character_start_position",
                type = TYPE_BOOL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })
        self._property_list_addendum.push_back({
                name = "returns_to_pre_behavior_position",
                type = TYPE_BOOL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })
    else:
        returns_to_character_start_position = false
        returns_to_pre_behavior_position = false
    
    if includes_mid_movement_pause:
        self._property_list_addendum.push_back({
                name = "min_pause_between_movements",
                type = TYPE_REAL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })
        self._property_list_addendum.push_back({
                name = "max_pause_between_movements",
                type = TYPE_REAL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })
    
    if includes_post_movement_pause:
        self._property_list_addendum.push_back({
                name = "min_pause_after_movements",
                type = TYPE_REAL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })
        self._property_list_addendum.push_back({
                name = "max_pause_after_movements",
                type = TYPE_REAL,
                usage = Utils.PROPERTY_USAGE_EXPORTED_ITEM,
            })


func _enter_tree() -> void:
    _get_character_reference_from_parent()
    if !is_added_manually and \
            Engine.editor_hint:
        Sc.logger.error(
                ("Behavior %s should not be added to your scene " +
                "manually.") % behavior_name)


func _ready() -> void:
    _is_ready = true
    _update_parameters()
    if Engine.editor_hint:
        return
    _check_ready_to_move()


func _check_ready_to_move() -> void:
    _is_ready_to_move = \
            _is_ready and \
            character._is_ready and \
            character.start_surface != null and \
            is_active
    
    if _is_ready_to_move and \
            !_was_already_ready_to_move_this_frame:
        _was_already_ready_to_move_this_frame = true
        
        if !is_instance_valid(next_behavior):
            next_behavior = _get_default_next_behavior()
            assert(is_instance_valid(next_behavior))
        
        _on_ready_to_move()


func _on_active() -> void:
    pass


## This is called any frame any of the following is called, but only after all
## of them have been called at least once:[br]
## -   _ready[br]
## -   character._ready[br]
## -   _on_active[br]
func _on_ready_to_move() -> void:
    pass


func _on_inactive() -> void:
    pass


# FIXME: ------ Call this.
func _on_finished() -> void:
    _clear_timeouts()
    character._on_behavior_finished(self)


func _on_error(message: String) -> void:
    Sc.logger.error(message, false)
    character._on_behavior_error(self)


func _on_reached_max_distance() -> void:
    pass


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    if is_active and \
            includes_mid_movement_pause:
        _pause_mid_movement()


func _on_physics_process(delta: float) -> void:
    _was_already_ready_to_move_this_frame = false


func trigger(shows_exclamation_mark: bool) -> void:
    _clear_timeouts()
    _set_is_active(true)
    _attempt_move()
    if shows_exclamation_mark:
        character.show_exclamation_mark()


func _attempt_move() -> void:
    assert(_is_ready_to_move,
            "Behavior._attempt_move must not be called before the character " +
            "and behavior are both ready.")
    assert(character.surface_state.last_position_along_surface == \
                    character.reachable_basis_surface or \
            character.surface_state.last_position_along_surface.surface == \
                    null)
    
    # Update the start position and surface for this latest move.
    start_position_along_surface = \
            character.surface_state.last_position_along_surface if \
            character.surface_state.last_position_along_surface \
                    .surface != null else \
            character.get_intended_position(
                    IntendedPositionType.CLOSEST_SURFACE_POSITION)
    start_position = start_position_along_surface.target_point
    start_surface = start_position_along_surface.surface
    start_position_for_max_distance_checks = \
            character.start_position if \
            max_distance_from_character_start_position >= 0.0 else \
            start_position
    
    _reached_max_distance = false
    
    var is_move_successful := _move()
    if !is_move_successful:
        if _reached_max_distance:
            character.navigator.stop()
            _on_reached_max_distance()
        else:
            _on_error(
                    ("Behavior._move() failed: " +
                    "behavior=%s, character=%s, position=%s") % [
                        behavior_name,
                        character.character_name,
                        Sc.utils.get_vector_string(character.position),
                    ])


func _move() -> bool:
    Sc.logger.error("Abstract Behavior._move is not implemented.")
    return false


func _pause_mid_movement() -> void:
    _clear_timeouts()
    _mid_movement_pause_timeout_id = Sc.time.set_timeout(
            funcref(self, "_on_mid_movement_pause_finished"),
            _get_mid_movement_pause_time())


func _pause_post_movement() -> void:
    _clear_timeouts()
    _post_movement_pause_timeout_id = Sc.time.set_timeout(
            funcref(self, "_on_post_movement_pause_finished"),
            _get_post_movement_pause_time())


func _on_mid_movement_pause_finished() -> void:
    _attempt_move()


func _on_post_movement_pause_finished() -> void:
    _on_finished()


func _clear_timeouts() -> void:
    Sc.time.clear_timeout(_mid_movement_pause_timeout_id)
    _mid_movement_pause_timeout_id = -1
    Sc.time.clear_timeout(_post_movement_pause_timeout_id)
    _post_movement_pause_timeout_id = -1


func _log_transition() -> void:
    if !character.logs_behavior_events:
        return
    
    character._log("Behavior change:     %8.3fs; %s; to=%s; from=%s; pos=%s" % [
                Sc.time.get_play_time(),
                character.character_name,
                behavior_name,
                character.previous_behavior.behavior_name if \
                    is_instance_valid(character.previous_behavior) else \
                    "_",
                character.position,
            ],
            CharacterLogType.BEHAVIOR)


func _update_parameters() -> void:
    if !_is_ready:
        return
    
    if !Sc.utils.check_whether_sub_classes_are_tools(self):
        _set_configuration_warning(
                "Subclasses of Behavior must be marked as tool.")
        return
    
    _get_character_reference_from_parent()
    if _configuration_warning != "":
        return
    
    if only_navigates_reversible_paths and \
            !Su.are_reachable_surfaces_per_player_tracked:
        _set_configuration_warning(
                "If only_navigates_reversible_paths is true, then " +
                "you must configure the app manifest with " +
                "are_reachable_surfaces_per_player_tracked as true.")
        return
    
    if returns_to_character_start_position and \
            !only_navigates_reversible_paths:
        _set_configuration_warning(
                "If returns_to_character_start_position is true, then " +
                "only_navigates_reversible_paths must also be true.")
        return
    
    if returns_to_pre_behavior_position and \
            !only_navigates_reversible_paths:
        _set_configuration_warning(
                "If returns_to_pre_behavior_position is true, then " +
                "only_navigates_reversible_paths must also be true.")
        return
    
    if min_pause_between_movements < 0.0:
        _set_configuration_warning(
                "min_pause_between_movements must be non-negative.")
        return
    
    if max_pause_between_movements < 0.0:
        _set_configuration_warning(
                "max_pause_between_movements must be non-negative.")
        return
    
    if min_pause_after_movements < 0.0:
        _set_configuration_warning(
                "min_pause_after_movements must be non-negative.")
        return
    
    if max_pause_after_movements < 0.0:
        _set_configuration_warning(
                "max_pause_after_movements must be non-negative.")
        return
    
    _set_configuration_warning("")


func _set_configuration_warning(value: String) -> void:
    if !_is_ready:
        return
    _configuration_warning = value
    update_configuration_warning()
    property_list_changed_notify()
    if value != "" and \
            !Engine.editor_hint:
        Sc.logger.error(value)


func _get_configuration_warning() -> String:
    return _configuration_warning


# NOTE: _get_property_list **appends** to the default list of properties.
#       It does not replace.
func _get_property_list() -> Array:
    return _property_list_addendum


func get_is_paused() -> bool:
    return _mid_movement_pause_timeout_id > 0 or \
            _post_movement_pause_timeout_id > 0


func _get_default_next_behavior() -> Behavior:
    return character.get_behavior("return") if \
            returns_to_character_start_position or \
                    returns_to_pre_behavior_position else \
            character.default_behavior


func _get_character_reference_from_parent() -> void:
    if is_instance_valid(character):
        return
    
    var parent := get_parent()
    
    if !is_instance_valid(parent):
        return
    
    if !parent.is_in_group(Sc.characters.GROUP_NAME_SURFACER_CHARACTERS):
        _set_configuration_warning("Must define a SurfacerCharacter parent.")
    
    character = parent


func _set_is_active(value: bool) -> void:
    var was_active := is_active
    is_active = value
    if is_active != was_active:
        if is_active:
            if is_instance_valid(character.behavior) and \
                    character.behavior != self:
                character.behavior.is_active = false
            character.previous_behavior = character.behavior
            character.behavior = self
            _log_transition()
            _on_active()
            _check_ready_to_move()
            emit_signal("activated")
        else:
            _is_ready_to_move = false
            _clear_timeouts()
            _on_inactive()
            emit_signal("deactivated")


func _set_is_active_at_start(value: bool) -> void:
    is_active_at_start = value
    _update_parameters()


func _set_can_leave_start_surface(value: bool) -> void:
    can_leave_start_surface = value
    _update_parameters()


func _set_only_navigates_reversible_paths(value: bool) -> void:
    only_navigates_reversible_paths = value
    _update_parameters()


func _set_max_distance_from_behavior_start_position(value: float) -> void:
    max_distance_from_behavior_start_position = value
    if max_distance_from_behavior_start_position > 0.0:
        max_distance_from_character_start_position = -1.0
        max_distance_from_start_position = \
                max_distance_from_behavior_start_position
    else:
        max_distance_from_start_position = \
                max_distance_from_character_start_position if \
                max_distance_from_character_start_position > 0.0 else \
                INF
    _update_parameters()


func _set_max_distance_from_character_start_position(value: float) -> void:
    max_distance_from_character_start_position = value
    if max_distance_from_character_start_position > 0.0:
        max_distance_from_behavior_start_position = -1.0
        max_distance_from_start_position = \
                max_distance_from_character_start_position
    else:
        max_distance_from_start_position = \
                max_distance_from_behavior_start_position if \
                max_distance_from_behavior_start_position > 0.0 else \
                INF
    _update_parameters()


func _set_starts_with_a_jump(value: bool) -> void:
    starts_with_a_jump = value
    _update_parameters()


func _set_start_jump_boost_multiplier(value: float) -> void:
    start_jump_boost_multiplier = value
    _update_parameters()


func _set_returns_to_character_start_position(value: bool) -> void:
    returns_to_character_start_position = value
    if returns_to_character_start_position:
        returns_to_pre_behavior_position = false
    _update_parameters()


func _set_returns_to_pre_behavior_position(value: bool) -> void:
    returns_to_pre_behavior_position = value
    if returns_to_pre_behavior_position:
        returns_to_character_start_position = false
    _update_parameters()


func _set_min_pause_between_movements(value: float) -> void:
    min_pause_between_movements = value
    _update_parameters()


func _set_max_pause_between_movements(value: float) -> void:
    max_pause_between_movements = value
    _update_parameters()


func _set_min_pause_after_movements(value: float) -> void:
    min_pause_after_movements = value
    _update_parameters()


func _set_max_pause_after_movements(value: float) -> void:
    max_pause_after_movements = value
    _update_parameters()


func _get_mid_movement_pause_time() -> float:
    return randf() * \
            (max_pause_between_movements - min_pause_between_movements) + \
            min_pause_between_movements


func _get_post_movement_pause_time() -> float:
    return randf() * \
            (max_pause_after_movements - min_pause_after_movements) + \
            min_pause_after_movements
