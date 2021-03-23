extends LegendItem
class_name DestinationLegendItem

const TYPE := LegendItemType.DESTINATION
const TEXT := "Destination"

const SCALE := 0.8
const SECTOR_ARC_LENGTH := 2.2

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    var cone_length: float = SurfacerDrawUtils.EDGE_END_CONE_LENGTH * SCALE
    var radius: float = SurfacerDrawUtils.EDGE_END_RADIUS * SCALE
    var length := cone_length + radius
    var cone_end_point := Vector2( \
            center.x, \
            center.y + length / 2.0)
    var color: Color = \
            AnnotationElementDefaults.DEFAULT_WAYPOINT_COLOR_PARAMS.get_color()
    
    Gs.draw_utils.draw_destination_marker( \
            self, \
            cone_end_point, \
            false, \
            SurfaceSide.FLOOR, \
            color, \
            cone_length, \
            radius, \
            false, \
            SurfacerDrawUtils.EDGE_WAYPOINT_STROKE_WIDTH, \
            SECTOR_ARC_LENGTH)
