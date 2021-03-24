class_name SquirrelAwayLevelConfig
extends ScaffoldLevelConfig

const ARE_LEVELS_SCENE_BASED := true

const LEVELS_PATH_PREFIX := "res://src/levels/"

var level_manifest := {
#    "1": {
#        name = "Dev level 1",
#        version = "0.0.1",
#        priority = 10,
#        scene_path = LEVELS_PATH_PREFIX + "Level1.tscn",
#    },
#    "2": {
#        name = "Dev level 2",
#        version = "0.0.1",
#        priority = 20,
#        scene_path = LEVELS_PATH_PREFIX + "Level2.tscn",
#    },
#    "3": {
#        name = "Dev level 3",
#        version = "0.0.1",
#        priority = 30,
#        scene_path = LEVELS_PATH_PREFIX + "Level3.tscn",
#    },
#    "4": {
#        name = "Dev level 4",
#        version = "0.0.1",
#        priority = 40,
#        scene_path = LEVELS_PATH_PREFIX + "Level4.tscn",
#    },
#    "5": {
#        name = "Dev level 5",
#        version = "0.0.1",
#        priority = 50,
#        scene_path = LEVELS_PATH_PREFIX + "Level5.tscn",
#    },
    "6": {
        name = "Dev level 6",
        version = "0.0.1",
        priority = 60,
        scene_path = LEVELS_PATH_PREFIX + "Level6.tscn",
    },
    "7": {
        name = "Dev level 7",
        version = "0.0.1",
        priority = 70,
        scene_path = LEVELS_PATH_PREFIX + "Level7.tscn",
    },
}

func _init().(ARE_LEVELS_SCENE_BASED) -> void:
    pass

func get_level_config(level_id: String) -> Dictionary:
    return level_manifest[level_id]

func get_level_ids() -> Array:
    return level_manifest.keys()

func get_unlock_hint(level_id: String) -> String:
    # TODO
    return "Not yet unlocked" if \
            !Gs.save_state.get_level_is_unlocked(level_id) else \
            ""

func get_suggested_next_level() -> String:
    # TODO
    return get_level_ids().front()
