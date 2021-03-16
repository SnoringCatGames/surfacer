extends Node

const MUSIC_CROSS_FADE_DURATION_SEC := 2.0
const SILENT_VOLUME_DB := -80.0

const GLOBAL_AUDIO_VOLUME_OFFSET_DB := -10.0

const _DEFAULT_SOUNDS_PATH_PREFIX := "res://assets/sounds/"
const _DEFAULT_SOUND_FILE_SUFFIX := ".wav"
const _DEFAULT_SOUNDS_BUS_INDEX := 1

const _DEFAULT_MUSIC_PATH_PREFIX := "res://assets/music/"
const _DEFAULT_MUSIC_FILE_SUFFIX := ".ogg"
const _DEFAULT_MUSIC_BUS_INDEX := 2

var _inflated_sounds_config := {}
var _inflated_music_config := {}

var _fade_out_tween: Tween
var _fade_in_tween: Tween

var _pitch_shift_effect: AudioEffectPitchShift

var _previous_music_name := ""
var _current_music_name := ""

var current_playback_speed := 1.0

var is_music_enabled := true setget _set_is_music_enabled,_get_is_music_enabled
var is_sound_effects_enabled := true setget \
        _set_is_sound_effects_enabled,_get_is_sound_effects_enabled

func _init() -> void:
    ScaffoldUtils.print("Audio._init")

func _enter_tree() -> void:
    _fade_out_tween = Tween.new()
    add_child(_fade_out_tween)
    _fade_in_tween = Tween.new()
    add_child(_fade_in_tween)
    _fade_in_tween.connect( \
            "tween_completed", \
            self, \
            "on_cross_fade_music_finished")

func register_sounds( \
        manifest: Array, \
        path_prefix = _DEFAULT_SOUNDS_PATH_PREFIX, \
        file_suffix = _DEFAULT_SOUND_FILE_SUFFIX, \
        bus_index = _DEFAULT_SOUNDS_BUS_INDEX) -> void:
    AudioServer.add_bus(bus_index)
    var bus_name := AudioServer.get_bus_name(bus_index)
    
    for config in manifest:
        assert(config.has("name"))
        assert(config.has("volume_db"))
        var player := AudioStreamPlayer.new()
        var path: String = path_prefix + config.name + file_suffix
        player.stream = load(path)
        player.bus = bus_name
        add_child(player)
        config.player = player
        _inflated_sounds_config[config.name] = config
    
    _update_volume()

func register_music( \
        manifest: Array, \
        path_prefix = _DEFAULT_MUSIC_PATH_PREFIX, \
        file_suffix = _DEFAULT_MUSIC_FILE_SUFFIX, \
        bus_index = _DEFAULT_MUSIC_BUS_INDEX) -> void:
    AudioServer.add_bus(bus_index)
    var bus_name := AudioServer.get_bus_name(bus_index)
    
    for config in manifest:
        assert(config.has("name"))
        assert(config.has("volume_db"))
        var player := AudioStreamPlayer.new()
        var path: String = path_prefix + config.name + file_suffix
        player.stream = load(path)
        player.bus = bus_name
        add_child(player)
        config.player = player
        _inflated_music_config[config.name] = config
    
    _pitch_shift_effect = AudioEffectPitchShift.new()
    AudioServer.add_bus_effect(bus_index, _pitch_shift_effect)
    
    _update_volume()

func play_sound( \
        sound_name: String, \
        deferred := false) -> void:
    if deferred:
        call_deferred("_play_sound_deferred", sound_name)
    else:
        _play_sound_deferred(sound_name)

func play_music( \
        music_name: String, \
        transitions_immediately := false, \
        deferred := false) -> void:
    if deferred:
        call_deferred( \
                "_cross_fade_music", \
                music_name, \
                transitions_immediately)
    else:
        _cross_fade_music(music_name, transitions_immediately)

func _play_sound_deferred(sound_name: String) -> void:
    _inflated_sounds_config[sound_name].player.play()

func _get_previous_music_player() -> AudioStreamPlayer:
    return _inflated_music_config[_previous_music_name].player if \
            _previous_music_name != "" else \
            null

func _get_current_music_player() -> AudioStreamPlayer:
    return _inflated_music_config[_current_music_name].player if \
            _current_music_name != "" else \
            null

func _cross_fade_music( \
        music_name: String, \
        transitions_immediately := false) -> void:
    on_cross_fade_music_finished()
    
    var previous_music_player := _get_previous_music_player()
    var current_music_player := _get_current_music_player()
    var next_music_player: AudioStreamPlayer = \
            _inflated_music_config[music_name].player
    
    if previous_music_player != null and \
            previous_music_player != current_music_player and \
            previous_music_player.playing:
        ScaffoldUtils.error( \
                "Previous music still playing when trying to play new music.")
        previous_music_player.stop()
    
    _previous_music_name = _current_music_name
    _current_music_name = music_name
    previous_music_player = current_music_player
    current_music_player = next_music_player
    
    if previous_music_player == current_music_player and \
            current_music_player.playing:
        if !_fade_in_tween.is_active():
            var loud_volume := \
                    _get_current_music_player().volume_db + \
                            GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
                    is_music_enabled else \
                    SILENT_VOLUME_DB
            current_music_player.volume_db = loud_volume
        return
    
    var transition_duration_sec := \
            0.01 if \
            transitions_immediately else \
            MUSIC_CROSS_FADE_DURATION_SEC
    
    if previous_music_player != null and \
            previous_music_player.playing:
        var previous_loud_volume := \
                _get_previous_music_player().volume_db + \
                        GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
                is_music_enabled else \
                SILENT_VOLUME_DB
        _fade_out_tween.interpolate_property( \
                previous_music_player, \
                "volume_db", \
                previous_loud_volume, \
                SILENT_VOLUME_DB, \
                transition_duration_sec, \
                Tween.TRANS_QUAD, \
                Tween.EASE_IN)
        _fade_out_tween.start()
    
    set_playback_speed(current_playback_speed)
    current_music_player.volume_db = SILENT_VOLUME_DB
    current_music_player.play()
    
    var current_loud_volume := \
            _get_current_music_player().volume_db + \
                    GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
            is_music_enabled else \
            SILENT_VOLUME_DB
    _fade_in_tween.interpolate_property( \
            current_music_player, \
            "volume_db", \
            SILENT_VOLUME_DB, \
            current_loud_volume, \
            transition_duration_sec, \
            Tween.TRANS_QUAD, \
            Tween.EASE_OUT)
    _fade_in_tween.start()

func on_cross_fade_music_finished( \
        _object = null, \
        _key = null) -> void:
    _fade_out_tween.stop_all()
    _fade_in_tween.stop_all()
    
    var previous_music_player := _get_previous_music_player()
    var current_music_player := _get_current_music_player()
    
    if previous_music_player != null and \
            previous_music_player != current_music_player:
        previous_music_player.volume_db = SILENT_VOLUME_DB
        previous_music_player.stop()
    if current_music_player != null:
        var loud_volume := \
                current_music_player.volume_db + \
                        GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
                is_music_enabled else \
                SILENT_VOLUME_DB
        current_music_player.volume_db = loud_volume

func set_playback_speed(playback_speed: float) -> void:
    current_playback_speed = playback_speed
    _get_current_music_player().pitch_scale = playback_speed
    _pitch_shift_effect.pitch_scale = 1.0 / playback_speed

func _set_is_music_enabled(enabled: bool) -> void:
    is_music_enabled = enabled
    _update_volume()

func _get_is_music_enabled() -> bool:
    return is_music_enabled

func _set_is_sound_effects_enabled(enabled: bool) -> void:
    is_sound_effects_enabled = enabled
    _update_volume()

func _get_is_sound_effects_enabled() -> bool:
    return is_sound_effects_enabled

func _update_volume() -> void:
    for config in _inflated_music_config.values():
        config.player.volume_db = \
                config.volume_db + GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
                is_music_enabled else \
                SILENT_VOLUME_DB
    
    for config in _inflated_sounds_config.values():
        config.player.volume_db = \
                config.volume_db + GLOBAL_AUDIO_VOLUME_OFFSET_DB if \
                is_sound_effects_enabled else \
                SILENT_VOLUME_DB
