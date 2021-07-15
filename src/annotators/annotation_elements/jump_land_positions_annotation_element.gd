class_name JumpLandPositionsAnnotationElement
extends AnnotationElement


const TYPE := AnnotationElementType.JUMP_LAND_POSITIONS

var jump_land_positions: JumpLandPositions
var color_params: ColorParams
var radius: float
var dash_length: float
var dash_gap: float
var dash_stroke_width: float


func _init(
        jump_land_positions: JumpLandPositions,
        color_params := \
                Su.ann_defaults.JUMP_LAND_POSITIONS_COLOR_PARAMS,
        dash_length := \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_LENGTH,
        dash_gap := \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_GAP,
        dash_stroke_width := AnnotationElementDefaults \
                .JUMP_LAND_POSITIONS_DASH_STROKE_WIDTH) \
        .(TYPE) -> void:
    self.jump_land_positions = jump_land_positions
    self.color_params = color_params
    self.dash_length = dash_length
    self.dash_gap = dash_gap
    self.dash_stroke_width = dash_stroke_width
    self.radius = radius


func draw(canvas: CanvasItem) -> void:
    var color := color_params.get_color()
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
