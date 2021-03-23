extends Node
class_name SquirrelAwayLevelConfig

var level_manifest := {
    "1": {
        version = "0.0.1",
        priority = 1,
    },
}

func get_level_config(level_id: String) -> Dictionary:
    return level_manifest[level_id]

func get_level_ids() -> Array:
    return level_manifest.keys()

func get_unlock_hint(level_id: String) -> String:
    # TODO
    return "Not yet unlocked" if \
            !SaveState.get_level_is_unlocked(level_id) else \
            ""

func get_suggested_next_level() -> String:
    # TODO
    return get_level_ids().front()
