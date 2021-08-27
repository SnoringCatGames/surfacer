tool
class_name SurfacerLevelConfig
extends ScaffolderLevelConfig
## -   You will need to sub-class `SurfacerLevelConfig` and reference this in
##     your `app_manifest`.[br]
## -   This defines some metadata for each of the levels in your game. For
##     example:[br]
##     -   `name`: The display name for the level.[br]
##     -   `sort_priority`: The level's position relative to other levels.[br]
##     -   `unlock_conditions`: How and when the level is unlocked.[br]
##     -   `platform_graph_character_names`: The names of the characters that
##         might appear in the level. A platform graph will need to be
##         calculated for each of these characters.[br]


const INTRO_CHOREOGRAPHY_DESTINATION_GROUP_NAME := \
        "intro_choreography_destination"


func _init(
        are_levels_scene_based: bool,
        level_manifest: Dictionary).(
        are_levels_scene_based,
        level_manifest) -> void:
    pass


func _sanitize_level_config(config: Dictionary) -> void:
    ._sanitize_level_config(config)
    assert(config.has("platform_graph_character_names") and \
            config.platform_graph_character_names is Array)


func get_intro_choreographer(character: SurfacerCharacter) -> Choreographer:
    var config := get_level_config(Sc.level_session.id)
    if !config.has("intro_choreography"):
        return null
    var sequence: Array = config.intro_choreography
    var choreographer := Choreographer.new()
    choreographer.configure(sequence, character, Sc.level)
    return choreographer
