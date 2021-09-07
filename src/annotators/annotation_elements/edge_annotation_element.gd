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
                Sc.ann_params.includes_waypoints,
        includes_instruction_indicators := \
                Sc.ann_params.includes_instruction_indicators,
        includes_continuous_positions := \
                Sc.ann_params.includes_continuous_positions,
        includes_discrete_positions := \
                Sc.ann_params.includes_discrete_positions,
        color_params := \
                Sc.ann_params.edge_discrete_trajectory_color_params) \
        .(TYPE) -> void:
    self.edge = edge
    self.includes_waypoints = \
            Sc.ann_params.includes_waypoints
    self.includes_instruction_indicators = \
            Sc.ann_params.includes_instruction_indicators
    self.includes_continuous_positions = \
            Sc.ann_params.includes_continuous_positions
    self.includes_discrete_positions = \
            Sc.ann_params.includes_discrete_positions
    self.color_params = color_params


func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
    Sc.draw.draw_edge(
            canvas,
            edge,
            Sc.ann_params.edge_trajectory_width,
            color,
            Sc.ann_params.includes_waypoints,
            Sc.ann_params.includes_instruction_indicators,
            Sc.ann_params.includes_continuous_positions,
            Sc.ann_params.includes_discrete_positions)


func _create_legend_items() -> Array:
    var items := []
    
    if Sc.ann_params.includes_discrete_positions:
        var discrete_trajectory_item := DiscreteEdgeTrajectoryLegendItem.new()
        items.push_back(discrete_trajectory_item)
    
    if Sc.ann_params.includes_continuous_positions:
        var continuous_trajectory_item := \
                ContinuousEdgeTrajectoryLegendItem.new()
        items.push_back(continuous_trajectory_item)
    
    if Sc.ann_params.includes_waypoints:
        var origin_item := OriginLegendItem.new()
        items.push_back(origin_item)
        var destination_item := DestinationLegendItem.new()
        items.push_back(destination_item)
    
    if Sc.ann_params.includes_instruction_indicators:
        var instruction_start_item := InstructionStartLegendItem.new()
        items.push_back(instruction_start_item)
        var instruction_end_item := InstructionEndLegendItem.new()
        items.push_back(instruction_end_item)
    
    return items
