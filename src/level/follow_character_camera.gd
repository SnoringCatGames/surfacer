class_name FollowCharacterCamera
extends ScaffolderCamera


const _PAN_AND_ZOOM_INTERVAL := 0.05

var target_character: ScaffolderCharacter


func _validate() -> void:
    pass


func reset(emits_signal := true) -> void:
    .reset(emits_signal)
    if is_instance_valid(target_character):
        _misc_offset = target_character.position
    else:
        _misc_offset = Vector2.ZERO
    _update_offset_and_zoom(true, emits_signal)


func _set_is_active(value: bool) -> void:
    _sync_to_character_position()
    ._set_is_active(value)
    if value:
        assert(is_instance_valid(target_character))


func _physics_process(delta: float) -> void:
    if !_get_is_active():
        return
    _sync_to_character_position()


func _sync_to_character_position() -> void:
    var old_misc_offset := _misc_offset
    if is_instance_valid(target_character):
        _misc_offset = target_character.position
    else:
        _misc_offset = Vector2.ZERO
    if _misc_offset != old_misc_offset:
        _update_offset_and_zoom()
