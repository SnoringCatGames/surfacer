extends Node2D
class_name IntraEdgeCalculationAnnotator

var graph: PlatformGraph
var trajectory_annotator: IntraEdgeCalculationTrajectoryAnnotator
var tree_view_annotator: IntraEdgeCalculationTreeViewAnnotator

func _init(graph: PlatformGraph) -> void:
    self.graph = graph
    self.trajectory_annotator = IntraEdgeCalculationTrajectoryAnnotator.new(graph)
    self.tree_view_annotator = IntraEdgeCalculationTreeViewAnnotator.new(graph)

func _enter_tree() -> void:
    add_child(trajectory_annotator)
    add_child(tree_view_annotator)
    
    tree_view_annotator.connect("step_selected", trajectory_annotator, "on_step_selected")
