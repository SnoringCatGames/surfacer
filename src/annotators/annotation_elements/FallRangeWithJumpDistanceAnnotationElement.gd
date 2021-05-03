class_name FallRangeWithJumpDistanceAnnotationElement
extends PolylineAnnotationElement

const TYPE := AnnotationElementType.FALL_RANGE_WITH_JUMP_DISTANCE
const LEGEND_ITEM_CLASS_REFERENCE := FallRangeWithJumpDistanceLegendItem

func _init(
        vertices: Array,
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
        LEGEND_ITEM_CLASS_REFERENCE,
        vertices,
        color_params,
        is_filled,
        is_dashed,
        dash_length,
        dash_gap,
        stroke_width) -> void:
    pass
