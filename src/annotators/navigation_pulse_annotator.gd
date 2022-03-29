class_name NavigationPulseAnnotator
extends Node2D


var navigator: SurfaceNavigator
var color: Color
var current_path: PlatformGraphPath
var is_slow_motion_enabled := false
var current_path_start_time := -INF
var current_path_elapsed_time := INF
var current_path_pulse_duration := 0.0
var current_path_pulse_delay := 0.0
var is_enabled := false
var is_pulse_active := false
var does_pulse_grow := false


func _init(
        navigator: SurfaceNavigator,
        color: Color) -> void:
    self.navigator = navigator
    self.color = color


func _physics_process(_delta: float) -> void:
    if navigator.path != current_path:
        current_path = navigator.path
        if current_path != null:
            current_path_start_time = Sc.time.get_play_time()
            is_pulse_active = true
            current_path_pulse_delay = \
                    Su.ann_manifest.nav_path_fade_in_duration * 0.85
            current_path_pulse_duration = max(
                    Su.ann_manifest.new_path_pulse_duration,
                    current_path.duration * 0.5)
            does_pulse_grow = \
                    Su.ann_manifest.does_player_nav_pulse_grow if \
                    navigator.character.is_player_character else \
                    Su.ann_manifest.does_npc_nav_pulse_grow
        update()
    
    if Sc.slow_motion.get_is_enabled_or_transitioning() != \
            is_slow_motion_enabled:
        is_slow_motion_enabled = \
                Sc.slow_motion.get_is_enabled_or_transitioning()
        is_enabled = _get_is_pulse_enabled()
        update()
    
    if is_pulse_active:
        current_path_elapsed_time = \
                Sc.time.get_play_time() - current_path_start_time
        is_pulse_active = \
                current_path_elapsed_time < \
                current_path_pulse_duration + current_path_pulse_delay
        update()


func _draw() -> void:
    if current_path == null or \
            !is_enabled or \
            !is_pulse_active or \
            Sc.level.get_is_intro_choreography_running():
        return
    
    var progress := max(
            (current_path_elapsed_time - current_path_pulse_delay) / \
            (current_path_pulse_duration - current_path_pulse_delay),
            0.0)
    
    var opacity_multiplier := \
            1.0 - Sc.utils.ease_by_name(progress, "ease_in_strong")
    progress = Sc.utils.ease_by_name(progress, "ease_out")
    
    if progress < 0.0001 or \
            progress > 0.9999:
        return
    
    var path_segment_time_start: float
    var path_segment_time_end: float
    if does_pulse_grow:
        path_segment_time_start = 0.0
        path_segment_time_end = current_path.duration * progress
    else:
        var half_pulse_time_length: float = \
                Su.ann_manifest.new_path_pulse_time_length / 2.0
        var path_duration_with_margin: float = \
                current_path.duration + \
                Su.ann_manifest.new_path_pulse_time_length
        var path_segment_time_center := \
                path_duration_with_margin * progress - half_pulse_time_length
        path_segment_time_start = max(
                path_segment_time_center - half_pulse_time_length,
                0.0)
        path_segment_time_end = min(
                path_segment_time_center + half_pulse_time_length,
                current_path.duration)
    
    var path_color := color
    path_color.a *= opacity_multiplier
    var trim_front_end_radius := 0.0
    var trim_back_end_radius := 0.0
    
    Sc.draw.draw_path_duration_segment(
            self,
            current_path,
            path_segment_time_start,
            path_segment_time_end,
            Sc.annotators.params.navigator_pulse_stroke_width,
            path_color,
            trim_front_end_radius,
            trim_back_end_radius)


func _get_is_pulse_enabled() -> bool:
    if navigator.character.is_player_character:
        return Su.ann_manifest.is_player_nav_pulse_shown and \
                (is_slow_motion_enabled and \
                Su.ann_manifest.is_player_slow_mo_trajectory_shown or \
                !is_slow_motion_enabled and \
                Su.ann_manifest.is_player_non_slow_mo_trajectory_shown)
    else:
        return Su.ann_manifest.is_npc_nav_pulse_shown and \
                (is_slow_motion_enabled and \
                Su.ann_manifest.is_npc_slow_mo_trajectory_shown or \
                !is_slow_motion_enabled and \
                Su.ann_manifest.is_npc_non_slow_mo_trajectory_shown)
