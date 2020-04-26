extends Node2D
class_name SurfacePreselectionAnnotator

var SELECT_COLOR: Color = Colors.opacify(Colors.PURPLE, Colors.ALPHA_SOLID)
const SELECT_DURATION_SEC := 0.4

var global # TODO: Add type back
var player: Player
var preselection_position_to_draw: PositionAlongSurface = null
var animation_start_time := -SELECT_DURATION_SEC
var animation_progress := 1.0

func _init(player: Player) -> void:
    self.player = player

func _ready() -> void:
    self.global = $"/root/Global"

func _process(delta: float) -> void:
    var current_time: float = global.elapsed_play_time_sec
    
    # Has the preselect position changed since last draw?
    if preselection_position_to_draw != player.preselection_position and \
            player.new_selection_target == Vector2.INF:
        # Are we starting a preselection on a new surface?
        var previous_preselection_surface := \
                preselection_position_to_draw.surface if \
                preselection_position_to_draw != null else \
                null
        var next_preselection_surface := \
                player.preselection_position.surface if \
                player.preselection_position != null else \
                null
        if previous_preselection_surface != next_preselection_surface:
            animation_start_time = current_time
        
        preselection_position_to_draw = player.preselection_position
        
        update()
    
    if preselection_position_to_draw != null:
        animation_progress = \
                fmod((current_time - animation_start_time) / SELECT_DURATION_SEC, 1.0)
        update()

func _draw() -> void:
    if preselection_position_to_draw == null:
        # When we don't render anything in this draw call, it clears the draw buffer.
        return
    
    var alpha := SELECT_COLOR.a * (1 - animation_progress)
    var color := Color( \
            SELECT_COLOR.r, \
            SELECT_COLOR.g, \
            SELECT_COLOR.b, \
            alpha)
    
    DrawUtils.draw_surface( \
            self, \
            preselection_position_to_draw.surface, \
            color)
