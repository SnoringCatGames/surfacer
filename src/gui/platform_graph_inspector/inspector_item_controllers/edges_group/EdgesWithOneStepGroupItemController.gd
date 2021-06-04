class_name EdgesWithOneStepGroupItemController
extends EdgesFilteredByResultTypeGroupItemController

const TYPE := InspectorItemType.EDGES_WITH_ONE_STEP_GROUP
const EDGE_CALC_RESULT_TYPE := EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP
const TEXT := "Edges calculated with one step"


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph) \
        .(
        TYPE,
        parent_item,
        tree,
        graph,
        EDGE_CALC_RESULT_TYPE,
        TEXT) -> void:
    pass


func get_description() -> String:
    return ("Some edges can be calculated with only a single horizontal " +
            "step, which does not need to move around any surface ends " +
            "(waypoints) to avoid collisions. " +
            "There are %s edges that were calculated with a single " +
            "horizontal step.") % [
                filtered_edge_count,
            ]
