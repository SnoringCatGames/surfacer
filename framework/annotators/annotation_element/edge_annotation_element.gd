extends AnnotationElement
class_name EdgeAnnotationElement

const DEFAULT_BASE_COLOR := Color.white

const TYPE := AnnotationElementType.EDGE

var edge: Edge
var includes_waypoints: bool
var includes_instruction_indicators: bool
var includes_discrete_positions: bool
var base_color: Color

func _init( \
        edge: Edge, \
        includes_waypoints := false, \
        includes_instruction_indicators := false, \
        includes_discrete_positions := false, \
        base_color := DEFAULT_BASE_COLOR) \
        .(TYPE) -> void:
    self.edge = edge
    self.includes_waypoints = includes_waypoints
    self.includes_instruction_indicators = includes_instruction_indicators
    self.includes_discrete_positions = includes_discrete_positions
    self.base_color = base_color

func draw(canvas: CanvasItem) -> void:
    DrawUtils.draw_edge( \
            canvas, \
            edge, \
            includes_waypoints, \
            includes_instruction_indicators, \
            includes_discrete_positions, \
            base_color)
