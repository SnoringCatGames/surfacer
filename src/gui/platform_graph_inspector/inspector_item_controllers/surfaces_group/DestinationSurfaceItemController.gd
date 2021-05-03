class_name DestinationSurfaceItemController
extends InspectorItemController

const TYPE := InspectorItemType.DESTINATION_SURFACE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
# Dictionary<EdgeType, Array<InterSurfaceEdgesResult>>
var edge_types_to_edges_results: Dictionary
var valid_edge_count: int
var failed_edge_count: int

func _init(
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        origin_surface: Surface,
        destination_surface: Surface,
        edge_types_to_edges_results: Dictionary) \
        .(
        TYPE,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_types_to_edges_results = edge_types_to_edges_results
    _count_edges()
    _post_init()

func to_string() -> String:
    return "%s{ [%s, %s] }" % [
        InspectorItemType.get_string(TYPE),
        str(destination_surface.first_point),
        str(destination_surface.last_point),
    ]

func get_text() -> String:
    return "%s [%s, %s]" % [
        SurfaceSide.get_string(destination_surface.side),
        str(destination_surface.first_point),
        str(destination_surface.last_point),
    ]

func get_description() -> String:
    return ("There are %s valid edges from this %s to this %s.") % [
        valid_edge_count,
        SurfaceSide.get_string(origin_surface.side),
        SurfaceSide.get_string(destination_surface.side),
    ]

func find_and_expand_controller(
        search_type: int,
        metadata: Dictionary) -> bool:
    match search_type:
        InspectorSearchType.DESTINATION_SURFACE:
            if metadata.destination_surface == destination_surface:
                expand()
                select()
                return true
            else:
                return false
        InspectorSearchType.EDGE:
            if metadata.destination_surface == destination_surface:
                expand()
                _trigger_find_and_expand_controller_recursive(
                        search_type,
                        metadata)
                return true
            else:
                return false
        _:
            Gs.logger.error()
            return false

func _find_and_expand_controller_recursive(
        search_type: int,
        metadata: Dictionary) -> void:
    assert(search_type == InspectorSearchType.EDGE)
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller(
                search_type,
                metadata)
        if is_subtree_found:
            return
        child = child.get_next()
    select()

func _create_children_inner() -> void:
    var calculator: EdgeCalculator
    
    for edge_type in EdgeType.values():
        if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        if edge_types_to_edges_results.has(edge_type):
            for edges_result in edge_types_to_edges_results[edge_type]:
                calculator = graph.player_params.get_edge_calculator(edge_type)
                EdgeTypeInSurfacesGroupItemController.new(
                        tree_item,
                        tree,
                        graph,
                        origin_surface,
                        destination_surface,
                        edge_type,
                        edges_result)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    
    var origin_element := OriginSurfaceAnnotationElement.new(origin_surface)
    elements.push_back(origin_element)
    var destination_element := DestinationSurfaceAnnotationElement.new(
            destination_surface)
    elements.push_back(destination_element)
    
    var edge_element: EdgeAnnotationElement
    for edge_type in edge_types_to_edges_results:
        for edges_result in edge_types_to_edges_results[edge_type]:
            for valid_edge in edges_result.valid_edges:
                edge_element = EdgeAnnotationElement.new(
                        valid_edge,
                        true,
                        false,
                        true,
                        false)
                elements.push_back(edge_element)
    
    return elements

func _count_edges() -> void:
    valid_edge_count = 0
    failed_edge_count = 0
    for edge_type in edge_types_to_edges_results:
        for edges_result in edge_types_to_edges_results[edge_type]:
            valid_edge_count += edges_result.valid_edges.size()
            failed_edge_count += edges_result.failed_edge_attempts.size()
