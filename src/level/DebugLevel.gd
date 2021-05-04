tool
class_name DebugLevel
extends SurfacerLevel

func _start() -> void:
    ._start()
    
    # FIXME: Move this player creation (and readiness recording) back into
    #        Level.
    # Add the player after removing the loading screen, since the camera
    # will track the player, which makes the loading screen look offset.
    add_player(
            Surfacer.player_params[Surfacer.default_player_name] \
                    .movement_params.player_resource_path,
            Vector2.ZERO,
            true)

func _get_music_name() -> String:
    return "on_a_quest"
