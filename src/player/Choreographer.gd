class_name Choreographer
extends Node

signal finished

# -   Each step is executed in sequence.
# -   These are the valid fields for the items in the choreography sequence to
#     contain:
#     -   duration
#         -   The duration of the step, in seconds.
#         -   If defined, then the included property will be interpolated from
#             its pre-existing value to its defined value over the given
#             duration.
#         -   If not defined, then the item is executed immediately.
#     -   destination
#         -   Either a **node group name** or a **Vector2**.
#         -   If a node group name is given:intro_choreographer
#             -   A single node is expected to belong to the group within the
#                 current level.
#             -   The position of this node is used as the navigation target.
#         -   Triggers navigation to the closest position-along-a-surface to
#             the given target.
#         -   If defined, then the next item will be executed after the player
#             finishes navigating to the given destination.
#     -   zoom
#         -   Updates the camera zoom.
#     -   time_scale
#         -   Updates the framerate (Time.time_scale).
#     -   trans_type
#     -   ease_type
#     -   is_user_interaction_enabled
#         -   Toggles whether the user can interact with the game.
#     -   sound
#         -   A sound effect to play.
#     -   music
#         -   A piece of music to play.
#     -   animation
#         -   A player animation to trigger.
#     -   level_callback
#         -   The name of a function to call on the level.
#     -   level_callback_args
#         -   Arguments to pass to level_callback.

const _DEFAULT_TRANS_TYPE := Tween.TRANS_QUAD
const _DEFAULT_EASE_TYPE := Tween.EASE_IN_OUT
const _SKIP_CHOREOGRAPHY_FRAMERATE_MULTIPLIER := 10.0

# Array<Dictionary>
var sequence: Array
var index := -1
var is_finished := false
var is_skippable := true
var _is_skipped := false
var player: Player
var level

var _tween: Tween

var _initial_is_previous_trajectory_shown: bool
var _initial_is_active_trajectory_shown: bool
var _initial_is_navigation_destination_shown: bool

var _initial_zoom: float
var _initial_time_scale: float
var _current_zoom: float
var _current_time_scale: float

func _enter_tree() -> void:
    _tween = Tween.new()
    add_child(_tween)

func configure(
        sequence: Array,
        player: Player,
        level) -> void:
    self.sequence = sequence
    self.player = player
    self.level = level

func start() -> void:
    assert(!sequence.empty())
    assert(is_instance_valid(player))
    assert(index == -1)
    assert(is_finished == false)
    
    player.navigator.connect(
            "reached_destination",
            self,
            "_execute_next_step")
    
    _initial_is_previous_trajectory_shown = \
            Surfacer.is_previous_trajectory_shown
    Surfacer.is_previous_trajectory_shown = false
    _initial_is_active_trajectory_shown = Surfacer.is_active_trajectory_shown
    Surfacer.is_active_trajectory_shown = false
    _initial_is_navigation_destination_shown = \
            Surfacer.is_navigation_destination_shown
    Surfacer.is_navigation_destination_shown = false
    
    _initial_zoom = Gs.camera_controller.zoom_factor
    _initial_time_scale = Gs.time.time_scale
    _current_zoom = _initial_zoom
    _current_time_scale = _initial_time_scale
    
    _execute_next_step()
    
    if !Surfacer.is_intro_choreography_shown:
        skip()

func _on_finished() -> void:
    _tween.stop_all()
    player.navigator.disconnect(
            "reached_destination",
            self,
            "_execute_next_step")
    index = -1
    is_finished = true
    Surfacer.is_previous_trajectory_shown = \
            _initial_is_previous_trajectory_shown
    Surfacer.is_active_trajectory_shown = _initial_is_active_trajectory_shown
    Surfacer.is_navigation_destination_shown = \
            _initial_is_navigation_destination_shown
    Gs.camera_controller.zoom_factor = _initial_zoom
    Gs.time.time_scale = _initial_time_scale
    emit_signal("finished")

func _execute_next_step() -> void:
    index += 1
    
    _tween.stop_all()
    
    if index >= sequence.size():
        _on_finished()
        return
    
    var step: Dictionary = sequence[index]
    
    var trans_type: int = \
            step.trans_type if \
            step.has("trans_type") else \
            _DEFAULT_TRANS_TYPE
    var ease_type: int = \
            step.ease_type if \
            step.has("ease_type") else \
            _DEFAULT_EASE_TYPE
    var duration: float = \
            step.duration if \
            step.has("duration") else \
            0.0
    if !Surfacer.is_intro_choreography_shown:
        duration /= _SKIP_CHOREOGRAPHY_FRAMERATE_MULTIPLIER
    var is_step_immediate := duration == 0.0
    
    var is_tween_registered := false
    
    for key in step.keys():
        match key:
            "destination":
                var target: Vector2 = \
                        Gs.utils.get_node_in_group(step.destination).position
                var destination := \
                        SurfaceParser.find_closest_position_on_a_surface(
                                target, player)
                var is_navigation_valid := \
                        player.navigator.navigate_to_position(destination)
                assert(is_navigation_valid)
            "zoom":
                _current_zoom = step.zoom
                if is_step_immediate:
                    Gs.camera_controller.zoom_factor = _current_zoom
                else:
                    _tween.interpolate_property(
                            Gs.camera_controller,
                            "zoom_factor",
                            Gs.camera_controller.zoom_factor,
                            _current_zoom,
                            duration,
                            trans_type,
                            ease_type)
                    is_tween_registered = true
            "time_scale":
                _current_time_scale = \
                        _initial_time_scale * \
                        step.time_scale
                if Surfacer.is_intro_choreography_shown:
                    _current_time_scale *= \
                            _SKIP_CHOREOGRAPHY_FRAMERATE_MULTIPLIER
                if is_step_immediate:
                    Gs.time.time_scale = \
                            _current_time_scale
                else:
                    _tween.interpolate_property(
                            Gs.time,
                            "time_scale",
                            Gs.time.time_scale,
                            _current_time_scale,
                            duration,
                            trans_type,
                            ease_type)
                    is_tween_registered = true
            "is_user_interaction_enabled":
                Gs.is_user_interaction_enabled = \
                        step.is_user_interaction_enabled
            "sound":
                Gs.audio.play_sound(step.sound)
            "music":
                Gs.audio.play_music(step.music)
            "animation":
                # TODO: Implement Choreographer `animation` triggers.
                pass
            "level_callback":
                if step.has("level_callback_args"):
                    level.callv(step.level_callback, step.level_callback_args)
                else:
                    level.call(step.level_callback)
            "duration", \
            "trans_type", \
            "ease_type", \
            "level_callback_args":
                # Do nothing. Handled elsewhere.
                pass
            _:
                Gs.logger.error("Unrecognized Choreographer step key: " + key)
    
    if is_tween_registered:
        _tween.start()
    
    # Handle triggering the next step.
    if !step.has("destination"):
        if step.has("duration"):
            # Schedule the next step to happen after a delay if we didn't just
            # start any other events that would otherwise trigger the next step
            # after they complete.
            Gs.time.set_timeout(
                    funcref(self, "_execute_next_step"),
                    step.duration + 0.0001,
                    [],
                    TimeType.PLAY_PHYSICS)
        else:
            _execute_next_step()

func on_interaction() -> void:
    if is_skippable:
        skip()

func skip() -> void:
    if _is_skipped:
        return
    Gs.logger.print("Skipping choreography")
    _is_skipped = true
    _current_time_scale *= _SKIP_CHOREOGRAPHY_FRAMERATE_MULTIPLIER
    _tween.stop_all()
    # TODO: Consider tweening these very quickly instead of setting them
    #       immediately.
    if Gs.time.time_scale != _current_time_scale:
        Gs.time.time_scale = _current_time_scale
    if Gs.camera_controller.zoom_factor != _current_zoom:
        Gs.camera_controller.zoom_factor
