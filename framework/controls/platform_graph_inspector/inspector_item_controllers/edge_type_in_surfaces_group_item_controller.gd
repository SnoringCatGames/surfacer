extends InspectorItemController
class_name EdgeTypeInSurfacesGroupItemController

const TYPE := InspectorItemType.EDGE_TYPE_IN_SURFACES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<Edge>
var valid_edges: Array
# Array<FailedEdgeAttempt>
var failed_edges: Array
# Array<JumpLandPositions>
var all_jump_land_positions: Array

var failed_edges_controller: FailedEdgesGroupItemController

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        valid_edges: Array, \
        failed_edges: Array, \
        all_jump_land_positions: Array) \
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
    self.valid_edges = valid_edges
    self.failed_edges = failed_edges
    self.all_jump_land_positions = all_jump_land_positions
    _post_init()

func to_string() -> String:
    return "%s { edge_type=%s, valid_edge_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge_type), \
        valid_edges.size(), \
    ]

func get_text() -> String:
    return "%ss [%s]" % [ \
        EdgeType.get_type_string(edge_type), \
        valid_edges.size(), \
    ]

func get_description() -> String:
    return EdgeType.get_description_string(edge_type)

func get_has_children() -> bool:
    return valid_edges.size() > 0 or failed_edges.size() > 0

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
    for edge in valid_edges:
        ValidEdgeItemController.new( \
                tree_item, \
                tree, \
                graph, \
                edge)
    
    failed_edges_controller = FailedEdgesGroupItemController.new( \
            tree_item, \
            tree, \
            graph, \
            origin_surface, \
            destination_surface, \
            edge_type, \
            failed_edges, \
            valid_edges, \
            all_jump_land_positions)

func _destroy_children_inner() -> void:
    failed_edges_controller = null

func get_annotation_elements() -> Array:
    var elements := []
    var element: AnnotationElement
    
    element = OriginSurfaceAnnotationElement.new(origin_surface)
    elements.push_back(element)
    
    element = DestinationSurfaceAnnotationElement.new(destination_surface)
    elements.push_back(element)
    
    for jump_land_positions in all_jump_land_positions:
        element = JumpLandPositionsAnnotationElement.new( \
                jump_land_positions, \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_COLOR_PARAMS, \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_LENGTH, \
                AnnotationElementDefaults.JUMP_LAND_POSITIONS_DASH_GAP, \
                AnnotationElementDefaults \
                        .JUMP_LAND_POSITIONS_DASH_STROKE_WIDTH)
        elements.push_back(element)
    
    return elements
