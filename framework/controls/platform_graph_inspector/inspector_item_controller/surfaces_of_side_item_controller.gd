extends InspectorItemController
class_name SurfacesOfSideGroupItemController

const IS_LEAF := false

var side := SurfaceSide.NONE
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<Edge>>>>
var surfaces_to_surfaces_to_edge_types_to_valid_edges := {}
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<FailedEdgeAttempt>>>>
var surfaces_to_surfaces_to_edge_types_to_failed_edges := {}
var surface_count := 0 

func _init( \
        type: int, \
        starts_collapsed: bool, \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        side: int, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        type, \
        IS_LEAF, \
        starts_collapsed, \
        parent_item, \
        tree, \
        graph) -> void:
    self.side = side
    self.surfaces_to_surfaces_to_edge_types_to_valid_edges = \
            surfaces_to_surfaces_to_edge_types_to_valid_edges
    self.surfaces_to_surfaces_to_edge_types_to_failed_edges = \
            surfaces_to_surfaces_to_edge_types_to_failed_edges
    self.surface_count = graph.counts[SurfaceSide.get_side_string(side)]
    _post_init()

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

func get_has_children() -> bool:
    return surface_count > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    expand()
    call_deferred( \
            "find_and_expand_controller_recursive", \
            search_type, \
            metadata)
    return true

func find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if is_subtree_found:
            return
        child = child.get_next()
    select()
    Utils.error("No matching Surface found: %s" % metadata)

func _create_children_inner() -> void:
    var surfaces_to_edge_types_to_valid_edges: Dictionary
    var surfaces_to_edge_types_to_failed_edges: Dictionary
    for surface in graph.surfaces_set:
        if surface.side == side:
            surfaces_to_edge_types_to_valid_edges = \
                    surfaces_to_surfaces_to_edge_types_to_valid_edges[surface] if \
                    surfaces_to_surfaces_to_edge_types_to_valid_edges.has(surface) else \
                    {}
            surfaces_to_edge_types_to_failed_edges = \
                    surfaces_to_surfaces_to_edge_types_to_failed_edges[surface] if \
                    surfaces_to_surfaces_to_edge_types_to_failed_edges.has(surface) else \
                    {}
            OriginSurfaceItemController.new( \
                    tree_item, \
                    tree, \
                    graph, \
                    surface, \
                    surfaces_to_edge_types_to_valid_edges, \
                    surfaces_to_edge_types_to_failed_edges)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: SurfaceAnnotationElement
    for surface in graph.surfaces_set:
        if surface.side == side:
            element = SurfaceAnnotationElement.new( \
                    surface, \
                    AnnotationElementDefaults.SURFACE_COLOR_PARAMS, \
                    AnnotationElementDefaults.SURFACE_DEPTH)
            elements.push_back(element)
    return elements
