extends Node2D
class_name ClickAnnotator

const CLICK_INNER_END_RADIUS := 58.0
const CLICK_OUTER_END_RADIUS := 100.0
var CLICK_INNER_COLOR := \
        Colors.opacify(Colors.WHITE, Colors.ALPHA_SLIGHTLY_FAINT)
var CLICK_OUTER_COLOR := \
        Colors.opacify(Colors.WHITE, Colors.ALPHA_SLIGHTLY_FAINT)
const CLICK_INNER_DURATION_SEC := 0.27
const CLICK_OUTER_DURATION_SEC := 0.23

var click_position := Vector2.INF
var start_time := -CLICK_INNER_DURATION_SEC
var inner_end_time := -CLICK_INNER_DURATION_SEC
var outer_end_time := -CLICK_OUTER_DURATION_SEC
var inner_progress := 1.0
var outer_progress := 1.0
var is_a_click_currently_rendered := false

func _unhandled_input(event: InputEvent) -> void:
    var current_time: float = Time.elapsed_play_time_sec
    
    var position := Vector2.INF
    
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed:
        position = Global.current_level.get_global_mouse_position()
        
    elif event is InputEventScreenTouch and \
            !event.pressed:
        position = Utils.get_global_touch_position(event)
    
    if position != Vector2.INF:
        click_position = position
        start_time = current_time
        inner_end_time = start_time + CLICK_INNER_DURATION_SEC
        outer_end_time = start_time + CLICK_OUTER_DURATION_SEC
        is_a_click_currently_rendered = true

func _process(delta_sec: float) -> void:
    var current_time: float = Time.elapsed_play_time_sec
    
    inner_progress = (current_time - start_time) / CLICK_INNER_DURATION_SEC
    outer_progress = (current_time - start_time) / CLICK_OUTER_DURATION_SEC
    
    if is_a_click_currently_rendered:
        update()

func _draw() -> void:
    var is_inner_animation_complete := inner_progress >= 1.0
    var is_outer_animation_complete := outer_progress >= 1.0
    
    if is_inner_animation_complete and \
            is_outer_animation_complete:
        is_a_click_currently_rendered = false
        return
    
    if !is_inner_animation_complete:
        var alpha := CLICK_INNER_COLOR.a * (1 - inner_progress)
        var color := Color( \
                CLICK_INNER_COLOR.r, \
                CLICK_INNER_COLOR.g, \
                CLICK_INNER_COLOR.b, \
                alpha)
        var radius := CLICK_INNER_END_RADIUS * inner_progress
        
        draw_circle( \
                click_position, \
                radius, \
                color)
    
    if !is_outer_animation_complete:
        var alpha := CLICK_OUTER_COLOR.a * (1 - outer_progress)
        var color := Color( \
                CLICK_OUTER_COLOR.r, \
                CLICK_OUTER_COLOR.g, \
                CLICK_OUTER_COLOR.b, \
                alpha)
        var radius := CLICK_OUTER_END_RADIUS * outer_progress
        
        draw_circle( \
                click_position, \
                radius, \
                color)
