class_name DiscreteEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := "DISCRETE_EDGE_TRAJECTORY"
const TEXT := "Edge trajectory\n(discrete)"
var COLOR_CONFIG: ColorConfig = \
        Sc.annotators.params.default_edge_discrete_trajectory_color_config


func _init().(
        TYPE,
        TEXT,
        COLOR_CONFIG) -> void:
    pass
