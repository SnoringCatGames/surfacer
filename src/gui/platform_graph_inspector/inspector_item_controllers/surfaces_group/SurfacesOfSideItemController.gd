class_name SurfacesOfSideGroupItemController
extends InspectorItemController

const IS_LEAF := false

var side := SurfaceSide.NONE
# Dictionary<Surface, Dictionary<Surface, Dictionary<int,
#         Array<InterSurfaceEdgesResult>>>>
var surfaces_to_surfaces_to_edge_types_to_edges_results := {}
var surface_count := 0

func _init( \
        type: int,
        starts_collapsed: bool,
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        side: int,
        surfaces_to_surfaces_to_edge_types_to_edges_results: Dictionary) \
        .( \
        type,
        IS_LEAF,
        starts_collapsed,
        parent_item,
        tree,
        graph) -> void:
    self.side = side
    self.surfaces_to_surfaces_to_edge_types_to_edges_results = \
            surfaces_to_surfaces_to_edge_types_to_edges_results
    self.surface_count = graph.counts[SurfaceSide.get_string(side)]
    _post_init()

func to_string() -> String:
    return "%s { surface_count=%s }" % [
        InspectorItemType.get_string(type),
        surface_count,
    ]

func get_text() -> String:
    return "%ss [%s]" % [
        SurfaceSide.get_string(side),
        surface_count,
    ]

func get_has_children() -> bool:
    return surface_count > 0

func find_and_expand_controller( \
        search_type: int,
        metadata: Dictionary) -> bool:
    expand()
    _trigger_find_and_expand_controller_recursive( \
            search_type,
            metadata)
    return true

func _find_and_expand_controller_recursive( \
        search_type: int,
        metadata: Dictionary) -> void:
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller( \
                search_type,
                metadata)
        if is_subtree_found:
            return
        child = child.get_next()
    select()
    Gs.logger.error("No matching Surface found: %s" % metadata)

func _create_children_inner() -> void:
    var surfaces_to_edge_types_to_edges_results: Dictionary
    for surface in graph.surfaces_set:
        if surface.side == side:
            surfaces_to_edge_types_to_edges_results = \
                    surfaces_to_surfaces_to_edge_types_to_edges_results \
                            [surface] if \
                    surfaces_to_surfaces_to_edge_types_to_edges_results.has( \
                            surface) else \
                    {}
            OriginSurfaceItemController.new( \
                    tree_item,
                    tree,
                    graph,
                    surface,
                    surfaces_to_edge_types_to_edges_results)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: SurfaceAnnotationElement
    for surface in graph.surfaces_set:
        if surface.side == side:
            element = SurfaceAnnotationElement.new(surface)
            elements.push_back(element)
    return elements
