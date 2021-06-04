class_name EdgesWithIncreasingJumpHeightGroupItemController
extends EdgesFilteredByResultTypeGroupItemController


const TYPE := InspectorItemType.EDGES_WITH_INCREASING_JUMP_HEIGHT_GROUP
const EDGE_CALC_RESULT_TYPE := \
        EdgeCalcResultType.EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT
const TEXT := "Edges calculated with increasing jump height"


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
    return ("Some edge calculations need to backtrack and consider a " +
            "higher jump height midway through the calculation. " +
            "There are %s valid edges that were calculated with " +
            "backtracking to increase their jump height.") % [
                filtered_edge_count,
            ]
