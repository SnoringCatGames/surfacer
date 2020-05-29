extends LegendItem
class_name FailedEdgeTrajectoryLegendItem

const TYPE := LegendItemType.FAILED_EDGE_TRAJECTORY
const TEXT := "Failed\nedge"

const X_WIDTH := 7.5
const X_HEIGHT := 10.5
const DASH_LENGTH := 3.0
const DASH_GAP := 4.0
const STROKE_WIDTH := 1.3

func _init().( \
        TYPE, \
        TEXT) -> void:
    pass

func _draw_shape(
        center: Vector2, \
        size: Vector2) -> void:
    var offset_from_center := size * 0.35 - Vector2(0.0, 6.0)
    var start := center - offset_from_center
    var end := center + offset_from_center
    var color: Color = AnnotationElementDefaults \
            .FAILED_EDGE_ATTEMPT_COLOR_PARAMS.get_color()
    DrawUtils.draw_dashed_line( \
            self, \
            start, \
            end, \
            color, \
            DASH_LENGTH, \
            DASH_GAP, \
            0.0, \
            STROKE_WIDTH)
    DrawUtils.draw_x( \
            self, \
            center, \
            X_WIDTH, \
            X_HEIGHT, \
            color, \
            STROKE_WIDTH)
