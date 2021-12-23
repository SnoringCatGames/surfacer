class_name ContinuousEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := "CONTINUOUS_EDGE_TRAJECTORY"
const TEXT := "Edge trajectory\n(continuous)"
var COLOR_PARAMS: ColorParams = Sc.ann_params \
        .default_edge_continuous_trajectory_color_params


func _init().(
        TYPE,
        TEXT,
        COLOR_PARAMS) -> void:
    pass
