class_name FallRangeWithoutJumpDistanceAnnotationElement
extends PolylineAnnotationElement


const TYPE := AnnotationElementType.FALL_RANGE_WITHOUT_JUMP_DISTANCE
const LEGEND_ITEM_CLASS_REFERENCE := FallRangeWithoutJumpDistanceLegendItem


func _init(
        vertices: Array,
        color := Sc.palette.get_color("default_polyline_color"),
        is_filled := false,
        is_dashed := false,
        dash_length := Sc.annotators.params.default_polyline_dash_length,
        dash_gap := Sc.annotators.params.default_polyline_dash_gap,
        stroke_width := Sc.annotators.params.default_polyline_stroke_width) \
        .(
        TYPE,
        LEGEND_ITEM_CLASS_REFERENCE,
        vertices,
        color,
        is_filled,
        is_dashed,
        dash_length,
        dash_gap,
        stroke_width) -> void:
    pass
