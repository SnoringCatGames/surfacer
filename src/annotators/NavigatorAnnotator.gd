class_name NavigatorAnnotator
extends Node2D


var FADE_IN_DURATION := 0.2

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var previous_path_beats: Array
var current_path_beats: Array
var last_navigator_beat: PathBeatPrediction
var is_enabled := false
var is_slow_motion_enabled := false

var is_fade_in_progress := false
var previous_fade_progress := 0.0
var fade_progress := 0.0

var previous_path_back_end_trim_radius: float

var pulse_annotator: NavigationPulseAnnotator
var fade_tween: ScaffolderTween


func _init(navigator: Navigator) -> void:
    self.navigator = navigator
    self.previous_path_back_end_trim_radius = min(
            navigator.player.movement_params.collider_half_width_height.x,
            navigator.player.movement_params.collider_half_width_height.y)
    
    self.pulse_annotator = NavigationPulseAnnotator.new(navigator)
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
            if _get_is_exclamation_mark_shown():
                Surfacer.annotators.add_transient(
                        NewNavExclamationMarkAnnotator.new(
                                navigator.player))
            if is_enabled:
                _trigger_fade_in(true)
        update()
    
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        previous_path_beats = navigator.previous_path_beats
        update()
    
    if Surfacer.slow_motion.get_is_enabled_or_transitioning() != \
            is_slow_motion_enabled:
        is_slow_motion_enabled = \
                Surfacer.slow_motion.get_is_enabled_or_transitioning()
        is_enabled = _get_is_enabled()
        _trigger_fade_in(is_enabled)
        update()
    
    if is_fade_in_progress:
        update()
    
    # Animate beats along the path as we hit them.
    if is_enabled:
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
        _draw_current_path(current_path)
    
    elif previous_path != null and \
            Surfacer.is_previous_trajectory_shown and \
            navigator.player.is_human_player:
        _draw_previous_path()


func _draw_current_path(current_path: PlatformGraphPath) -> void:
    if Surfacer.is_active_trajectory_shown:
        var current_path_color: Color = \
                Surfacer.ann_defaults \
                        .HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults.COMPUTER_NAVIGATOR_CURRENT_PATH_COLOR
        current_path_color.a *= fade_progress
        Gs.draw_utils.draw_path(
                self,
                current_path,
                AnnotationElementDefaults \
                        .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
                current_path_color,
                AnnotationElementDefaults \
                        .NAVIGATOR_ORIGIN_INDICATOR_RADIUS + 
                        AnnotationElementDefaults \
                            .NAVIGATOR_TRAJECTORY_STROKE_WIDTH / 2.0,
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS + 
                        AnnotationElementDefaults \
                            .NAVIGATOR_TRAJECTORY_STROKE_WIDTH / 2.0,
                true,
                false,
                true,
                false)
        
        _draw_beat_hashes(
                current_path_beats,
                current_path_color)
        
        # Draw the origin indicator.
        var origin_indicator_fill_color: Color = \
                Surfacer.ann_defaults \
                        .HUMAN_NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults \
                        .COMPUTER_NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR
        origin_indicator_fill_color.a *= fade_progress
        self.draw_circle(
                current_path.origin.target_point,
                AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                origin_indicator_fill_color)
        var origin_indicator_stroke_color: Color = \
                Surfacer.ann_defaults \
                        .HUMAN_NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults \
                        .COMPUTER_NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR
        origin_indicator_stroke_color.a *= fade_progress
        Gs.draw_utils.draw_circle_outline(
                self,
                current_path.origin.target_point,
                AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS,
                origin_indicator_stroke_color,
                AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH,
                4.0)
    
    if Surfacer.is_navigation_destination_shown:
        # Draw the destination indicator.
        var cone_length: float = \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATIAN_INDICATOR_LENGTH - \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS
        var destination_indicator_fill_color: Color = \
                Surfacer.ann_defaults \
                        .HUMAN_NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults \
                        .COMPUTER_NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR
        destination_indicator_fill_color.a *= fade_progress
        Gs.draw_utils.draw_destination_marker(
                self,
                current_path.destination,
                false,
                destination_indicator_fill_color,
                cone_length,
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                true,
                INF,
                4.0)
        var destination_indicator_stroke_color: Color = \
                Surfacer.ann_defaults \
                        .HUMAN_NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR if \
                navigator.player.is_human_player else \
                Surfacer.ann_defaults \
                        .COMPUTER_NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR
        destination_indicator_stroke_color *= fade_progress
        Gs.draw_utils.draw_destination_marker(
                self,
                current_path.destination,
                false,
                destination_indicator_stroke_color,
                cone_length,
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS,
                false,
                AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH,
                4.0)


func _draw_previous_path() -> void:
    var previous_path_color: Color = \
            Surfacer.ann_defaults.HUMAN_NAVIGATOR_PREVIOUS_PATH_COLOR if \
            navigator.player.is_human_player else \
            Surfacer.ann_defaults.COMPUTER_NAVIGATOR_PREVIOUS_PATH_COLOR
    Gs.draw_utils.draw_path(
            self,
            previous_path,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
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
    Gs.draw_utils.draw_beat_hashes(
            self,
            beats,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_DOWNBEAT_HASH_LENGTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_OFFBEAT_HASH_LENGTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
            color,
            color)


func _get_is_enabled() -> bool:
    if navigator.player.is_human_player:
        if is_slow_motion_enabled:
            return Surfacer \
                    .is_human_current_nav_trajectory_shown_with_slow_mo
        else:
            return Surfacer \
                    .is_human_current_nav_trajectory_shown_without_slow_mo
    else:
        if is_slow_motion_enabled:
            return Surfacer \
                    .is_computer_current_nav_trajectory_shown_with_slow_mo
        else:
            return Surfacer \
                    .is_computer_current_nav_trajectory_shown_without_slow_mo


func _get_is_exclamation_mark_shown() -> bool:
    return Surfacer.is_human_new_nav_exclamation_mark_shown if \
            navigator.player.is_human_player else \
            Surfacer.is_computer_new_nav_exclamation_mark_shown


func _get_last_beat_from_navigator() -> PathBeatPrediction:
    if !navigator.is_currently_navigating:
        return null
    
    var current_path_time := \
            Gs.time.get_scaled_play_time() - navigator.path_start_time_scaled
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
            FADE_IN_DURATION,
            "ease_out",
            0.0,
            TimeType.PLAY_PHYSICS)
    fade_tween.start()


func _trigger_beat_hash_animation(beat: PathBeatPrediction) -> void:
    var current_path_color: Color = \
            Surfacer.ann_defaults \
                    .HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
            navigator.player.is_human_player else \
            Surfacer.ann_defaults.COMPUTER_NAVIGATOR_CURRENT_PATH_COLOR
    current_path_color.a *= fade_progress
    
    Surfacer.annotators.add_transient(OnBeatHashAnnotator.new(
            beat,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_DOWNBEAT_HASH_LENGTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_OFFBEAT_HASH_LENGTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
            AnnotationElementDefaults \
                    .NAVIGATOR_TRAJECTORY_STROKE_WIDTH,
            current_path_color,
            current_path_color))
