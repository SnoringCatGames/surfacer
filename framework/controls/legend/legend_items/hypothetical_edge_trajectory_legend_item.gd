extends LegendItem
class_name HypotheticalEdgeTrajectoryLegendItem

const TYPE := LegendItemType.HYPOTHETICAL_EDGE_TRAJECTORY
const TEXT := "Hypothetical\nedge"

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    var offset_from_center := size * 0.35
    var start := center - offset_from_center
    var end := center + offset_from_center
    DrawUtils.draw_dashed_line( \
            self, \
            start, \
            end, \
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_COLOR_PARAMS \
                    .get_color(), \
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH, \
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP, \
            0.0, \
            AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH)
