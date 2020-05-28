extends LegendItem
class_name DestinationLegendItem

const TYPE := LegendItemType.DESTINATION
const TEXT := "Destination"

const SCALE := 0.8

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    var radius := DrawUtils.EDGE_END_RADIUS * SCALE
    var length := \
            (DrawUtils.EDGE_END_RADIUS + DrawUtils.EDGE_END_CONE_LENGTH) * \
            SCALE
    var cone_end_point := Vector2( \
            center.x, \
            center.y + length / 2.0)
    var circle_center := Vector2( \
            center.x, \
            center.y - length / 2.0 + radius)
    
    DrawUtils.draw_ice_cream_cone( \
            self, \
            cone_end_point, \
            circle_center, \
            radius, \
            AnnotationElementDefaults.EDGE_COLOR_PARAMS.get_color(), \
            false, \
            DrawUtils.EDGE_WAYPOINT_STROKE_WIDTH, \
            4.0)
