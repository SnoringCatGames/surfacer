extends LegendItem
class_name OriginLegendItem

const TYPE := LegendItemType.ORIGIN
const TEXT := "Origin"

const SCALE := 0.8

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    # FIXME: -----------------------
    pass
    DrawUtils.draw_circle_outline( \
            self, \
            center, \
            DrawUtils.EDGE_START_RADIUS * SCALE, \
            AnnotationElementDefaults.EDGE_COLOR_PARAMS.get_color(), \
            DrawUtils.EDGE_WAYPOINT_STROKE_WIDTH, \
            3.0)
