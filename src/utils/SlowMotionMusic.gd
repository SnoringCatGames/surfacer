class_name SlowMotionMusic
extends Node

signal music_beat(is_downbeat, beat_index, meter)
signal tick_tock_beat(is_downbeat, beat_index, meter)

var playback_position := INF
var time_to_next_music_beat := INF
var time_to_next_tick_tock_beat := INF
var next_music_beat_index := -1
var next_tick_tock_beat_index := -1

var meter := -1
var music_beat_duration := INF
var tick_tock_beat_duration := INF

var _is_active := false
var _is_transition_complete := false
var _start_time := INF
var _start_playback_position := INF
var _is_transition_complete_timeout_id := -1

func _init() -> void:
    Gs.audio.connect("music_changed", self, "_on_music_changed")

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
        
        _is_transition_complete = false
        _is_transition_complete_timeout_id = Gs.time.set_timeout(
                funcref(self, "set"),
                time_scale_duration,
                ["_is_transition_complete", true])
    
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
    
    Gs.time.clear_timeout(_is_transition_complete_timeout_id)
    
    Gs.audio.play_sound("speed_up")
    
    _is_active = false
    _is_transition_complete = false
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
    
    var previous_music_beat_index := next_music_beat_index
    next_music_beat_index = int(playback_position / music_beat_duration) + 1
    
    var current_tick_tock_beat_progress := \
            fmod(playback_position, tick_tock_beat_duration)
    time_to_next_tick_tock_beat = \
            tick_tock_beat_duration - current_tick_tock_beat_progress
    
    var previous_tick_tock_beat_index := next_tick_tock_beat_index
    next_tick_tock_beat_index = \
            int(playback_position / tick_tock_beat_duration) + 1
    
    if _is_transition_complete:
        if previous_music_beat_index != next_music_beat_index:
            var is_downbeat := (next_music_beat_index - 1) % meter == 0
            emit_signal(
                    "music_beat",
                    is_downbeat,
                    next_music_beat_index - 1,
                    meter)
        
        if previous_tick_tock_beat_index != next_tick_tock_beat_index:
            var is_downbeat := (next_tick_tock_beat_index - 1) % meter == 0
            _on_tick_tock_beat(is_downbeat, next_tick_tock_beat_index - 1)
            emit_signal(
                    "tick_tock_beat",
                    is_downbeat,
                    next_tick_tock_beat_index - 1,
                    meter)

func _on_tick_tock_beat(
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

func _on_music_changed(music_name: String) -> void:
    # Changing the music while slow-motion is active isn't supported.
    assert(music_name == "" or \
            !Surfacer.slow_motion.is_enabled)
