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

## -   If true, the character may leave the starting surface in order to
##     run-away far enough.
## -   If false, the character will only run, at the furthest, to the end of the
##     starting surface.
export var can_leave_start_surface := true \
        setget _set_can_leave_start_surface

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

## -   If true, the run-away will start with the character jumping away from the
##     target.
## -   This initial jump will respect `can_leave_start_surface`, and will only
##     send the character to a position from which they can return.
export var starts_with_a_jump := false \
        setget _set_starts_with_a_jump

## -   If `starts_with_a_jump = true`, then the initial jump will use this
##     value, multiplied by the character's normal jump boost, as the starting
##     vertical speed.
export var start_jump_boost_multiplier := 1.0 \
        setget _set_start_jump_boost_multiplier

## -   If true, the collide trajectory will end with the character jumping onto
##     the destination.
export var ends_with_a_jump := false \
        setget _set_ends_with_a_jump

## -   If true, the character will return to their starting position after this
##     behavior has finished.
## -   If true, then `only_navigates_reversible_paths` must also be true.
var returns_to_character_start_position := false \
        setget _set_returns_to_character_start_position

## -   If true, after this behavior has finished, the character will return to
##     the position they were at before triggering this behavior.
## -   If true, then `only_navigates_reversible_paths` must also be true.
var returns_to_pre_behavior_position := true \
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
var uses_move_target: bool
var includes_mid_movement_pause: bool
var includes_post_movement_pause: bool
var could_return_to_start_position: bool

var character: ScaffolderCharacter
var move_target: Node2D setget _set_move_target
var latest_move_start_position: Vector2
var latest_move_start_surface: Surface
var latest_move_start_position_along_surface: PositionAlongSurface
var latest_activate_start_position: Vector2
var latest_activate_start_surface: Surface
var latest_activate_start_position_along_surface: PositionAlongSurface
var start_position_for_max_distance_checks: Vector2
var next_behavior: Behavior
var is_active := false setget _set_is_active
var _is_first_move_since_active := false

var _mid_movement_pause_timeout_id := -1
var _post_movement_pause_timeout_id := -1

var _is_ready := false
var _was_ready_called := false
var _is_ready_to_move := false
var is_enabled := false
var _was_already_ready_to_move_this_frame := false
var _configuration_warning := ""
var _property_list_addendum := []


func _init(
        behavior_name: String,
        is_added_manually: bool,
        uses_move_target: bool,
        includes_mid_movement_pause: bool,
        includes_post_movement_pause: bool,
        could_return_to_start_position: bool) -> void:
    self.behavior_name = behavior_name
    self.is_added_manually = is_added_manually
    self.uses_move_target = uses_move_target
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
    _check_ready()
    if !is_added_manually and \
            Engine.editor_hint:
        Sc.logger.error(
                ("Behavior %s should not be added to your scene " +
                "manually.") % behavior_name)


func _ready() -> void:
    _was_ready_called = true
    _update_parameters()
    _check_ready()


func _check_ready() -> void:
    if !is_instance_valid(character) or \
            !_was_ready_called or \
            _is_ready:
        return
    
    _is_ready = true
    if Engine.editor_hint:
        return
    _check_ready_to_move()


func _check_ready_to_move() -> void:
    _is_ready_to_move = \
            _is_ready and \
            is_enabled and \
            is_instance_valid(character) and \
            character._is_ready and \
            is_instance_valid(character.start_surface) and \
            is_active
    
    if _is_ready_to_move and \
            !_was_already_ready_to_move_this_frame:
        _was_already_ready_to_move_this_frame = true
        
        if !is_instance_valid(next_behavior):
            next_behavior = _get_default_next_behavior()
            assert(is_instance_valid(next_behavior))
        
        _is_first_move_since_active = true
        
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


func _on_finished() -> void:
    _clear_timeouts()
    character._on_behavior_finished(self)


func _on_error(message: String) -> void:
    Sc.logger.error(message, false)
    character._on_behavior_error(self)


func _on_reached_max_distance() -> void:
    _on_finished()


func _on_move_target_destroyed() -> void:
    character._on_behavior_move_target_destroyed(self)


func _on_navigation_ended(did_navigation_finish: bool) -> void:
    if !did_navigation_finish:
        _pause_post_movement()
    elif is_active and \
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
    var last_surface: Surface = \
            character.surface_state.last_position_along_surface.surface
    # FIXME: ----------------- 
    # - This should just be an assertion.
    # - Debug why this ever occurs.
    if last_surface != character.reachable_basis_surface and \
            last_surface != null:
        Sc.logger.warning(
                "Behavior._attempt_move: character.reachable_basis_surface " +
                "is not updated correctly")
        character._update_reachable_surfaces(last_surface)
    
    _update_start_positions(false)
    
    if uses_move_target and \
            !is_instance_valid(move_target):
        _on_move_target_destroyed()
        return
    
    var move_result := _move()
    
    _is_first_move_since_active = false
    
    match move_result:
        BehaviorMoveResult.ERROR:
            _on_error(
                    ("ERROR: Behavior._move() failed: " +
                    "behavior=%s, character=%s, position=%s") % [
                        behavior_name,
                        character.character_name,
                        Sc.utils.get_vector_string(
                                character.surface_state.center_position),
                    ])
        BehaviorMoveResult.REACHED_MAX_DISTANCE:
            character.navigator.stop()
            _on_reached_max_distance()
        BehaviorMoveResult.VALID_MOVE:
            # Do nothing.
            pass
        BehaviorMoveResult.INVALID_MOVE:
            # Abort to the default behavior.
            _on_finished()
        _:
            Sc.logger.error()


func _move() -> int:
    Sc.logger.error("Abstract Behavior._move is not implemented.")
    return BehaviorMoveResult.ERROR


func _attempt_navigation_to_destination(
        destination: PositionAlongSurface,
        possibly_includes_jump_at_start := true) -> int:
    var path := _find_path(destination, possibly_includes_jump_at_start)
    if path != null:
        var is_navigation_valid: bool = character.navigator.navigate_path(path)
        return BehaviorMoveResult.VALID_MOVE if \
                is_navigation_valid else \
                BehaviorMoveResult.ERROR
    else:
        return BehaviorMoveResult.INVALID_MOVE


func _find_path(
        destination: PositionAlongSurface,
        possibly_includes_jump_at_start: bool) -> PlatformGraphPath:
    var path: PlatformGraphPath = character.navigator.find_path(
            destination,
            only_navigates_reversible_paths)
    
    if path == null:
        # Unable to navigate to the destination.
        return null
    
    if character.is_bouncy:
        character.navigator.bouncify_path(path)
        
    else:
        if starts_with_a_jump and \
                possibly_includes_jump_at_start:
            # Try to prepend a jump to the navigation.
            character.navigator.try_to_start_path_with_a_jump(
                    path,
                    start_jump_boost_multiplier)
        
        if ends_with_a_jump:
            # Try to append a jump to the navigation.
            character.navigator.try_to_end_path_with_a_jump(path)
    
    return path


func _pause_mid_movement() -> void:
    _clear_timeouts()
    var delay := _get_mid_movement_pause_time()
    if delay > 0.0:
        _mid_movement_pause_timeout_id = Sc.time.set_timeout(
                funcref(self, "_on_mid_movement_pause_finished"),
                delay)
    else:
        _on_mid_movement_pause_finished()


func _pause_post_movement() -> void:
    _clear_timeouts()
    var delay := _get_post_movement_pause_time()
    if delay > 0.0:
        _post_movement_pause_timeout_id = Sc.time.set_timeout(
                funcref(self, "_on_post_movement_pause_finished"),
                delay)
    else:
        _on_post_movement_pause_finished()


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
    
    character._log(
            "Behav change",
            "to=%s; from=%s" % [
                behavior_name,
                character.previous_behavior.behavior_name if \
                    is_instance_valid(character.previous_behavior) else \
                    "_",
            ],
            CharacterLogType.BEHAVIOR,
            false)


func _update_parameters() -> void:
    if !_was_ready_called:
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
    if !_was_ready_called:
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
    
    var is_parent_a_character := \
            parent.is_in_group(Sc.characters.GROUP_NAME_SURFACER_CHARACTERS)
    var is_parent_a_spawn_position := parent is SpawnPosition
    if !is_parent_a_character and \
            !is_parent_a_spawn_position:
        _set_configuration_warning(
                "Must be a child of a SurfacerCharacter or SpawnPosition.")
    
    if is_parent_a_character:
        character = parent


func _update_start_positions(is_new_activation: bool) -> void:
    var basis_position_along_surface: PositionAlongSurface = \
            character.surface_state.last_position_along_surface if \
            is_instance_valid(character.surface_state \
                    .last_position_along_surface.surface) else \
            character.get_intended_position(
                    IntendedPositionType.CLOSEST_SURFACE_POSITION)
    
    if is_new_activation:
        # Update the start position and surface for this latest activation.
        latest_activate_start_position_along_surface = \
                PositionAlongSurface.new(basis_position_along_surface)
        latest_activate_start_position = \
                latest_activate_start_position_along_surface.target_point
        latest_activate_start_surface = \
                latest_activate_start_position_along_surface.surface
    else:
        # Update the start position and surface for this latest move.
        latest_move_start_position_along_surface = \
                PositionAlongSurface.new(basis_position_along_surface)
        latest_move_start_position = \
                latest_move_start_position_along_surface.target_point
        latest_move_start_surface = \
                latest_move_start_position_along_surface.surface
    
    start_position_for_max_distance_checks = \
            character.start_position if \
            max_distance_from_character_start_position >= 0.0 else \
            latest_activate_start_position


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
            _update_start_positions(true)
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


func _set_ends_with_a_jump(value: bool) -> void:
    ends_with_a_jump = value
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


func _set_move_target(value: Node2D) -> void:
    move_target = value
    assert(move_target is ScaffolderCharacter)
