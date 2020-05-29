extends ValidEdgeTrajectoryLegendItem
class_name DiscreteEdgeTrajectoryLegendItem

const TYPE := LegendItemType.DISCRETE_EDGE_TRAJECTORY
const TEXT := "Edge\ntrajectory (disc.)"
var COLOR_PARAMS: ColorParams = \
        AnnotationElementDefaults.DEFAULT_EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS

func _init().( \
        TYPE, \
        TEXT, \
        COLOR_PARAMS) -> void:
    pass
