class_name NewNavExclamationMarkAnnotator
extends TransientAnnotator

var EXCLAMATION_MARK_WIDTH_START := 8.0
var EXCLAMATION_MARK_LENGTH_START := 48.0
var EXCLAMATION_MARK_STROKE_WIDTH_START := 3.0
var EXCLAMATION_MARK_SCALE_END := 2.0
var EXCLAMATION_MARK_VERTICAL_OFFSET := 0.0
var EXCLAMATION_MARK_DURATION := 1.0
var EXCLAMATION_MARK_OPACITY_DELAY := 0.3

var player

var mark_scale: float
var opacity: float


func _init(player).(EXCLAMATION_MARK_DURATION) -> void:
    self.player = player
    _update()


func _update() -> void:
    ._update()
    
    var scale_progress := \
            (current_time - start_time) / \
            EXCLAMATION_MARK_DURATION
    scale_progress = min(scale_progress, 1.0)
    scale_progress = Gs.utils.ease_by_name(
            scale_progress, "ease_out_very_strong")
    mark_scale = lerp(
            1.0,
            EXCLAMATION_MARK_SCALE_END,
            scale_progress)
    
    var opacity_progress := \
            (current_time - \
                    start_time - \
                    EXCLAMATION_MARK_OPACITY_DELAY) / \
            (EXCLAMATION_MARK_DURATION - \
                    EXCLAMATION_MARK_OPACITY_DELAY)
    opacity_progress = clamp(
            opacity_progress,
            0.0,
            1.0)
    opacity_progress = Gs.utils.ease_by_name(
            opacity_progress, "ease_out_very_strong")
    opacity = lerp(
            1.0,
            0.0,
            opacity_progress)


func _draw() -> void:
    var width := EXCLAMATION_MARK_WIDTH_START * mark_scale
    var length := EXCLAMATION_MARK_LENGTH_START * mark_scale
    var stroke_width := EXCLAMATION_MARK_STROKE_WIDTH_START * mark_scale
    
    var center: Vector2 = player.position + Vector2(
            0.0,
            -player.movement_params.collider_half_width_height.y - \
            EXCLAMATION_MARK_LENGTH_START * \
                    EXCLAMATION_MARK_SCALE_END / 2.0 + \
            EXCLAMATION_MARK_VERTICAL_OFFSET)
    
    var fill_color: Color = \
            Surfacer.ann_defaults.HUMAN_NAVIGATOR_CURRENT_PATH_COLOR if \
            player.is_human_player else \
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
