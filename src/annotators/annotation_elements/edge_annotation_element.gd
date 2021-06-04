class_name EdgeAnnotationElement
extends AnnotationElement


const TYPE := AnnotationElementType.EDGE

var edge: Edge
var includes_waypoints: bool
var includes_instruction_indicators: bool
var includes_continuous_positions: bool
var includes_discrete_positions: bool
var color_params: ColorParams


func _init(
        edge: Edge,
        includes_waypoints := \
                AnnotationElementDefaults.INCLUDES_WAYPOINTS,
        includes_instruction_indicators := \
                AnnotationElementDefaults.INCLUDES_INSTRUCTION_INDICATORS,
        includes_continuous_positions := \
                AnnotationElementDefaults.INCLUDES_CONTINUOUS_POSITIONS,
        includes_discrete_positions := \
                AnnotationElementDefaults.INCLUDES_DISCRETE_POSITIONS,
        color_params := Surfacer.ann_defaults \
                .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS) \
        .(TYPE) -> void:
    self.edge = edge
    self.includes_waypoints = includes_waypoints
    self.includes_instruction_indicators = includes_instruction_indicators
    self.includes_continuous_positions = includes_continuous_positions
    self.includes_discrete_positions = includes_discrete_positions
    self.color_params = color_params


func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    Gs.draw_utils.draw_edge(
            canvas,
            edge,
            SurfacerDrawUtils.EDGE_TRAJECTORY_WIDTH,
            color,
            includes_waypoints,
            includes_instruction_indicators,
            includes_continuous_positions,
            includes_discrete_positions)


func _create_legend_items() -> Array:
    var items := []
    
    if includes_discrete_positions:
        var discrete_trajectory_item := DiscreteEdgeTrajectoryLegendItem.new()
        items.push_back(discrete_trajectory_item)
    
    if includes_continuous_positions:
        var continuous_trajectory_item := \
                ContinuousEdgeTrajectoryLegendItem.new()
        items.push_back(continuous_trajectory_item)
    
    if includes_waypoints:
        var origin_item := OriginLegendItem.new()
        items.push_back(origin_item)
        var destination_item := DestinationLegendItem.new()
        items.push_back(destination_item)
    
    if includes_instruction_indicators:
        var instruction_start_item := InstructionStartLegendItem.new()
        items.push_back(instruction_start_item)
        var instruction_end_item := InstructionEndLegendItem.new()
        items.push_back(instruction_end_item)
    
    return items
