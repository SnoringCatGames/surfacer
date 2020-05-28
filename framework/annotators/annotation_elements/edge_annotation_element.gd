extends AnnotationElement
class_name EdgeAnnotationElement

const TYPE := AnnotationElementType.EDGE

var edge: Edge
var includes_waypoints: bool
var includes_instruction_indicators: bool
var includes_discrete_positions: bool
var color_params: ColorParams

func _init( \
        edge: Edge, \
        includes_waypoints := \
                AnnotationElementDefaults_.INCLUDES_WAYPOINTS, \
        includes_instruction_indicators := \
                AnnotationElementDefaults_.INCLUDES_INSTRUCTION_INDICATORS, \
        includes_discrete_positions := \
                AnnotationElementDefaults_.INCLUDES_DISCRETE_POSITIONS, \
        color_params := \
                AnnotationElementDefaults_.EDGE_COLOR_PARAMS) \
        .(TYPE) -> void:
    self.edge = edge
    self.includes_waypoints = includes_waypoints
    self.includes_instruction_indicators = includes_instruction_indicators
    self.includes_discrete_positions = includes_discrete_positions
    self.color_params = color_params

func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    DrawUtils.draw_edge( \
            canvas, \
            edge, \
            includes_waypoints, \
            includes_instruction_indicators, \
            includes_discrete_positions, \
            color)
