class_name ScaffolderAudio
extends Node


const SFX_BUS_NAME := "SFX"
const MUSIC_BUS_NAME := "Music"

var sfx_players: Dictionary[String, AudioStreamPlayer]


func _init() -> void:
    S.log.on_global_init(self, "Audio")


func _ready() -> void:
    S.utils.ensure(
        AudioServer.get_bus_index(SFX_BUS_NAME) >= 0,
        "Scaffolder expects an audio bus of name %s." % SFX_BUS_NAME)
    S.utils.ensure(
        AudioServer.get_bus_index(MUSIC_BUS_NAME) >= 0,
        "Scaffolder expects an audio bus of name %s." % MUSIC_BUS_NAME)

    for name in S.manifest.sfxs:
        var player := AudioStreamPlayer.new()
        player.stream = S.manifest.sfxs[name]
        player.bus = SFX_BUS_NAME
        add_child(player)
        sfx_players[name] = player


func set_up() -> void:
    S.settings.property_changed.connect(_on_property_changed)
    for property_name in ["music_volume", "sfx_volume", "audio_input"]:
        var value: Variant = S.settings.get(property_name)
        _on_property_changed(property_name, value, value)


func _on_property_changed(name: String, new_value: Variant, old_value: Variant) -> void:
    match name:
        "music_volume":
            # new_value is [0,1].
            set_music_volume(linear_to_db(new_value))
        "sfx_volume":
            # new_value is [0,1].
            set_sfx_volume(linear_to_db(new_value))
        "audio_input":
            AudioServer.input_device = new_value
        _:
            # Do nothing.
            return


func set_music_volume(volume_db: float) -> void:
    var index := AudioServer.get_bus_index(MUSIC_BUS_NAME)
    if not S.utils.ensure(index >= 0):
        return
    AudioServer.set_bus_volume_db(index, volume_db)


func set_sfx_volume(volume_db: float) -> void:
    var index := AudioServer.get_bus_index(SFX_BUS_NAME)
    if not S.utils.ensure(index >= 0):
        return
    AudioServer.set_bus_volume_db(index, volume_db)


# -   Plays the SFX non-positionally.
# -   The SFXs are registered in manifest.tres.
func play_sfx(name: String) -> void:
    if not S.utils.ensure(sfx_players.has(name)):
        return
    # Asssigning the AudioStream to null in the manifest will disable the SFX.
    if is_instance_valid(sfx_players[name]):
        sfx_players[name].play()
