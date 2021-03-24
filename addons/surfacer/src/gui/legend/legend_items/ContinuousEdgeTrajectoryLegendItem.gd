extends ValidEdgeTrajectoryLegendItem
class_name ContinuousEdgeTrajectoryLegendItem

const TYPE := LegendItemType.CONTINUOUS_EDGE_TRAJECTORY
const TEXT := "Edge trajectory\n(continuous)"
var COLOR_PARAMS: ColorParams = Surfacer.ann_defaults \
        .DEFAULT_EDGE_CONTINUOUS_TRAJECTORY_COLOR_PARAMS

func _init().( \
        TYPE, \
        TEXT, \
        COLOR_PARAMS) -> void:
    pass
