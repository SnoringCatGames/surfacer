class_name HypotheticalEdgeTrajectoryLegendItem
extends LegendItem


const TYPE := "HYPOTHETICAL_EDGE_TRAJECTORY"
const TEXT := "Hypothetical\nedge"


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    var offset_from_center := size * 0.35
    var start := center - offset_from_center
    var end := center + offset_from_center
    var color: Color = Sc.palette.get_color("default_jump_land_positions_color")
    Sc.draw.draw_dashed_line(
            self,
            start,
            end,
            color,
            Sc.annotators.params.jump_land_positions_dash_length,
            Sc.annotators.params.jump_land_positions_dash_gap,
            0.0,
            Sc.annotators.params.jump_land_positions_dash_stroke_width)
