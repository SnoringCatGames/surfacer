class_name EdgeTypeInSurfacesGroupItemController
extends InspectorItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_SURFACES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
var edges_results: InterSurfaceEdgesResult

var failed_edges_controller: FailedEdgesGroupItemController

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        edges_results: InterSurfaceEdgesResult) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_type = edge_type
    self.edges_results = edges_results
    _post_init()

func to_string() -> String:
    return "%s { edge_type=%s, valid_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge_type), \
        edges_results.valid_edges.size(), \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        edges_results.valid_edges.size(), \
    ]

func get_description() -> String:
    return EdgeType.get_description_string(edge_type)

func get_has_children() -> bool:
    return !edges_results.valid_edges.empty() or \
            !edges_results.failed_edge_attempts.empty()

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    if metadata.edge_type == edge_type:
        expand()
        _trigger_find_and_expand_controller_recursive( \
                search_type, \
                metadata)
        return true
    else:
        return false

func _find_and_expand_controller_recursive( \
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
    for valid_edge in edges_results.valid_edges:
        ValidEdgeItemController.new( \
                tree_item, \
                tree, \
                graph, \
                valid_edge)
    
    failed_edges_controller = FailedEdgesGroupItemController.new( \
            tree_item, \
            tree, \
            graph, \
            origin_surface, \
            destination_surface, \
            edge_type, \
            edges_results)

func _destroy_children_inner() -> void:
    failed_edges_controller = null

func get_annotation_elements() -> Array:
    var elements := []
    var element: AnnotationElement
    
    element = OriginSurfaceAnnotationElement.new(origin_surface)
    elements.push_back(element)
    
    element = DestinationSurfaceAnnotationElement.new(destination_surface)
    elements.push_back(element)
    
    for jump_land_positions in edges_results.all_jump_land_positions:
        element = JumpLandPositionsAnnotationElement.new( \
                jump_land_positions, \
                Surfacer.ann_defaults.JUMP_LAND_POSITIONS_COLOR_PARAMS, \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_LENGTH, \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_GAP, \
                AnnotationElementDefaults \
                        .JUMP_LAND_POSITIONS_DASH_STROKE_WIDTH)
        elements.push_back(element)
    
    return elements
