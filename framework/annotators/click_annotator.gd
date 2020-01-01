extends Node2D
class_name ClickAnnotator

const CLICK_END_RADIUS := 58.0
var CLICK_COLOR := Colors.opacify(Colors.WHITE, Colors.ALPHA_SOLID)
const CLICK_DURATION_SEC := 0.2

var global # TODO: Add type back
var level # TODO: Add type back
var click_position: Vector2
var closest_surface_position: PositionAlongSurface
var start_time := -CLICK_DURATION_SEC
var end_time := -CLICK_DURATION_SEC
var progress := 1.0
var is_a_click_currently_rendered := false

func _ready() -> void:
    self.global = $"/root/Global"

func _unhandled_input(event: InputEvent) -> void:
    var current_time: float = global.elapsed_play_time_sec
    
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
        click_position = global.current_level.get_global_mouse_position()
        
        if global.current_player_for_clicks != null:
            closest_surface_position = SurfaceParser.find_closest_position_on_a_surface( \
                    click_position, global.current_player_for_clicks)
        else:
            closest_surface_position = null
        
        start_time = current_time
        end_time = start_time + CLICK_DURATION_SEC
        is_a_click_currently_rendered = true

func _process(delta: float) -> void:
    var current_time: float = global.elapsed_play_time_sec
    
    if end_time > current_time or is_a_click_currently_rendered:
        progress = (current_time - start_time) / CLICK_DURATION_SEC
        update()

func _draw() -> void:
    if progress >= 1:
        is_a_click_currently_rendered = false
        return
    
    var alpha := CLICK_COLOR.a * (1 - progress)
    var color := Color(CLICK_COLOR.r, CLICK_COLOR.g, CLICK_COLOR.b, alpha)
    var radius := CLICK_END_RADIUS * progress
    
    draw_circle(click_position, radius, color)
    if closest_surface_position != null:
        DrawUtils.draw_surface(self, closest_surface_position.surface, color)
