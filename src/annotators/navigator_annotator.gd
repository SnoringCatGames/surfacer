class_name NavigatorAnnotator
extends Node2D


var navigator: SurfaceNavigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var previous_path_beats: Array
var current_path_beats: Array
var last_navigator_beat: PathBeatPrediction

var is_active_trajectory_shown := false
var is_previous_trajectory_shown := false
var is_destination_shown := false

var is_enabled := false
var is_slow_motion_enabled := false

var is_fade_in_progress := false
var previous_fade_progress := 0.0
var fade_progress := 0.0

var previous_path_back_end_trim_radius: float

var current_path_color: Color
var previous_path_color: Color
var indicator_fill_color: Color
var indicator_stroke_color: Color
var pulse_color: Color

var pulse_annotator: NavigationPulseAnnotator
var fade_tween: ScaffolderTween


func _init(navigator: SurfaceNavigator) -> void:
    self.navigator = navigator
    self.previous_path_back_end_trim_radius = min(
            navigator.character.movement_params.collider_half_width_height.x,
            navigator.character.movement_params.collider_half_width_height.y)
    
    var base_color: Color = navigator.character.navigation_annotation_color
    current_path_color = Sc.colors.opacify(
            base_color,
            ScaffolderColors.ALPHA_XFAINT)
    previous_path_color = Sc.colors.opacify(
            base_color,
            ScaffolderColors.ALPHA_XXFAINT)
    indicator_fill_color = Sc.colors.opacify(
            base_color,
            ScaffolderColors.ALPHA_XXFAINT)
    indicator_stroke_color = Sc.colors.opacify(
            base_color,
            ScaffolderColors.ALPHA_SLIGHTLY_FAINT)
    pulse_color = Color.from_hsv(
            base_color.h,
            0.3,
            0.99,
            0.4)
    
    self.pulse_annotator = NavigationPulseAnnotator.new(navigator, pulse_color)
    add_child(pulse_annotator)
    
    self.fade_tween = ScaffolderTween.new()
    add_child(fade_tween)


func _process(_delta: float) -> void:
    is_fade_in_progress = fade_progress != previous_fade_progress
    previous_fade_progress = fade_progress
    
    if navigator.path != current_path:
        current_path = navigator.path
        current_path_beats = navigator.path_beats
        if current_path != null:
            if is_enabled:
                _trigger_fade_in(true)
        update()
    
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        previous_path_beats = navigator.previous_path_beats
        update()
    
    if Sc.slow_motion.get_is_enabled_or_transitioning() != \
            is_slow_motion_enabled:
        is_slow_motion_enabled = \
                Sc.slow_motion.get_is_enabled_or_transitioning()
        _update_is_enabled()
        _trigger_fade_in(is_enabled)
        update()
    
    if is_fade_in_progress:
        update()
    
    # Animate beats along the path as we hit them.
    if is_active_trajectory_shown:
        var next_navigator_beat := _get_last_beat_from_navigator()
        if last_navigator_beat != next_navigator_beat:
            last_navigator_beat = next_navigator_beat
            if next_navigator_beat != null:
                _trigger_beat_hash_animation(next_navigator_beat)


func _draw() -> void:
    if !is_enabled and \
            !is_fade_in_progress:
        return
    
    if current_path != null:
        if is_active_trajectory_shown:
            _draw_current_path(current_path)
        if is_destination_shown:
            _draw_current_path_destination(current_path)
        if is_active_trajectory_shown and \
                is_destination_shown:
            _draw_current_path_origin(current_path)
    
    if previous_path != null and \
            is_previous_trajectory_shown:
        _draw_previous_path()


func _draw_current_path(current_path: PlatformGraphPath) -> void:
    var path_color := current_path_color
    path_color.a *= fade_progress
    Sc.draw.draw_path(
            self,
            current_path,
            Sc.ann_params.navigator_trajectory_stroke_width,
            current_path_color,
            Sc.ann_params.navigator_origin_indicator_radius + 
                    Sc.ann_params.navigator_trajectory_stroke_width / 2.0,
            Sc.ann_params.navigator_destination_indicator_radius + 
                    Sc.ann_params.navigator_trajectory_stroke_width / 2.0,
            true,
            false,
            true,
            false)
    
    _draw_beat_hashes(
            current_path_beats,
            path_color)


func _draw_current_path_origin(current_path: PlatformGraphPath) -> void:
    var origin_indicator_fill_color := indicator_fill_color
    origin_indicator_fill_color.a *= fade_progress
    self.draw_circle(
            current_path.origin.target_point,
            Sc.ann_params.navigator_origin_indicator_radius,
            origin_indicator_fill_color)
    var origin_indicator_stroke_color := indicator_stroke_color
    origin_indicator_stroke_color.a *= fade_progress
    Sc.draw.draw_circle_outline(
            self,
            current_path.origin.target_point,
            Sc.ann_params.navigator_origin_indicator_radius,
            origin_indicator_stroke_color,
            Sc.ann_params.navigator_indicator_stroke_width,
            4.0)


func _draw_current_path_destination(current_path: PlatformGraphPath) -> void:
    var cone_length: float = \
            Sc.ann_params.navigator_destination_indicator_length - \
            Sc.ann_params.navigator_destination_indicator_radius
    var destination_indicator_fill_color := indicator_fill_color
    destination_indicator_fill_color.a *= fade_progress
    Sc.draw.draw_destination_marker(
            self,
            current_path.destination,
            false,
            destination_indicator_fill_color,
            cone_length,
            Sc.ann_params.navigator_destination_indicator_radius,
            true,
            INF,
            4.0)
    var destination_indicator_stroke_color := indicator_stroke_color
    destination_indicator_stroke_color *= fade_progress
    Sc.draw.draw_destination_marker(
            self,
            current_path.destination,
            false,
            destination_indicator_stroke_color,
            cone_length,
            Sc.ann_params.navigator_destination_indicator_radius,
            false,
            Sc.ann_params.navigator_indicator_stroke_width,
            4.0)


func _draw_previous_path() -> void:
    Sc.draw.draw_path(
            self,
            previous_path,
            Sc.ann_params.navigator_trajectory_stroke_width,
            previous_path_color,
            0.0,
            previous_path_back_end_trim_radius,
            true,
            false,
            true,
            false)
    _draw_beat_hashes(
            previous_path_beats,
            previous_path_color)


func _draw_beat_hashes(
        beats: Array,
        color: Color) -> void:
    Sc.draw.draw_beat_hashes(
            self,
            beats,
            Sc.ann_params.navigator_trajectory_downbeat_hash_length,
            Sc.ann_params.navigator_trajectory_offbeat_hash_length,
            Sc.ann_params.navigator_trajectory_stroke_width,
            Sc.ann_params.navigator_trajectory_stroke_width,
            color,
            color)


func _update_is_enabled() -> void:
    if navigator.character.is_player_character:
        is_active_trajectory_shown = \
                is_slow_motion_enabled and \
                Su.ann_manifest.is_player_slow_mo_trajectory_shown or \
                !is_slow_motion_enabled and \
                Su.ann_manifest.is_player_non_slow_mo_trajectory_shown
        is_previous_trajectory_shown = \
                Su.ann_manifest.is_player_previous_trajectory_shown
        is_destination_shown = \
                Su.ann_manifest.is_player_navigation_destination_shown
    else:
        is_active_trajectory_shown = \
                is_slow_motion_enabled and \
                Su.ann_manifest.is_npc_slow_mo_trajectory_shown or \
                !is_slow_motion_enabled and \
                Su.ann_manifest.is_npc_non_slow_mo_trajectory_shown
        is_previous_trajectory_shown = \
                Su.ann_manifest.is_npc_previous_trajectory_shown
        is_destination_shown = \
                Su.ann_manifest.is_npc_navigation_destination_shown
    is_enabled = \
            is_active_trajectory_shown or \
            is_previous_trajectory_shown or \
            is_destination_shown


func _get_last_beat_from_navigator() -> PathBeatPrediction:
    if !navigator.navigation_state.is_currently_navigating:
        return null
    
    var current_path_time := \
            Sc.time.get_scaled_play_time() - navigator.path_start_time_scaled
    var last_beat: PathBeatPrediction = null
    for next_beat in navigator.path_beats:
        if next_beat.time > current_path_time:
            break
        last_beat = next_beat
    return last_beat


func _trigger_fade_in(is_fade_in := true) -> void:
    fade_tween.stop_all()
    fade_tween.interpolate_property(
            self,
            "fade_progress",
            0.0 if is_fade_in else 1.0,
            1.0 if is_fade_in else 0.0,
            Su.ann_manifest.nav_path_fade_in_duration,
            "ease_out",
            0.0,
            TimeType.PLAY_PHYSICS)
    fade_tween.start()


func _trigger_beat_hash_animation(beat: PathBeatPrediction) -> void:
    var beat_color := current_path_color
    beat_color.a *= fade_progress
    
    Sc.annotators.add_transient(OnBeatHashAnnotator.new(
            beat,
            Sc.ann_params.navigator_trajectory_downbeat_hash_length,
            Sc.ann_params.navigator_trajectory_offbeat_hash_length,
            Sc.ann_params.navigator_trajectory_stroke_width,
            Sc.ann_params.navigator_trajectory_stroke_width,
            beat_color,
            beat_color))
