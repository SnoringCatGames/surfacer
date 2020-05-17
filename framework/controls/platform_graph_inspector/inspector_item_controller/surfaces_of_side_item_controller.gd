extends InspectorItemController
class_name SurfacesOfSideGroupItemController

var graph: PlatformGraph
var side := SurfaceSide.NONE
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<Edge>>>>
var surfaces_to_surfaces_to_edge_types_to_valid_edges := {}
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<FailedEdgeAttempt>>>>
var surfaces_to_surfaces_to_edge_types_to_failed_edges := {}
var surface_count := 0 

func _init( \
        type: int, \
        starts_collapsed: bool, \
        tree_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        side: int, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        type, \
        starts_collapsed, \
        tree_item, \
        tree) -> void:
    self.graph = graph
    self.side = side
    self.surfaces_to_surfaces_to_edge_types_to_valid_edges = \
            surfaces_to_surfaces_to_edge_types_to_valid_edges
    self.surfaces_to_surfaces_to_edge_types_to_failed_edges = \
            surfaces_to_surfaces_to_edge_types_to_failed_edges
    self.surface_count = graph.counts[SurfaceSide.get_side_string(side)]
    _update_text()

func to_string() -> String:
    return "%s { surface_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        surface_count, \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        SurfaceSide.get_side_string(side), \
        surface_count, \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> InspectorItemController:
    expand()
    
    var result: InspectorItemController
    for child in tree_item.get_children():
        result = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if result != null:
            return result
    return null

func _create_children() -> void:
    for surface in graph.surfaces_set:
        if surface.side == side:
            OriginSurfaceItemController.new( \
                    tree_item, \
                    tree, \
                    surface, \
                    surfaces_to_surfaces_to_edge_types_to_valid_edges[surface], \
                    surfaces_to_surfaces_to_edge_types_to_failed_edges[surface])

func _destroy_children() -> void:
    for child in tree_item.get_children():
        child.get_metadata(0).destroy()
    surface_count = 0

func _draw_annotations() -> void:
    # FIXME: -----------------
    pass
