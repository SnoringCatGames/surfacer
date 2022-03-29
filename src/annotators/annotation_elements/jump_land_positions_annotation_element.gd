class_name JumpLandPositionsAnnotationElement
extends SurfacerAnnotationElement


const TYPE := AnnotationElementType.JUMP_LAND_POSITIONS

var jump_land_positions: JumpLandPositions
var color_config: ColorConfig
var radius: float
var dash_length: float
var dash_gap: float
var dash_stroke_width: float


func _init(
        jump_land_positions: JumpLandPositions,
        color_config := Sc.annotators.params.jump_land_positions_color_config,
        dash_length := Sc.annotators.params.jump_land_positions_dash_length,
        dash_gap := Sc.annotators.params.jump_land_positions_dash_gap,
        dash_stroke_width := \
                Sc.annotators.params.jump_land_positions_dash_stroke_width) \
        .(TYPE) -> void:
    self.jump_land_positions = jump_land_positions
    self.color_config = color_config
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.dash_stroke_width = dash_stroke_width
    self.radius = radius


func draw(canvas: CanvasItem) -> void:
    var color := color_config.sample()
    var start := jump_land_positions.jump_position.target_point
    var end := jump_land_positions.land_position.target_point
    Sc.draw.draw_dashed_line(
            canvas,
            start,
            end,
            color,
            dash_length,
            dash_gap,
            0.0,
            dash_stroke_width)
    Sc.draw.draw_origin_marker(
            canvas,
            start,
            color)
    Sc.draw.draw_destination_marker(
            canvas,
            jump_land_positions.land_position,
            true,
            color)


func _create_legend_items() -> Array:
    var hypothetical_edge_item := HypotheticalEdgeTrajectoryLegendItem.new()
    var origin_item := OriginLegendItem.new()
    var destination_item := DestinationLegendItem.new()
    return [
        hypothetical_edge_item,
        origin_item,
        destination_item,
    ]
