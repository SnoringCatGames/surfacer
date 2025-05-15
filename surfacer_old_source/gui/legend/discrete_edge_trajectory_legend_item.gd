class_name DiscreteEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := "DISCRETE_EDGE_TRAJECTORY"
const TEXT := "Edge trajectory\n(discrete)"
var COLOR: Color = \
        Sc.palette.get_color("default_edge_discrete_trajectory_color")


func _init().(
        TYPE,
        TEXT,
        COLOR) -> void:
    pass
