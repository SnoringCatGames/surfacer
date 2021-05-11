class_name SlowMotionHandler
extends Node

const DESATURATION_SHADER := \
        preload("res://addons/surfacer/src/Desaturation.shader")

const ENABLE_SLOW_MOTION_DURATION_SEC := 0.3
const DISABLE_SLOW_MOTION_DURATION_SEC := 0.2
const DISABLE_SLOW_MOTION_CROSS_FADE_DURATION_MULTIPLIER := 1.2
const DISABLE_SLOW_MOTION_SATURATION_DURATION_MULTIPLIER := 0.9

var is_enabled := false
var _previous_playback_position := 0.0

var _slow_motion_tween: ScaffolderTween
var _desaturation_material: ShaderMaterial

func _init() -> void:
    Gs.logger.print("SlowMotionHandler._init")
    
    _slow_motion_tween = ScaffolderTween.new()
    add_child(_slow_motion_tween)
    
    _desaturation_material = ShaderMaterial.new()
    _desaturation_material.shader = DESATURATION_SHADER
    _set_saturation(1.0)

func set_slow_motion_enabled(is_enabled: bool) -> void:
    if is_enabled == self.is_enabled:
        # No change.
        return
    
    self.is_enabled = is_enabled
    
    _slow_motion_tween.stop_all()
    
    var next_time_scale: float
    var time_scale_duration: float
    var ease_name: String
    var cross_fade_duration: float
    var next_saturation: float
    var saturation_duration: float
    if is_enabled:
        next_time_scale = Surfacer.nav_selection_slow_mo_time_scale
        time_scale_duration = ENABLE_SLOW_MOTION_DURATION_SEC
        ease_name = "ease_in"
        cross_fade_duration = \
                time_scale_duration * \
                DISABLE_SLOW_MOTION_CROSS_FADE_DURATION_MULTIPLIER
        next_saturation = Surfacer.nav_selection_slow_mo_saturation
        saturation_duration = \
                time_scale_duration * \
                DISABLE_SLOW_MOTION_SATURATION_DURATION_MULTIPLIER
    else:
        next_time_scale = 1.0
        time_scale_duration = DISABLE_SLOW_MOTION_DURATION_SEC
        ease_name = "ease_out"
        cross_fade_duration = time_scale_duration
        next_saturation = 1.0
        saturation_duration = time_scale_duration
    
    # Update time scale.
    _slow_motion_tween.interpolate_method(
            self,
            "_set_time_scale",
            Gs.time.time_scale,
            next_time_scale,
            time_scale_duration,
            ease_name,
            0.0,
            TimeType.PLAY_PHYSICS)
    
    # Update desaturation.
    var desaturatables := Gs.utils.get_all_nodes_in_group(
            Surfacer.group_name_desaturatable)
    for node in desaturatables:
        node.material = _desaturation_material
    _slow_motion_tween.interpolate_method(
            self,
            "_set_saturation",
            _get_saturation(),
            next_saturation,
            saturation_duration,
            ease_name,
            0.0,
            TimeType.PLAY_PHYSICS)
    
    # Update music.
    if is_instance_valid(Gs.level):
        if is_enabled:
            _previous_playback_position = Gs.audio.get_playback_position()
        
        var music_name: String = \
                Gs.level.get_slow_motion_music_name() if \
                is_enabled else \
                Gs.level.get_music_name()
        Gs.audio.cross_fade_music(music_name, cross_fade_duration)
        
        if !is_enabled:
            Gs.audio.seek(_previous_playback_position)
    
    _slow_motion_tween.start()

func _get_saturation() -> float:
    return _desaturation_material.get_shader_param("saturation")

func _set_saturation(saturation: float) -> void:
    _desaturation_material.set_shader_param("saturation", saturation)

func _get_time_scale() -> float:
    return Gs.time.time_scale

func _set_time_scale(value: float) -> void:
    Gs.time.time_scale = value
    
    var computer_players := Gs.utils.get_all_nodes_in_group(
            Surfacer.group_name_computer_players)
    var human_players := [Surfacer.human_player]
    for players in [computer_players, human_players]:
        for player in players:
            player.animator.match_rate_to_time_scale()
