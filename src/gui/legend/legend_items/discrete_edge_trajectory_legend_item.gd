class_name DiscreteEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := LegendItemType.DISCRETE_EDGE_TRAJECTORY
const TEXT := "Edge trajectory\n(discrete)"
var COLOR_PARAMS: ColorParams = \
        Sc.ann_params.default_edge_discrete_trajectory_color_params


func _init().(
        TYPE,
        TEXT,
        COLOR_PARAMS) -> void:
    pass
