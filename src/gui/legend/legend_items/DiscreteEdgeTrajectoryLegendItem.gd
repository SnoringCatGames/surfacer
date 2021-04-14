class_name DiscreteEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem

const TYPE := LegendItemType.DISCRETE_EDGE_TRAJECTORY
const TEXT := "Edge trajectory\n(discrete)"
var COLOR_PARAMS: ColorParams = \
        Surfacer.ann_defaults.DEFAULT_EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS

func _init().(
        TYPE,
        TEXT,
        COLOR_PARAMS) -> void:
    pass
