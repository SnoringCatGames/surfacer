class_name CeilingsItemController
extends SurfacesOfSideGroupItemController

const TYPE := InspectorItemType.CEILINGS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.CEILING

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
    return ("There are %s ceiling surfaces in the plaform graph for the %s " + \
            "player.") % [
        surface_count,
        graph.movement_params.name,
    ]
