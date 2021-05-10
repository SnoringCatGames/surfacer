class_name SlowMotionHandler
extends Node

const ENABLE_SLOW_MOTION_DURATION_SEC := 0.3
const DISABLE_SLOW_MOTION_DURATION_SEC := 0.2

var is_slow_motion_enabled := false
var _previous_playback_position := 0.0

var _slow_motion_tween: ScaffolderTween

func _init() -> void:
    Gs.logger.print("SlowMotionHandler._init")
    _slow_motion_tween = ScaffolderTween.new()
    add_child(_slow_motion_tween)

func set_slow_motion_enabled(is_enabled: bool) -> void:
    if is_enabled == is_slow_motion_enabled:
        # No change.
        return
    
    is_slow_motion_enabled = is_enabled
    
    var next_time_scale: float
    var duration: float
    var ease_name: String
    if is_slow_motion_enabled:
        next_time_scale = Surfacer.nav_selection_slowmo_time_scale
        duration = ENABLE_SLOW_MOTION_DURATION_SEC
        ease_name = "ease_in"
    else:
        next_time_scale = 1.0
        duration = DISABLE_SLOW_MOTION_DURATION_SEC
        ease_name = "ease_out"
    
    # Update time scale.
    _slow_motion_tween.stop_all()
    _slow_motion_tween.interpolate_property(
            Gs.time,
            "time_scale",
            Gs.time.time_scale,
            next_time_scale,
            duration,
            ease_name,
            0.0,
            TimeType.PLAY_PHYSICS_SCALED)
    _slow_motion_tween.start()
    
    # Update music.
    if is_instance_valid(Gs.level):
        if is_slow_motion_enabled:
            _previous_playback_position = Gs.audio.get_playback_position()
        
        var cross_fade_duration := \
                duration * 2.0 if \
                is_slow_motion_enabled else \
                duration
        
        var music_name: String = \
                Gs.level.get_slow_motion_music_name() if \
                is_slow_motion_enabled else \
                Gs.level.get_music_name()
        Gs.audio.cross_fade_music(music_name, cross_fade_duration)
        
        if !is_slow_motion_enabled:
            Gs.audio.seek(_previous_playback_position)
