extends Node2D
class_name SurfaceSelectionAnnotator

var SELECT_COLOR: Color = Colors.opacify(Colors.WHITE, Colors.ALPHA_SOLID)
const SELECT_DURATION_SEC := ClickAnnotator.CLICK_DURATION_SEC

var global # TODO: Add type back
var player: Player
var preselect_surface_position: PositionAlongSurface = null
var selected_surface_position: PositionAlongSurface = null
var last_animated_selection_position := Vector2.INF
var select_animation_start_time := -SELECT_DURATION_SEC
var select_animation_end_time := -SELECT_DURATION_SEC
var progress := 1.0
var is_a_select_currently_rendered := false

func _init(player: Player) -> void:
    self.player = player

func _ready() -> void:
    self.global = $"/root/Global"

func _process(delta: float) -> void:
    var current_time: float = global.elapsed_play_time_sec
    
    if player.last_selection_position != last_animated_selection_position and \
            player.last_selection_position == player.navigator.current_target:
        selected_surface_position = \
                player.navigator.current_path.edges.back().end_position_along_surface
        last_animated_selection_position = player.last_selection_position
        select_animation_start_time = current_time
        select_animation_end_time = select_animation_start_time + SELECT_DURATION_SEC
        is_a_select_currently_rendered = true
    
    if select_animation_end_time > current_time or \
            is_a_select_currently_rendered:
        progress = (current_time - select_animation_start_time) / SELECT_DURATION_SEC
        update()

func _draw() -> void:
    if progress >= 1:
        is_a_select_currently_rendered = false
        return
    
    var alpha := SELECT_COLOR.a * (1 - progress)
    var color := Color( \
            SELECT_COLOR.r, \
            SELECT_COLOR.g, \
            SELECT_COLOR.b, \
            alpha)
    
    DrawUtils.draw_surface( \
            self, \
            selected_surface_position.surface, \
            color)
