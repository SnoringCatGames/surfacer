class_name PlayerPointerListener
extends Node2D


var _character
var _player_nav: PlayerNavigationBehavior
var _is_preselection_path_update_pending := false
var _throttled_update_preselection_path: FuncRef = Sc.time.throttle(
        self,
        "_update_preselection_path",
        Su.path_drag_update_throttle_interval)
var _throttled_update_preselection_beats: FuncRef = Sc.time.throttle(
        self,
        "_update_preselection_beats",
        Su.path_beat_update_throttle_interval)
var _last_pointer_drag_position := Vector2.INF
var _ignore_next_pointer_release := false


func _init(character) -> void:
    self._character = character
    self._player_nav = character.get_behavior(PlayerNavigationBehavior)
    Sc.level.touch_listener.connect(
            "single_touch_dragged", self, "_on_pointer_moved")
    Sc.level.touch_listener.connect(
            "single_touch_released", self, "_on_pointer_released")


func _process(_delta: float) -> void:
    if _last_pointer_drag_position != Vector2.INF:
        if _character.is_player_control_active:
            _throttled_update_preselection_beats.call_func()
        else:
            # Reset state.
            _last_pointer_drag_position = Vector2.INF
            Sc.slow_motion.set_slow_motion_enabled(false)
            _is_preselection_path_update_pending = false
            Sc.time.clear_throttle(_throttled_update_preselection_path)
            Sc.time.clear_throttle(_throttled_update_preselection_beats)
            _player_nav.pre_selection.clear()


func _update_preselection_path() -> void:
    _is_preselection_path_update_pending = false
    _player_nav.pre_selection.update_pointer_position(
            _last_pointer_drag_position)


func _update_preselection_beats() -> void:
    # Skip the beat update if we're already going to the whole path update.
    if !_is_preselection_path_update_pending:
        _player_nav.pre_selection.update_beats()


func _on_pointer_released(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2,
        has_corresponding_touch_down: bool) -> void:
    if _ignore_next_pointer_release:
        _ignore_next_pointer_release = false
        return
    if !_character.is_player_control_active:
        return
    _last_pointer_drag_position = Vector2.INF
    Sc.slow_motion.set_slow_motion_enabled(false)
    _is_preselection_path_update_pending = false
    Sc.time.clear_throttle(_throttled_update_preselection_path)
    Sc.time.clear_throttle(_throttled_update_preselection_beats)
    _player_nav.new_selection.update_pointer_position(pointer_level_position)
    
    var selected_surface: Surface = \
            _player_nav.new_selection.navigation_destination.surface if \
            _player_nav.new_selection.navigation_destination != null else \
            null
    var is_surface_navigable: bool = _player_nav.new_selection.path != null
    Sc.annotators.add_transient(SurfacerClickAnnotator.new(
            pointer_level_position,
            selected_surface,
            is_surface_navigable))


func _on_pointer_moved(
        pointer_screen_position: Vector2,
        pointer_level_position: Vector2,
        has_corresponding_touch_down: bool) -> void:
    if !_character.is_player_control_active:
        return
    _last_pointer_drag_position = pointer_level_position
    Sc.slow_motion.set_slow_motion_enabled(true)
    _is_preselection_path_update_pending = true
    _throttled_update_preselection_path.call_func()


func on_character_moved() -> void:
    if _last_pointer_drag_position != Vector2.INF and \
            _character.is_player_control_active:
        Sc.slow_motion.set_slow_motion_enabled(true)
        _throttled_update_preselection_path.call_func()


func on_character_player_control_activated(
        was_activated_on_touch_down: bool) -> void:
    _ignore_next_pointer_release = was_activated_on_touch_down


func get_is_drag_active() -> bool:
    return _last_pointer_drag_position != Vector2.INF
