extends Node2D
class_name RulerAnnotator

const GRID_SPACING := 64.0

const LINE_WIDTH := 1.0

var LINE_COLOR := Colors.opacify(Colors.WHITE, Colors.ALPHA_XXFAINT)
var TEXT_COLOR := Colors.opacify(Colors.WHITE, Colors.ALPHA_XFAINT)

var viewport: Viewport

var viewport_size: Vector2
var screen_center := Vector2.ZERO

func _enter_tree() -> void:
    viewport = get_viewport()
    viewport_size = viewport.get_visible_rect().size
    get_tree().get_root().connect( \
            "size_changed", \
            self, \
            "_on_viewport_size_changed")

func _process(delta_sec: float) -> void:
    var next_screen_center: Vector2 = \
            ScaffoldConfig.camera_controller.get_position()
    
    if next_screen_center != screen_center:
        # The camera position moved, so we need to update the ruler.
        screen_center = next_screen_center
        update()

func _draw() -> void:
    var grid_spacing: float = \
            GRID_SPACING / ScaffoldConfig.camera_controller.zoom
    var screen_start_position: Vector2 = \
            screen_center / ScaffoldConfig.camera_controller.zoom - \
            viewport_size / 2.0
    
    # Offset the start position to align with the grid cell boundaries.
    var ruler_start_position := Vector2( \
            -fmod((screen_start_position.x + grid_spacing * 1000000000), \
                    grid_spacing), \
            -fmod((screen_start_position.y + grid_spacing * 1000000000), \
                    grid_spacing))
    
    var ruler_size := viewport_size + Vector2(grid_spacing, grid_spacing)
    var vertical_line_count := floor(ruler_size.x / grid_spacing) as int + 1
    var horizontal_line_count := floor(ruler_size.y / grid_spacing) as int + 1
    
    var start_x: float
    var start_y: float
    var start_position: Vector2
    var end_position: Vector2
    var text: String
    
    # Draw the vertical lines.
    start_y = ruler_start_position.y
    for i in range(vertical_line_count):
        start_x = ruler_start_position.x + grid_spacing * i
        start_position = Vector2(start_x, start_y)
        end_position = Vector2(start_x, start_y + ruler_size.y)
        draw_line( \
                start_position, \
                end_position, \
                LINE_COLOR, \
                LINE_WIDTH)
        
        text = str(round((screen_start_position.x + start_x) * \
                ScaffoldConfig.camera_controller.zoom))
        text = "0" if text == "-0" else text
        draw_string( \
                ScaffoldConfig.fonts.main_xs, \
                Vector2(start_position.x + 2, 14), \
                text, \
                TEXT_COLOR)
    
    # Draw the horizontal lines.
    start_x = ruler_start_position.x
    for i in range(1, horizontal_line_count):
        start_y = ruler_start_position.y + grid_spacing * i
        start_position = Vector2(start_x, start_y)
        end_position = Vector2(start_x + ruler_size.x, start_y)
        draw_line( \
                start_position, \
                end_position, \
                LINE_COLOR, \
                LINE_WIDTH)
        
        text = str(round((screen_start_position.y + start_y) * \
                ScaffoldConfig.camera_controller.zoom))
        text = "0" if text == "-0" else text
        draw_string( \
                ScaffoldConfig.fonts.main_xs, \
                Vector2(2, start_position.y + 14), \
                text, \
                TEXT_COLOR)

func _on_viewport_size_changed() -> void:
    viewport_size = viewport.get_visible_rect().size
    update()
