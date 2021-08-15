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
#         -   If defined, then the next item will be executed after the character
#             finishes navigating to the given destination.
#     -   zoom
#         -   Updates the camera zoom.
#     -   time_scale
#         -   Updates the framerate (Time.time_scale).
#     -   ease_name
#         -   A String. See Utils.ease_by_name.
#     -   is_user_interaction_enabled
#         -   Toggles whether the user can interact with the game.
#     -   sound
#         -   A sound effect to play.
#     -   music
#         -   A piece of music to play.
#     -   animation
#         -   A character animation to trigger.
#     -   level_callback
#         -   The name of a function to call on the level.
#     -   level_callback_args
#         -   Arguments to pass to level_callback.

const _DEFAULT_EASE_NAME := "ease_in_out"

# Array<Dictionary>
var sequence: Array
var index := -1
var is_finished := false
var is_skippable := true
var _is_skipped := false
var character: SurfacerCharacter
var level

var _tween: ScaffolderTween

var _initial_is_previous_trajectory_shown: bool
var _initial_is_active_trajectory_shown: bool
var _initial_is_navigation_destination_shown: bool

var _initial_zoom: float
var _initial_time_scale: float
var _current_zoom_multiplier: float
var _current_time_scale: float


func _ready() -> void:
    _tween = ScaffolderTween.new()
    add_child(_tween)


func configure(
        sequence: Array,
        character: SurfacerCharacter,
        level) -> void:
    self.sequence = sequence
    self.character = character
    self.level = level


func start() -> void:
    assert(!sequence.empty())
    assert(is_instance_valid(character))
    assert(index == -1)
    assert(is_finished == false)
    
    character.navigator.connect(
            "destination_reached",
            self,
            "_execute_next_step")
    
    _initial_is_previous_trajectory_shown = \
            Su.ann_manifest.is_previous_trajectory_shown
    Su.ann_manifest.is_previous_trajectory_shown = false
    _initial_is_active_trajectory_shown = Su.ann_manifest.is_active_trajectory_shown
    Su.ann_manifest.is_active_trajectory_shown = false
    _initial_is_navigation_destination_shown = \
            Su.ann_manifest.is_navigation_destination_shown
    Su.ann_manifest.is_navigation_destination_shown = false
    
    _initial_zoom = Sc.camera_controller.zoom_factor
    _initial_time_scale = Sc.time.time_scale
    _current_zoom_multiplier = 1.0
    _current_time_scale = _initial_time_scale
    
    _execute_next_step()
    
    if !Su.is_intro_choreography_shown:
        skip()


func _on_finished() -> void:
    _tween.stop_all()
    character.navigator.disconnect(
            "destination_reached",
            self,
            "_execute_next_step")
    index = -1
    is_finished = true
    Su.ann_manifest.is_previous_trajectory_shown = \
            _initial_is_previous_trajectory_shown
    Su.ann_manifest.is_active_trajectory_shown = \
            _initial_is_active_trajectory_shown
    Su.ann_manifest.is_navigation_destination_shown = \
            _initial_is_navigation_destination_shown
    Sc.camera_controller.zoom_factor = _initial_zoom
    Sc.time.time_scale = _initial_time_scale
    emit_signal("finished")


func _execute_next_step() -> void:
    index += 1
    
    _tween.stop_all()
    
    if index >= sequence.size():
        _on_finished()
        return
    
    var step: Dictionary = sequence[index]
    
    var ease_name: String = \
            step.ease_name if \
            step.has("ease_name") else \
            _DEFAULT_EASE_NAME
    var duration: float = \
            step.duration if \
            step.has("duration") else \
            0.0
    if !Su.is_intro_choreography_shown:
        duration /= Su.skip_choreography_framerate_multiplier
    var is_step_immediate := duration == 0.0
    
    var is_tween_registered := false
    
    for key in step.keys():
        match key:
            "destination":
                var target: Vector2 = \
                        Sc.utils.get_node_in_group(step.destination) \
                                .position if \
                        step.destination is String else \
                        step.destination
                var destination := \
                        SurfaceParser.find_closest_position_on_a_surface(
                                target, character)
                var is_navigation_valid := \
                        character.navigate_as_choreographed(destination)
                assert(is_navigation_valid)
            "zoom_multiplier":
                _current_zoom_multiplier = \
                        step.zoom_multiplier if \
                        !is_inf(step.zoom_multiplier) else \
                        1.0
                var current_zoom := _initial_zoom * _current_zoom_multiplier
                if is_step_immediate:
                    Sc.camera_controller.zoom_factor = current_zoom
                else:
                    _tween.interpolate_property(
                            Sc.camera_controller,
                            "zoom_factor",
                            Sc.camera_controller.zoom_factor,
                            current_zoom,
                            duration,
                            ease_name)
                    is_tween_registered = true
            "time_scale":
                _current_time_scale = \
                        _initial_time_scale * \
                        step.time_scale
                if Su.is_intro_choreography_shown:
                    _current_time_scale *= \
                            Su.skip_choreography_framerate_multiplier
                if is_step_immediate:
                    Sc.time.time_scale = \
                            _current_time_scale
                else:
                    _tween.interpolate_property(
                            Sc.time,
                            "time_scale",
                            Sc.time.time_scale,
                            _current_time_scale,
                            duration,
                            ease_name)
                    is_tween_registered = true
            "is_user_interaction_enabled":
                Sc.gui.is_user_interaction_enabled = \
                        step.is_user_interaction_enabled
            "sound":
                Sc.audio.play_sound(step.sound)
            "music":
                Sc.audio.play_music(step.music)
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
                Sc.logger.error("Unrecognized Choreographer step key: " + key)
    
    if is_tween_registered:
        _tween.start()
    
    # Handle triggering the next step.
    if !step.has("destination"):
        if step.has("duration"):
            # Schedule the next step to happen after a delay if we didn't just
            # start any other events that would otherwise trigger the next step
            # after they complete.
            Sc.time.set_timeout(
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
    character._log(
            "Skipping choreography: %8.3fs" % Sc.time.get_play_time(),
            CharacterLogType.DEFAULT)
    _is_skipped = true
    _current_time_scale *= Su.skip_choreography_framerate_multiplier
    _tween.stop_all()
    # TODO: Consider tweening these very quickly instead of setting them
    #       immediately.
    if Sc.time.time_scale != _current_time_scale:
        Sc.time.time_scale = _current_time_scale
    var current_zoom := _initial_zoom * _current_zoom_multiplier
    if Sc.camera_controller.zoom_factor != current_zoom:
        Sc.camera_controller.zoom_factor = current_zoom
