class_name SlowMotionMusic
extends Node


signal music_beat(is_downbeat, beat_index, meter)
signal tick_tock_beat(is_downbeat, beat_index, meter)
signal transition_completed(is_active)

var playback_position := INF
var time_to_next_music_beat := INF
var time_to_next_tick_tock_beat := INF
var next_music_beat_index := -1
var next_tick_tock_beat_index := -1

var meter := -1
var music_beat_duration_unscaled := INF
var tick_tock_beat_duration_unscaled := INF

var _is_active := false
var _is_transition_complete := true
var _start_time_scaled := INF
var _start_playback_position := INF
var _start_music_name := ""
var _music_bpm_unscaled := INF
var _is_transition_complete_timeout_id := -1


func _init() -> void:
    Gs.audio.connect("music_changed", self, "_on_music_changed")


func _process(_delta: float) -> void:
    if _is_active and \
            Surfacer.are_beats_tracked:
        _update_beat_state()


func start(time_scale_duration: float) -> void:
    _is_active = true
    
    _start_time_scaled = Gs.time.get_scaled_play_time()
    
    if !_is_transition_complete:
        # We didn't finish transitioning out of the previous slow-motion mode.
        # Don't overwrite the music parameters we'd saved from before.
        pass
    else:
        # Update music.
        meter = Gs.audio.get_meter()
        _start_playback_position = Gs.audio.get_playback_position()
        _music_bpm_unscaled = Gs.audio.get_bpm_unscaled()
        _start_music_name = Gs.audio.get_music_name()
    
    var slow_motion_music_name: String = \
            Gs.level.get_slow_motion_music_name() if \
            is_instance_valid(Gs.level) else \
            ""
    Gs.audio.cross_fade_music(slow_motion_music_name, time_scale_duration)
    Gs.audio.is_beat_event_emission_paused = true
    
    Gs.audio.play_sound("slow_down")
    
    if Surfacer.are_beats_tracked:
        _update_beat_state()
    
    _is_transition_complete = false
    Gs.time.clear_timeout(_is_transition_complete_timeout_id)
    _is_transition_complete_timeout_id = Gs.time.set_timeout(
            funcref(self, "_on_transition_complete"),
            time_scale_duration)


func stop(time_scale_duration: float) -> void:
    _is_transition_complete = false
    Gs.time.clear_timeout(_is_transition_complete_timeout_id)
    _is_transition_complete_timeout_id = Gs.time.set_timeout(
            funcref(self, "_on_transition_complete"),
            time_scale_duration)
    
    Gs.audio.play_sound("speed_up")
    
    _is_active = false


func _on_transition_complete() -> void:
    _is_transition_complete = true
    
    if !_is_active:
        # Resume music playback at the correct position given the elapsed
        # scaled-time during slow-motion mode and the transitions into and out
        # of slow-motion mode.
        var music_name: String = \
                Gs.level.get_music_name() if \
                is_instance_valid(Gs.level) else \
                ""
        Gs.audio.cross_fade_music(music_name, 0.01)
        var slow_motion_duration_scaled := \
                Gs.time.get_scaled_play_time() - _start_time_scaled
        var playback_position := \
                _start_playback_position + slow_motion_duration_scaled
        Gs.audio.seek(playback_position)
        Gs.audio.is_beat_event_emission_paused = false
        
        _start_time_scaled = INF
        _start_playback_position = INF
        _music_bpm_unscaled = INF
        _start_music_name = ""
        meter = -1
        music_beat_duration_unscaled = INF
        tick_tock_beat_duration_unscaled = INF
        playback_position = INF
        time_to_next_music_beat = INF
        time_to_next_tick_tock_beat = INF
        next_music_beat_index = -1
        next_tick_tock_beat_index = -1
    
    emit_signal("transition_completed", _is_active)


func _update_beat_state() -> void:
    Gs.audio._update_scaled_speed()
    
    music_beat_duration_unscaled = \
            60.0 / _music_bpm_unscaled / \
            Gs.audio.playback_speed_multiplier
    tick_tock_beat_duration_unscaled = \
            music_beat_duration_unscaled / \
            Surfacer.nav_selection_slow_mo_tick_tock_tempo_multiplier
    
    var slow_motion_duration_scaled := \
            Gs.time.get_scaled_play_time() - _start_time_scaled
    playback_position = _start_playback_position + slow_motion_duration_scaled
    
    var current_music_beat_progress := \
            fmod(playback_position, music_beat_duration_unscaled)
    time_to_next_music_beat = \
            music_beat_duration_unscaled - current_music_beat_progress
    
    var previous_music_beat_index := next_music_beat_index
    next_music_beat_index = \
            int(playback_position / music_beat_duration_unscaled) + 1
    
    var current_tick_tock_beat_progress := \
            fmod(playback_position, tick_tock_beat_duration_unscaled)
    time_to_next_tick_tock_beat = \
            tick_tock_beat_duration_unscaled - current_tick_tock_beat_progress
    
    var previous_tick_tock_beat_index := next_tick_tock_beat_index
    next_tick_tock_beat_index = \
            int(playback_position / tick_tock_beat_duration_unscaled) + 1
    
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
