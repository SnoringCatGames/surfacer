class_name ExclamationMarkAnnotator
extends TransientAnnotator


var WIDTH_START := 8.0
var LENGTH_START := 48.0
var STROKE_WIDTH_START := 3.0
var SCALE_END := 2.0
var VERTICAL_OFFSET := 0.0
var DURATION := 1.0
var OPACITY_DELAY := 0.3

var player
var player_half_height: float
var color: Color
var border_color: Color
var width_start: float
var length_start: float
var stroke_width_start: float
var scale_end: float
var vertical_offset: float
var opacity_delay: float

var mark_scale: float
var opacity: float


func _init(
        player,
        player_half_height := INF,
        color := Color.white,
        border_color := Color.white,
        width_start := WIDTH_START,
        length_start := LENGTH_START,
        stroke_width_start := STROKE_WIDTH_START,
        duration := DURATION,
        scale_end := SCALE_END,
        vertical_offset := VERTICAL_OFFSET,
        opacity_delay := OPACITY_DELAY).(duration) -> void:
    self.player = player
    self.player_half_height = \
            player_half_height if \
            !is_inf(player_half_height) else \
            player.movement_params.collider_half_width_height.y
    self.color = \
            color if \
            color != Color.white else \
            player.primary_annotation_color
    self.border_color = \
            border_color if \
            border_color != Color.white else \
            player.secondary_annotation_color
    self.width_start = width_start
    self.length_start = length_start
    self.stroke_width_start = stroke_width_start
    self.scale_end = scale_end
    self.vertical_offset = vertical_offset
    self.opacity_delay = opacity_delay
    _update()


func _update() -> void:
    if !is_instance_valid(player):
        emit_signal("stopped")
        return
    
    ._update()
    
    var scale_progress := (current_time - start_time) / duration
    scale_progress = min(scale_progress, 1.0)
    scale_progress = Sc.utils.ease_by_name(
            scale_progress, "ease_out_very_strong")
    mark_scale = lerp(
            1.0,
            scale_end,
            scale_progress)
    
    var opacity_progress := \
            (current_time - start_time - opacity_delay) / \
            (duration - opacity_delay)
    opacity_progress = clamp(
            opacity_progress,
            0.0,
            1.0)
    opacity_progress = Sc.utils.ease_by_name(
            opacity_progress, "ease_out_very_strong")
    opacity = lerp(
            1.0,
            0.0,
            opacity_progress)


func _draw() -> void:
    if !is_instance_valid(player):
        return
    
    var width := width_start * mark_scale
    var length := length_start * mark_scale
    var stroke_width := stroke_width_start * mark_scale
    var arc_length := clamp(width / 4.0, 2.0, 6.0)
    
    var center: Vector2 = player.position + Vector2(
            0.0,
            -player_half_height - \
            length_start * scale_end / 2.0 + \
            vertical_offset)
    
    self.modulate.a = opacity
    
    Sc.draw.draw_exclamation_mark(
            self,
            center,
            width,
            length,
            border_color,
            false,
            stroke_width,
            arc_length)
    Sc.draw.draw_exclamation_mark(
            self,
            center,
            width,
            length,
            color,
            true,
            0.0,
            arc_length)
