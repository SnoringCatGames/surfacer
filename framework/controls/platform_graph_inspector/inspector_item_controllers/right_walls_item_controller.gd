extends SurfacesOfSideGroupItemController
class_name RightWallsItemController

const TYPE := InspectorItemType.RIGHT_WALLS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.RIGHT_WALL

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        TYPE, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph, \
        SIDE, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges) -> void:
    pass

func get_description() -> String:
    return "A right wall is on the right side of the player when the player " + \
            "stands along the outside of the surface. The wall is " + \
            "actually the left side of the level shape that it's a part of."
