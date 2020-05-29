extends ValidEdgeTrajectoryLegendItem
class_name ContinuousEdgeTrajectoryLegendItem

const TYPE := LegendItemType.CONTINUOUS_EDGE_TRAJECTORY
const TEXT := "Edge\ntrajectory (cont.)"
var COLOR_PARAMS: ColorParams = AnnotationElementDefaults \
        .DEFAULT_EDGE_CONTINUOUS_TRAJECTORY_COLOR_PARAMS

func _init().( \
        TYPE, \
        TEXT, \
        COLOR_PARAMS) -> void:
    pass
