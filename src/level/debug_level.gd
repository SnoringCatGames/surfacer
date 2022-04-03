tool
class_name DebugLevel
extends SurfacerLevel


func _start() -> void:
    ._start()
    
    assert(Sc.characters.default_player_character_name != "")
    
    # FIXME: Move this character creation (and readiness recording) back into
    #        Level.
    # Add the character after removing the loading screen, since the camera
    # will track the character, which makes the loading screen look offset.
    add_character(
            Sc.characters.default_player_character_name,
            Vector2.ZERO,
            true,
            true)


func get_music_name() -> String:
    return "on_a_quest"
