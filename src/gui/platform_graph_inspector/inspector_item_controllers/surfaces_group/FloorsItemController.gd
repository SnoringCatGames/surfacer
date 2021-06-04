class_name FloorsItemController
extends SurfacesOfSideGroupItemController

const TYPE := InspectorItemType.FLOORS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.FLOOR


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
    return ("There are %s floor surfaces in the plaform graph for the %s " +
            "player.") % [
        surface_count,
        graph.movement_params.name,
    ]
