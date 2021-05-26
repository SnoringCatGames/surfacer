class_name SlowMotionMusic
extends Node

var _start_time := -1
var _start_playback_position := 0.0
var _meter := -1
var _beat_duration := INF
var _on_beat_timeout_id := -1
var _on_beat_callback := funcref(self, "_on_beat")

func start(time_scale_duration: float) -> void:
    _start_time = Gs.time.get_scaled_play_time_sec()
    
    # Update music.
    if is_instance_valid(Gs.level):
        _meter = Gs.audio.get_meter()
        _beat_duration = \
                60.0 / Gs.audio.get_bpm() / \
                Surfacer.nav_selection_slow_mo_tick_tock_tempo_multiplier
        _start_playback_position = Gs.audio.get_playback_position()
        
        var music_name: String = Gs.level.get_slow_motion_music_name()
        Gs.audio.cross_fade_music(music_name, time_scale_duration)
        
        _on_beat_timeout_id = Gs.time.set_timeout(
                funcref(self, "_cue_beat"),
                time_scale_duration)
    
    Gs.audio.play_sound("slow_down")

func stop(time_scale_duration: float) -> void:
    # Update music.
    if is_instance_valid(Gs.level):
        var music_name: String = Gs.level.get_music_name()
        Gs.audio.cross_fade_music(music_name, time_scale_duration)
        
        var slow_motion_duration := \
                Gs.time.get_scaled_play_time_sec() - _start_time
        var playback_position := \
                _start_playback_position + slow_motion_duration
        Gs.audio.seek(playback_position)
    
    Gs.time.clear_timeout(_on_beat_timeout_id)
    
    Gs.audio.play_sound("speed_up")

func _cue_beat() -> void:
    var slow_motion_duration := \
            Gs.time.get_scaled_play_time_sec() - _start_time
    var playback_position := \
            _start_playback_position + slow_motion_duration
    
    var current_beat_progress := fmod(playback_position, _beat_duration)
    var time_to_next_beat := _beat_duration - current_beat_progress
    var next_beat_index := int(playback_position / _beat_duration) + 1
    var is_next_downbeat := next_beat_index % _meter == 0
    
    _on_beat_timeout_id = Gs.time.set_timeout(
            _on_beat_callback,
            time_to_next_beat,
            [is_next_downbeat, next_beat_index],
            TimeType.APP_PHYSICS_SCALED)

func _on_beat(
        is_downbeat: bool,
        beat_index: int) -> void:
    assert(!is_downbeat or \
            beat_index % _meter == 0)
    
    var sound_name: String
    var downbeat_index := int(beat_index / _meter)
    if downbeat_index % 2 == 0:
        sound_name = "tock_low"
    elif downbeat_index % 4 == 1:
        sound_name = "tock_high"
    else:
        sound_name = "tock_higher"
    
    var volume_offset := \
            0.0 if \
            is_downbeat else \
            -16.0
    
    Gs.audio.play_sound(sound_name, volume_offset)
    
    _cue_beat()
