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
#     -   framerate_multiplier
#         -   Updates the framerate (Time.physics_framerate_multiplier).
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

const _DEFAULT_TRANS_TYPE := Tween.TRANS_QUAD
const _DEFAULT_EASE_TYPE := Tween.EASE_IN_OUT

# Array<Dictionary>
var sequence: Array
var index := -1
var is_finished := false
var player: Player

var _tween: Tween

func _enter_tree() -> void:
    _tween = Tween.new()
    add_child(_tween)

func configure(
        sequence: Array,
        player: Player) -> void:
    self.sequence = sequence
    self.player = player

func start() -> void:
    assert(!sequence.empty())
    assert(is_instance_valid(player))
    assert(index == -1)
    assert(is_finished == false)
    player.navigator.connect(
            "reached_destination",
            self,
            "_execute_next_step")
    _execute_next_step()

func _on_finished() -> void:
    _tween.stop_all()
    player.navigator.disconnect(
            "reached_destination",
            self,
            "_execute_next_step")
    index = -1
    is_finished = true
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
                if step.has("duration"):
                    _tween.interpolate_property(
                            Gs.camera_controller,
                            "zoom",
                            Gs.camera_controller.zoom,
                            step.zoom,
                            step.duration,
                            trans_type,
                            ease_type)
                else:
                    Gs.camera_controller.zoom = step.zoom
            "framerate_multiplier":
                if step.has("duration"):
                    _tween.interpolate_property(
                            Gs.time,
                            "physics_framerate_multiplier",
                            Gs.time.physics_framerate_multiplier,
                            step.framerate_multiplier,
                            step.duration,
                            trans_type,
                            ease_type)
                else:
                    Gs.time.physics_framerate_multiplier = \
                            step.framerate_multiplier
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
            "duration", \
            "trans_type", \
            "ease_type":
                # Do nothing. Handled elsewhere.
                pass
            _:
                Gs.logger.error("Unrecognized Choreographer step key: " + key)
    
    _tween.start()
    
    # Handle triggering the next step.
    if !step.has("destination"):
        if step.has("duration"):
            Gs.time.set_timeout(
                    funcref(self, "_execute_next_step"),
                    step.duration + 0.0001)
        else:
            _execute_next_step()
