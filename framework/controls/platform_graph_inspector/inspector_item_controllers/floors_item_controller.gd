extends SurfacesOfSideGroupItemController
class_name FloorsItemController

const TYPE := InspectorItemType.FLOORS
const STARTS_COLLAPSED := true
const SIDE := SurfaceSide.FLOOR

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
    return ("There are %s floor surfaces in the plaform graph for the %s " + \
            "player.") % [ \
        surface_count, \
        graph.movement_params.name, \
    ]
