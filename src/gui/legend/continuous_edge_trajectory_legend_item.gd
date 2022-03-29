class_name ContinuousEdgeTrajectoryLegendItem
extends ValidEdgeTrajectoryLegendItem


const TYPE := "CONTINUOUS_EDGE_TRAJECTORY"
const TEXT := "Edge trajectory\n(continuous)"
var COLOR: Color = \
        Sc.palette.get_color("default_edge_continuous_trajectory_color")


func _init().(
        TYPE,
        TEXT,
        COLOR) -> void:
    pass
