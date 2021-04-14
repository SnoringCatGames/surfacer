class_name FallRangeWithJumpDistanceLegendItem
extends PolylineLegendItem

const TYPE := LegendItemType.FALL_RANGE_WITH_JUMP_DISTANCE
const TEXT := "Fall range with\njump distance"

func _init(
        color_params := Surfacer.ann_defaults \
                .DEFAULT_POLYLINE_COLOR_PARAMS,
        is_filled := false,
        is_dashed := false,
        dash_length := \
                AnnotationElementDefaults.DEFAULT_POLYLINE_DASH_LENGTH,
        dash_gap := \
                AnnotationElementDefaults.DEFAULT_POLYLINE_DASH_GAP,
        stroke_width := AnnotationElementDefaults \
                .DEFAULT_POLYLINE_STROKE_WIDTH) \
        .(
        TYPE,
        TEXT,
        color_params,
        is_filled,
        is_dashed,
        dash_length,
        dash_gap,
        stroke_width) -> void:
    pass
