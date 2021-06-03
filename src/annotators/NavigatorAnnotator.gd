class_name NavigatorAnnotator
extends Node2D

var FADE_IN_DURATION := 0.2

var EXCLAMATION_MARK_WIDTH_START := 8.0
var EXCLAMATION_MARK_LENGTH_START := 48.0
var EXCLAMATION_MARK_STROKE_WIDTH_START := 3.0
var EXCLAMATION_MARK_SCALE_END := 2.0
var EXCLAMATION_MARK_VERTICAL_OFFSET := 0.0
var EXCLAMATION_MARK_DURATION := 1.0
var EXCLAMATION_MARK_OPACITY_DELAY_SEC := 0.3

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var previous_path_beats: Array
var current_path_beats: Array
var is_enabled := false
var is_slow_motion_enabled := false

var is_fade_in_progress := false
var previous_fade_progress := 0.0
var fade_progress := 0.0

var previous_path_back_end_trim_radius: float

var is_exclamation_mark_shown := false
var exclamation_mark_trigger_time_scaled := INF
var exclamation_mark_offset: Vector2

var pulse_annotator: NavigationPulseAnnotator
var fade_tween: ScaffolderTween
var exclamation_mark_tween: ScaffolderTween

func _init(navigator: Navigator) -> void:
    self.navigator = navigator
    self.previous_path_back_end_trim_radius = min(
            navigator.player.movement_params.collider_half_width_height.x,
            navigator.player.movement_params.collider_half_width_height.y)
    
    self.pulse_annotator = NavigationPulseAnnotator.new(navigator)
    add_child(pulse_annotator)
    
    self.fade_tween = ScaffolderTween.new()
    add_child(fade_tween)
    
    self.exclamation_mark_tween = ScaffolderTween.new()
    exclamation_mark_tween.connect(
            "tween_all_completed", self, "_exclamation_mark_tween_completed")
    add_child(exclamation_mark_tween)

func _physics_process(_delta_sec: float) -> void:
    is_fade_in_progress = fade_progress != previous_fade_progress
    previous_fade_progress = fade_progress
    
    if navigator.path != current_path:
        current_path = navigator.path
        current_path_beats = navigator.path_beats
        if current_path != null:
            if _get_is_exclamation_mark_shown():
                is_exclamation_mark_shown = true
                exclamation_mark_trigger_time_scaled = \
                        Gs.time.get_scaled_play_time_sec()
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
    
    if is_exclamation_mark_shown:
        update()

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

func _draw() -> void:
    if is_exclamation_mark_shown:
        _draw_exclamation_mark()
    
    if !is_enabled and \
            !is_fade_in_progress:
        return
    
    if current_path != null:
        _draw_current_path(current_path, fade_progress)
    
    elif previous_path != null and \
            Surfacer.is_previous_trajectory_shown and \
            navigator.player.is_human_player:
        _draw_previous_path()

func _draw_current_path(
        current_path: PlatformGraphPath,
        fade_progress: float) -> void:
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

func _draw_exclamation_mark() -> void:
    var current_time_scaled := Gs.time.get_scaled_play_time_sec()
    var end_time_scaled := \
            exclamation_mark_trigger_time_scaled + EXCLAMATION_MARK_DURATION
    
    if current_time_scaled > end_time_scaled:
        is_exclamation_mark_shown = false
        exclamation_mark_trigger_time_scaled = INF
        return
    
    var scale_progress := \
            (current_time_scaled - exclamation_mark_trigger_time_scaled) / \
            EXCLAMATION_MARK_DURATION
    scale_progress = min(scale_progress, 1.0)
    scale_progress = Gs.utils.ease_by_name(
            scale_progress, "ease_out_very_strong")
    var scale: float = lerp(
            1.0,
            EXCLAMATION_MARK_SCALE_END,
            scale_progress)
    
    var opacity_progress := \
            (current_time_scaled - \
                    EXCLAMATION_MARK_OPACITY_DELAY_SEC - \
                    exclamation_mark_trigger_time_scaled) / \
            (EXCLAMATION_MARK_DURATION - \
                    EXCLAMATION_MARK_OPACITY_DELAY_SEC)
    opacity_progress = clamp(
            opacity_progress,
            0.0,
            1.0)
    opacity_progress = Gs.utils.ease_by_name(
            opacity_progress, "ease_out_very_strong")
    var opacity: float = lerp(
            1.0,
            0.0,
            opacity_progress)
    
    var width := EXCLAMATION_MARK_WIDTH_START * scale
    var length := EXCLAMATION_MARK_LENGTH_START * scale
    var stroke_width := EXCLAMATION_MARK_STROKE_WIDTH_START * scale
    
    var center: Vector2 = navigator.player.position + Vector2(
            0.0,
            -navigator.player.movement_params.collider_half_width_height.y - \
            EXCLAMATION_MARK_LENGTH_START * EXCLAMATION_MARK_SCALE_END / 2.0 + \
            EXCLAMATION_MARK_VERTICAL_OFFSET)
    
    var fill_color: Color = \
            Surfacer.ann_defaults.HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
            navigator.player.is_human_player else \
            Surfacer.ann_defaults.COMPUTER_NAVIGATOR_CURRENT_PATH_COLOR
    fill_color.a = opacity
    
    var stroke_color: Color = Color.white
    stroke_color.a = opacity
    
    Gs.draw_utils.draw_exclamation_mark(
            self,
            center,
            width,
            length,
            stroke_color,
            false,
            stroke_width)
    Gs.draw_utils.draw_exclamation_mark(
            self,
            center,
            width,
            length,
            fill_color,
            true,
            0.0)
