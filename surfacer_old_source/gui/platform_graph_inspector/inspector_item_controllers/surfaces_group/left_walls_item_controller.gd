class_name LeftWallsItemController
extends SurfacesOfSideGroupItemController


const TYPE := InspectorItemType.LEFT_WALLS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.LEFT_WALL


func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        surfaces_to_surfaces_to_edge_types_to_edges_results: Dictionary) \
        .(
        TYPE,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph,
        SIDE,
        surfaces_to_surfaces_to_edge_types_to_edges_results) -> void:
    pass


func get_description() -> String:
    return ("A left wall is on the left side of the character when the " +
            "character stands along the outside of the surface. The wall is " +
            "actually the right side of the level shape that it's a part of.")
