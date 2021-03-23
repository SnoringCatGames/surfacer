extends Node
class_name SaveState

const CONFIG_FILE_PATH := "user://settings.cfg"
const SETTINGS_SECTION_KEY := "settings"

var config: ConfigFile

func _init() -> void:
    Gs.utils.print("SaveSate._init")
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

func _get_value(section: String, key: String, default = null):
    if !config.has_section_key(section, key):
        config.set_value(section, key, default)
    return config.get_value(section, key, default)
