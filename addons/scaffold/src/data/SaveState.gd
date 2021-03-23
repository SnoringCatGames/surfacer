extends Node
class_name SaveState

const CONFIG_FILE_PATH := "user://settings.cfg"
const SETTINGS_SECTION_KEY := "settings"
const MISCELLANEOUS_SECTION_KEY := "miscellaneous"
const HIGH_SCORES_SECTION_KEY := "high_scores"
const TOTAL_PLAYS_SECTION_KEY := "total_plays"
const ALL_SCORES_SECTION_KEY := "all_scores"
const IS_UNLOCKED_SECTION_KEY := "is_unlocked"
const VERSIONS_SECTION_KEY := "versions"

const NEW_UNLOCKED_LEVELS_KEY := "new_unlocked_levels"
const GAVE_FEEDBACK_KEY := "gave_feedback"
const SCORE_VERSION_KEY := "score_v"

var config: ConfigFile

func _init() -> void:
    print("SaveSate._init")
    _load_config()

func _load_config() -> void:
    config = ConfigFile.new()
    var status := config.load(CONFIG_FILE_PATH)
    if status != OK and \
            status != ERR_FILE_NOT_FOUND:
        Gs.utils.error("An error occurred loading game state: %s" % status)

func _save_config() -> void:
    var status := config.save(CONFIG_FILE_PATH)
    if status != OK:
        Gs.utils.error("An error occurred saving game state: %s" % status)

func set_setting( \
        setting_key: String, \
        setting_value) -> void:
    config.set_value( \
            SETTINGS_SECTION_KEY, \
            setting_key, \
            setting_value)
    _save_config()

func get_setting( \
        setting_key: String, \
        default = null):
    return _get_value( \
                    SETTINGS_SECTION_KEY, \
                    setting_key) if \
            config.has_section_key( \
                    SETTINGS_SECTION_KEY, \
                    setting_key) else \
            default

func erase_all_state() -> void:
    for section in config.get_sections():
        if config.has_section(section):
            config.erase_section(section)

func erase_all_scores() -> void:
    var sections := [
        HIGH_SCORES_SECTION_KEY,
        ALL_SCORES_SECTION_KEY,
    ]
    for section_key in sections:
        if config.has_section(section_key):
            config.erase_section(section_key)

func erase_level_state(level_id: String) -> void:
    var sections := [
        HIGH_SCORES_SECTION_KEY,
        TOTAL_PLAYS_SECTION_KEY,
        ALL_SCORES_SECTION_KEY,
    ]
    for section_key in sections:
        if config.has_section_key(section_key, level_id):
            config.erase_section_key( \
                    section_key, \
                    level_id)

func _get_value(section: String, key: String, default = null):
    if !config.has_section_key(section, key):
        config.set_value(section, key, default)
    return config.get_value(section, key, default)

func set_gave_feedback(gave_feedback: bool) -> void:
    config.set_value( \
            MISCELLANEOUS_SECTION_KEY, \
            GAVE_FEEDBACK_KEY, \
            gave_feedback)
    _save_config()

func get_gave_feedback() -> bool:
    return _get_value( \
            MISCELLANEOUS_SECTION_KEY, \
            GAVE_FEEDBACK_KEY, \
            false) as bool

func set_score_version(version: String) -> void:
    config.set_value( \
            VERSIONS_SECTION_KEY, \
            SCORE_VERSION_KEY, \
            version)
    _save_config()

func get_score_version() -> String:
    return _get_value( \
            VERSIONS_SECTION_KEY, \
            SCORE_VERSION_KEY, \
            "") as String

func set_level_version( \
        level_id: String, \
        version: String) -> void:
    config.set_value( \
            VERSIONS_SECTION_KEY, \
            level_id, \
            version)
    _save_config()

func get_level_version(level_id: String) -> String:
    return _get_value( \
            VERSIONS_SECTION_KEY, \
            level_id, \
            "") as String

func set_level_high_score( \
        level_id: String, \
        high_score: int) -> void:
    config.set_value( \
            HIGH_SCORES_SECTION_KEY, \
            level_id, \
            high_score)
    _save_config()

func get_level_high_score(level_id: String) -> int:
    return _get_value( \
            HIGH_SCORES_SECTION_KEY, \
            level_id, \
            0) as int

func set_level_total_plays( \
        level_id: String, \
        total_plays: int) -> void:
    config.set_value( \
            TOTAL_PLAYS_SECTION_KEY, \
            level_id, \
            total_plays)
    _save_config()

func get_level_total_plays(level_id: String) -> int:
    return _get_value( \
            TOTAL_PLAYS_SECTION_KEY, \
            level_id, \
            0) as int

func set_level_all_scores( \
        level_id: String, \
        level_all_scores: Array) -> void:
    config.set_value( \
            ALL_SCORES_SECTION_KEY, \
            level_id, \
            level_all_scores)
    _save_config()

func get_level_all_scores(level_id: String) -> Array:
    return _get_value( \
            ALL_SCORES_SECTION_KEY, \
            level_id, \
            []) as Array

func set_level_is_unlocked( \
        level_id: String, \
        is_unlocked: bool) -> void:
    config.set_value( \
            IS_UNLOCKED_SECTION_KEY, \
            level_id, \
            is_unlocked)
    _save_config()

func get_level_is_unlocked(level_id: String) -> bool:
    return _get_value( \
            IS_UNLOCKED_SECTION_KEY, \
            level_id, \
            false) as bool or \
            Gs.are_all_levels_unlocked

func set_new_unlocked_levels(new_unlocked_levels: Array) -> void:
    config.set_value( \
            MISCELLANEOUS_SECTION_KEY, \
            NEW_UNLOCKED_LEVELS_KEY, \
            new_unlocked_levels)
    _save_config()

func get_new_unlocked_levels() -> Array:
    return _get_value( \
            MISCELLANEOUS_SECTION_KEY, \
            NEW_UNLOCKED_LEVELS_KEY, \
            []) as Array
