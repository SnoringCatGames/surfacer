extends Node2D
class_name SurfaceSelectionAnnotator

var VALID_SELECTION_COLOR: Color = Colors.opacify(Colors.WHITE, Colors.ALPHA_SOLID)
var INVALID_SELECTION_COLOR: Color = Colors.opacify(Colors.RED, Colors.ALPHA_SOLID)
const SELECT_DURATION_SEC := max( \
        ClickAnnotator.CLICK_INNER_DURATION_SEC, \
        ClickAnnotator.CLICK_OUTER_DURATION_SEC)

var player: Player
var selection_position_to_animate: PositionAlongSurface = null
var selection_color: Color
var animation_start_time := -SELECT_DURATION_SEC
var animation_end_time := -SELECT_DURATION_SEC
var animation_progress := 1.0
# This separate field is used to ensure we clear any remaining rendering after the animation is
# done.
var is_a_selection_currently_rendered := false

func _init(player: Player) -> void:
    self.player = player

func _process(delta_sec: float) -> void:
    var current_time: float = Time.elapsed_play_time_sec
    
    # Has there been a new surface selection?
    if player.last_selection_position != selection_position_to_animate:
        # Choose a color that indicates whether the navigator could actually navigate to the
        # selected position.
        selection_color = \
                VALID_SELECTION_COLOR if \
                player.last_selection_position == player.navigator.current_destination else \
                INVALID_SELECTION_COLOR
        selection_position_to_animate = player.last_selection_position
        animation_start_time = current_time
        animation_end_time = animation_start_time + SELECT_DURATION_SEC
        is_a_selection_currently_rendered = true
    
    if animation_end_time > current_time or \
            is_a_selection_currently_rendered:
        animation_progress = (current_time - animation_start_time) / SELECT_DURATION_SEC
        update()

func _draw() -> void:
    if animation_progress >= 1:
        # When we don't render anything in this draw call, it clears the draw buffer.
        is_a_selection_currently_rendered = false
        return
    
    var alpha := selection_color.a * (1 - animation_progress)
    var color := Color( \
            selection_color.r, \
            selection_color.g, \
            selection_color.b, \
            alpha)
    
    DrawUtils.draw_surface( \
            self, \
            selection_position_to_animate.surface, \
            color)
