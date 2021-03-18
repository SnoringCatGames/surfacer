extends LegendItem
class_name OriginLegendItem

const TYPE := LegendItemType.ORIGIN
const TEXT := "Origin"

const SCALE := 0.8
const SECTOR_ARC_LENGTH := 2.2

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape( \
        center: Vector2, \
        size: Vector2) -> void:
    var color: Color = \
            AnnotationElementDefaults.DEFAULT_WAYPOINT_COLOR_PARAMS.get_color()
    var radius: float = DrawUtils.EDGE_START_RADIUS * SCALE
    DrawUtils.draw_origin_marker( \
            self, \
            center, \
            color, \
            radius, \
            DrawUtils.EDGE_WAYPOINT_STROKE_WIDTH, \
            SECTOR_ARC_LENGTH)
