class_name FallRangeWithJumpDistanceLegendItem
extends PolylineLegendItem


const TYPE := "FALL_RANGE_WITH_JUMP_DISTANCE"
const TEXT := "Fall range with\njump distance"


func _init(
        color_config := Sc.annotators.params \
                .default_polyline_color_config,
        is_filled := false,
        is_dashed := false,
        dash_length := \
                Sc.annotators.params.default_polyline_dash_length,
        dash_gap := \
                Sc.annotators.params.default_polyline_dash_gap,
        stroke_width := Sc.annotators.params \
                .default_polyline_stroke_width) \
        .(
        TYPE,
        TEXT,
        color_config,
        is_filled,
        is_dashed,
        dash_length,
        dash_gap,
        stroke_width) -> void:
    pass
