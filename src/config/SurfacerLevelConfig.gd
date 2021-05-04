class_name SurfacerLevelConfig
extends ScaffolderLevelConfig

const PLAYER_START_POSITION_GROUP_NAME := "player_start_position"
const INTRO_CHOREOGRAPHY_DESTINATION_GROUP_NAME := \
        "intro_choreography_destination"

func _init(are_levels_scene_based: bool).(are_levels_scene_based) -> void:
    pass

func _sanitize_level_config(config: Dictionary) -> void:
    ._sanitize_level_config(config)
    assert(config.has("player_names") and config.player_names is Array)

func get_intro_choreographer(player: Player) -> Choreographer:
    var config := get_level_config(Gs.level.id)
    
    var sequence: Array
    if config.has("intro_choreography"):
        # Use the pre-configured intro choreography.
        sequence = config.intro_choreography
    else:
        # Just navigate to the closest surface position to the player-start
        # position.
        sequence = [
            {
                is_user_interaction_enabled = false,
                destination = player.position,
            },
            {
                is_user_interaction_enabled = true,
            },
        ]
    
    var choreographer := Choreographer.new()
    choreographer.configure(sequence, player)
    return choreographer
