extends InspectorItemController
class_name OriginSurfaceItemController

const TYPE := InspectorItemType.ORIGIN_SURFACE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
# Dictionary<Surface, Dictionary<EdgeType, Array<Edge>>>
var destination_surfaces_to_edge_types_to_valid_edges := {}
# Dictionary<Surface, Dictionary<EdgeType, Array<FailedEdgeAttempt>>>
var destination_surfaces_to_edge_types_to_failed_edges := {}
# Array<Surface>
var attempted_destination_surfaces := []
var valid_edge_count := 0
var failed_edge_count := 0

var valid_edges_count_item_controller: DescriptionItemController
var destination_surfaces_description_item_controller: DescriptionItemController

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        destination_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surfaces_to_edge_types_to_valid_edges = \
            destination_surfaces_to_edge_types_to_valid_edges
    self.destination_surfaces_to_edge_types_to_failed_edges = \
            destination_surfaces_to_edge_types_to_failed_edges
    _calculate_metadata()
    _post_init()

func _calculate_metadata() -> void:
    # Count the valid and failed edges from this surface.
    var edge_types_to_edges: Dictionary
    valid_edge_count = 0
    for destination_surface in destination_surfaces_to_edge_types_to_valid_edges:
        edge_types_to_edges = \
                destination_surfaces_to_edge_types_to_valid_edges[destination_surface]
        for edge_type in edge_types_to_edges:
            valid_edge_count += edge_types_to_edges[edge_type].size()
    failed_edge_count = 0
    for destination_surface in destination_surfaces_to_edge_types_to_failed_edges:
        edge_types_to_edges = \
                destination_surfaces_to_edge_types_to_failed_edges[destination_surface]
        for edge_type in edge_types_to_edges:
            failed_edge_count += edge_types_to_edges[edge_type].size()
    
    # Populate a sorted list of all attempted destination edges.
    attempted_destination_surfaces.clear()
    for destination_surface in destination_surfaces_to_edge_types_to_failed_edges:
        attempted_destination_surfaces.push_back(destination_surface)
    for destination_surface in destination_surfaces_to_edge_types_to_valid_edges:
        if !destination_surfaces_to_edge_types_to_failed_edges.has(destination_surface):
            attempted_destination_surfaces.push_back(destination_surface)
    attempted_destination_surfaces.sort_custom( \
            SurfaceHorizontalPositionComparator, \
            "sort")

func to_string() -> String:
    return "%s{ [%s, %s] }" % [ \
        InspectorItemType.get_type_string(TYPE), \
        str(origin_surface.first_point), \
        str(origin_surface.last_point), \
    ]

func get_text() -> String:
    return "[%s, %s]" % [ \
        str(origin_surface.first_point), \
        str(origin_surface.last_point), \
    ]

func get_description() -> String:
    return ("There are %s valid outbound edges from this %s surface.") % [ \
        valid_edge_count, \
        SurfaceSide.get_side_string(origin_surface.side), \
    ]

func get_has_children() -> bool:
    return destination_surfaces_to_edge_types_to_valid_edges.size() > 0 or \
            destination_surfaces_to_edge_types_to_failed_edges.size() > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    if search_type == InspectorSearchType.SURFACE:
        if metadata.surface == origin_surface:
            expand()
            select()
            return true
        else:
            return false
    else:
        if metadata.origin_surface == origin_surface:
            expand()
            call_deferred( \
                    "find_and_expand_controller_recursive", \
                    search_type, \
                    metadata)
            return true
        else:
            return false

func find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    assert(search_type == InspectorSearchType.EDGE)
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

func _create_children_inner() -> void:
    valid_edges_count_item_controller = DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            "_%s valid outbound edges_" % valid_edge_count, \
            get_description(), \
            funcref(self, "_get_annotation_elements_for_valid_edges_count_description_item"))
    destination_surfaces_description_item_controller = DescriptionItemController.new( \
            tree_item, \
            tree, \
            graph, \
            "_Destination surfaces:_", \
            get_description(), \
            funcref(self, "_get_annotation_elements_for_destination_surfaces_description_item"))
    
    var edge_types_to_valid_edges: Dictionary
    var edge_types_to_failed_edges: Dictionary
    for destination_surface in attempted_destination_surfaces:
        edge_types_to_valid_edges = \
                destination_surfaces_to_edge_types_to_valid_edges[destination_surface] if \
                destination_surfaces_to_edge_types_to_valid_edges.has(destination_surface) else \
                {}
        edge_types_to_failed_edges = \
                destination_surfaces_to_edge_types_to_failed_edges[destination_surface] if \
                destination_surfaces_to_edge_types_to_failed_edges.has(destination_surface) else \
                {}
        DestinationSurfaceItemController.new( \
                tree_item, \
                tree, \
                graph, \
                origin_surface, \
                destination_surface, \
                edge_types_to_valid_edges, \
                edge_types_to_failed_edges)

func _destroy_children_inner() -> void:
    valid_edges_count_item_controller = null
    destination_surfaces_description_item_controller = null

func get_annotation_elements() -> Array:
    var element := OriginSurfaceAnnotationElement.new(origin_surface)
    return [element]

func _get_annotation_elements_for_valid_edges_count_description_item() -> Array:
    var elements := get_annotation_elements()
    var element: EdgeAnnotationElement
    var edge: Edge
    for destination_surface in destination_surfaces_to_edge_types_to_valid_edges:
        for edge_type in destination_surfaces_to_edge_types_to_valid_edges[destination_surface]:
            for edge in destination_surfaces_to_edge_types_to_valid_edges[destination_surface][edge_type]:
                element = EdgeAnnotationElement.new( \
                        edge, \
                        true, \
                        false, \
                        false)
                elements.push_back(element)
    return elements

func _get_annotation_elements_for_destination_surfaces_description_item() -> Array:
    var elements := get_annotation_elements()
    var element: SurfaceAnnotationElement
    for destination_surface in attempted_destination_surfaces:
        element = DestinationSurfaceAnnotationElement.new(destination_surface)
        elements.push_back(element)
    return elements

class SurfaceHorizontalPositionComparator:
    static func sort( \
            a: Surface, \
            b: Surface) -> bool:
        return a.bounding_box.position.x < b.bounding_box.position.x if \
                a.bounding_box.position.x != b.bounding_box.position.x else \
                a.bounding_box.end.x != b.bounding_box.end.x
