class_name OriginLegendItem
extends LegendItem


const TYPE := "ORIGIN"
const TEXT := "Origin"

const SCALE := 0.8
const SECTOR_ARC_LENGTH := 2.2


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    var color: Color = Sc.palette.get_color("default_waypoint_color")
    var radius: float = Sc.annotators.params.edge_start_radius * SCALE * Sc.gui.scale
    Sc.draw.draw_origin_marker(
            self,
            center,
            color,
            radius,
            Sc.annotators.params.edge_waypoint_stroke_width,
            SECTOR_ARC_LENGTH)
