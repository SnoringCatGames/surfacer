class_name ContinuousEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := "CONTINUOUS_EDGE_TRAJECTORY"
const TEXT := "Edge trajectory\n(continuous)"
var COLOR_CONFIG: ColorConfig = Sc.ann_params \
        .default_edge_continuous_trajectory_color_config


func _init().(
        TYPE,
        TEXT,
        COLOR_CONFIG) -> void:
    pass
