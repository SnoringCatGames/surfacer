class_name OriginLegendItem
extends LegendItem


const TYPE := LegendItemType.ORIGIN
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
    var color: Color = Sc.ann_params.default_waypoint_color_params.get_color()
    var radius: float = Sc.ann_params.edge_start_radius * SCALE * Sc.gui.scale
    Sc.draw.draw_origin_marker(
            self,
            center,
            color,
            radius,
            Sc.ann_params.edge_waypoint_stroke_width,
            SECTOR_ARC_LENGTH)
