class_name NavigatorAnnotator
extends Node2D

var FADE_IN_DURATION := 0.35

var EXCLAMATION_MARK_SCALE_START := Vector2(0.2, 0.2)
var EXCLAMATION_MARK_SCALE_END := Vector2(1.5, 1.5)
var EXCLAMATION_MARK_DURATION := 1.0
var EXCLAMATION_MARK_VERTICAL_OFFSET := -32.0

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var current_destination: PositionAlongSurface
var is_enabled := false
var is_slow_motion_enabled := false

var is_fade_in_progress := false
var previous_fade_progress := 0.0
var fade_progress := 0.0

var previous_path_back_end_trim_radius: float

var exclamation_mark_offset: Vector2

var pulse_annotator: NavigationPulseAnnotator
var exclamation_mark: Label
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
    
    self.exclamation_mark = Label.new()
    exclamation_mark.add_font_override("font", Gs.fonts.main_m)
    var exclamation_mark_color: Color = \
            Surfacer.ann_defaults \
                    .HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
            navigator.player.is_human_player else \
            Surfacer.ann_defaults.COMPUTER_NAVIGATOR_CURRENT_PATH_COLOR
    exclamation_mark_color.a = 1.0
    exclamation_mark.add_color_override("font_color", exclamation_mark_color)
    exclamation_mark.align = Label.ALIGN_CENTER
    exclamation_mark.valign = Label.VALIGN_CENTER
    exclamation_mark.text = "!"
    exclamation_mark.visible = false
    add_child(exclamation_mark)
    
    _update_exclamation_mark_offset()
    call_deferred("_update_exclamation_mark_offset")

func _physics_process(_delta_sec: float) -> void:
    is_fade_in_progress = fade_progress != previous_fade_progress
    previous_fade_progress = fade_progress
    
    exclamation_mark.rect_position = \
            navigator.player.position + exclamation_mark_offset
    
    if navigator.path != current_path:
        current_path = navigator.path
        current_destination = navigator.get_destination()
        if current_path != null:
            _trigger_exclamation_mark()
            if is_enabled:
                _trigger_fade_in(true)
        update()
    
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        update()
    
    if Surfacer.slow_motion.is_enabled != is_slow_motion_enabled:
        is_slow_motion_enabled = Surfacer.slow_motion.is_enabled
        is_enabled = _get_is_enabled()
        _trigger_fade_in(is_enabled)
        update()
    
    if is_fade_in_progress:
        update()

func _update_exclamation_mark_offset() -> void:
    var half_size := exclamation_mark.rect_size / 2.0
    exclamation_mark_offset = \
            -half_size + Vector2(
            0.0,
            -navigator.player.movement_params.collider_half_width_height.y + \
            EXCLAMATION_MARK_VERTICAL_OFFSET)
    exclamation_mark.rect_pivot_offset = half_size

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

func _trigger_exclamation_mark() -> void:
    var opacity_start := 1.0
    var opacity_end := 0.0
    
    var scale_delay := EXCLAMATION_MARK_DURATION * 0.0
    var scale_duration := EXCLAMATION_MARK_DURATION - scale_delay
    var opacity_delay := EXCLAMATION_MARK_DURATION * 0.3
    var opacity_duration := EXCLAMATION_MARK_DURATION - opacity_delay
    
    exclamation_mark.visible = true
    exclamation_mark.rect_scale = EXCLAMATION_MARK_SCALE_START
    exclamation_mark.modulate.a = opacity_start
    
    exclamation_mark_tween.stop_all()
    exclamation_mark_tween.interpolate_property(
            exclamation_mark,
            "rect_scale",
            EXCLAMATION_MARK_SCALE_START,
            EXCLAMATION_MARK_SCALE_END,
            scale_duration,
            "ease_out_very_strong",
            scale_delay,
            TimeType.PLAY_PHYSICS_SCALED)
    exclamation_mark_tween.interpolate_property(
            exclamation_mark,
            "modulate:a",
            opacity_start,
            opacity_end,
            opacity_duration,
            "ease_out_very_strong",
            opacity_delay,
            TimeType.PLAY_PHYSICS_SCALED)
    exclamation_mark_tween.start()

func _exclamation_mark_tween_completed() -> void:
    exclamation_mark.visible = false

func _draw() -> void:
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
        
        _draw_beat_hashes(current_path, current_path_color)
        
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
                current_destination,
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
                current_destination,
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
    _draw_beat_hashes(previous_path, previous_path_color)

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

func _draw_beat_hashes(
        path: PlatformGraphPath,
        color: Color) -> void:
    if is_slow_motion_enabled:
        Gs.draw_utils.draw_path_beat_hashes(
                self,
                path,
                Surfacer.slow_motion.music.time_to_next_music_beat,
                Surfacer.slow_motion.music.next_music_beat_index,
                Surfacer.slow_motion.music.music_beat_duration,
                Surfacer.slow_motion.music.meter,
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
    else:
        Gs.draw_utils.draw_path_beat_hashes(
                self,
                path,
                Gs.audio.time_to_next_beat,
                Gs.audio.next_beat_index,
                Gs.audio.get_beat_duration(),
                Gs.audio.get_meter(),
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
