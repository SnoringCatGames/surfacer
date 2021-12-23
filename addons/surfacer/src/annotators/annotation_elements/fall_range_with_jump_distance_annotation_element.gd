class_name FallRangeWithJumpDistanceAnnotationElement
extends PolylineAnnotationElement


const TYPE := AnnotationElementType.FALL_RANGE_WITH_JUMP_DISTANCE
const LEGEND_ITEM_CLASS_REFERENCE := FallRangeWithJumpDistanceLegendItem


func _init(
        vertices: Array,
        color_params := Sc.ann_params \
                .default_polyline_color_params,
        is_filled := false,
        is_dashed := false,
        dash_length := \
                Sc.ann_params.default_polyline_dash_length,
        dash_gap := \
                Sc.ann_params.default_polyline_dash_gap,
        stroke_width := Sc.ann_params \
                .default_polyline_stroke_width) \
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
