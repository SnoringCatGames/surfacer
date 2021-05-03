class_name SurfacerLevelConfig
extends ScaffolderLevelConfig

func _init(are_levels_scene_based: bool).(are_levels_scene_based) -> void:
    pass

func _sanitize_level_config(config: Dictionary) -> void:
    ._sanitize_level_config(config)
    assert(config.has("player_names") and config.player_names is Array)
