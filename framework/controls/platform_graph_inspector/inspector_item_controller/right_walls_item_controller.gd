extends SurfacesOfSideGroupItemController
class_name RightWallsItemController

const TYPE := InspectorItemType.RIGHT_WALLS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.RIGHT_WALL

func _init( \
        tree_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        tree_item, \
        tree, \
        graph, \
        SIDE, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges) -> void:
    pass
