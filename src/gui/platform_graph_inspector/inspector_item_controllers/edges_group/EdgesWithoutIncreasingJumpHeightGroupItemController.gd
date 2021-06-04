class_name EdgesWithoutIncreasingJumpHeightGroupItemController
extends EdgesFilteredByResultTypeGroupItemController

const TYPE := InspectorItemType.EDGES_WITHOUT_INCREASING_JUMP_HEIGHT_GROUP
const EDGE_CALC_RESULT_TYPE := \
        EdgeCalcResultType.EDGE_VALID_WITHOUT_INCREASING_JUMP_HEIGHT
const TEXT := "Edges calculated without increasing jump height"


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
    return ("Some edge calculations need to consider extra movement " +
            "around surface ends (waypoints) in order to avoid " +
            "collisions. " +
            "There are %s valid edges that were calculated with " +
            "intermediate waypoints and without backtracking to increase " +
            "their jump height.") % [
                filtered_edge_count,
            ]
