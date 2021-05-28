class_name SlowMotionMusic
extends Node

var playback_position := INF
var time_to_next_music_beat := INF
var time_to_next_tick_tock_beat := INF
var next_music_beat_index := -1
var next_tick_tock_beat_index := -1

var meter := -1
var music_beat_duration := INF
var tick_tock_beat_duration := INF

var _is_active := false
var _start_time := INF
var _start_playback_position := INF

var _on_beat_timeout_id := -1
var _on_beat_callback := funcref(self, "_on_beat")

func _process(_delta_sec: float) -> void:
    if _is_active:
        _update_playback_state()

func start(time_scale_duration: float) -> void:
    _is_active = true
    
    _start_time = Gs.time.get_scaled_play_time_sec()
    
    # Update music.
    if is_instance_valid(Gs.level):
        meter = Gs.audio.get_meter()
        music_beat_duration = Gs.audio.get_beat_duration()
        tick_tock_beat_duration = \
                music_beat_duration / \
                Surfacer.nav_selection_slow_mo_tick_tock_tempo_multiplier
        _start_playback_position = Gs.audio.get_playback_position()
        
        var music_name: String = Gs.level.get_slow_motion_music_name()
        Gs.audio.cross_fade_music(music_name, time_scale_duration)
        
        _on_beat_timeout_id = Gs.time.set_timeout(
                funcref(self, "_cue_beat"),
                time_scale_duration)
    
    Gs.audio.play_sound("slow_down")
    
    _update_playback_state()

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
    
    _is_active = false
    _start_time = INF
    _start_playback_position = INF
    meter = -1
    music_beat_duration = INF
    tick_tock_beat_duration = INF
    playback_position = INF
    time_to_next_music_beat = INF
    time_to_next_tick_tock_beat = INF
    next_music_beat_index = -1
    next_tick_tock_beat_index = -1

func _update_playback_state() -> void:
    var slow_motion_duration := \
            Gs.time.get_scaled_play_time_sec() - _start_time
    playback_position = _start_playback_position + slow_motion_duration
    
    var current_music_beat_progress := \
            fmod(playback_position, music_beat_duration)
    time_to_next_music_beat = music_beat_duration - current_music_beat_progress
    
    next_music_beat_index = int(playback_position / music_beat_duration) + 1
    
    var current_tick_tock_beat_progress := \
            fmod(playback_position, tick_tock_beat_duration)
    time_to_next_tick_tock_beat = \
            tick_tock_beat_duration - current_tick_tock_beat_progress
    
    next_tick_tock_beat_index = \
            int(playback_position / tick_tock_beat_duration) + 1

func _cue_beat() -> void:
    _update_playback_state()
    var is_next_downbeat := next_tick_tock_beat_index % meter == 0
    _on_beat_timeout_id = Gs.time.set_timeout(
            _on_beat_callback,
            time_to_next_tick_tock_beat,
            [is_next_downbeat, next_tick_tock_beat_index],
            TimeType.APP_PHYSICS_SCALED)

func _on_beat(
        is_downbeat: bool,
        beat_index: int) -> void:
    assert(!is_downbeat or \
            beat_index % meter == 0)
    
    var sound_name: String
    var downbeat_index := int(beat_index / meter)
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
