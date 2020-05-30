extends InspectorItemController
class_name DestinationSurfaceItemController

const TYPE := InspectorItemType.DESTINATION_SURFACE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var origin_surface: Surface
var destination_surface: Surface
# Dictionary<EdgeType, Array<Edge>>
var edge_types_to_valid_edges: Dictionary
# Dictionary<EdgeType, Array<FailedEdgeAttempt>>
var edge_types_to_failed_edges: Dictionary
var valid_edge_count: int
var failed_edge_count: int
# Array<JumpLandPositions>
var jump_type_jump_land_positions: Array
# Array<JumpLandPositions>
var fall_type_jump_land_positions: Array

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_types_to_valid_edges: Dictionary, \
        edge_types_to_failed_edges: Dictionary) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.origin_surface = origin_surface
    self.destination_surface = destination_surface
    self.edge_types_to_valid_edges = edge_types_to_valid_edges
    self.edge_types_to_failed_edges = edge_types_to_failed_edges
    self.valid_edge_count = _count_edges(edge_types_to_valid_edges)
    self.failed_edge_count = _count_edges(edge_types_to_failed_edges)
    self.jump_type_jump_land_positions = JumpLandPositionsUtils \
            .calculate_jump_land_positions_for_surface_pair( \
                    graph.movement_params, \
                    origin_surface, \
                    destination_surface, \
                    true)
    self.fall_type_jump_land_positions = JumpLandPositionsUtils \
            .calculate_jump_land_positions_for_surface_pair( \
                    graph.movement_params, \
                    origin_surface, \
                    destination_surface, \
                    false)
    _post_init()

func to_string() -> String:
    return "%s{ [%s, %s] }" % [ \
        InspectorItemType.get_type_string(TYPE), \
        str(destination_surface.first_point), \
        str(destination_surface.last_point), \
    ]

func get_text() -> String:
    return "%s [%s, %s]" % [ \
        SurfaceSide.get_side_string(destination_surface.side), \
        str(destination_surface.first_point), \
        str(destination_surface.last_point), \
    ]

func get_description() -> String:
    return ("There are %s valid edges from this %s to this %s.") % [ \
        valid_edge_count, \
        SurfaceSide.get_side_string(origin_surface.side), \
        SurfaceSide.get_side_string(destination_surface.side), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    if metadata.destination_surface == destination_surface:
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
    var valid_edges: Array
    var failed_edges: Array
    var is_a_jump_calculator: bool
    var jump_land_positions: Array
    
    for edge_type in EdgeType.values():
        if InspectorItemController.EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        valid_edges = \
                edge_types_to_valid_edges[edge_type] if \
                edge_types_to_valid_edges.has(edge_type) else \
                []
        failed_edges = \
                edge_types_to_failed_edges[edge_type] if \
                edge_types_to_failed_edges.has(edge_type) else \
                []
        
        if !valid_edges.empty() or \
                !failed_edges.empty():
            is_a_jump_calculator = \
                    InspectorItemController.JUMP_CALCULATORS.find( \
                            edge_type) >= 0
            jump_land_positions = \
                    jump_type_jump_land_positions if \
                    is_a_jump_calculator else \
                    fall_type_jump_land_positions
            EdgeTypeInSurfacesGroupItemController.new( \
                    tree_item, \
                    tree, \
                    graph, \
                    origin_surface, \
                    destination_surface, \
                    edge_type, \
                    valid_edges, \
                    failed_edges, \
                    jump_land_positions)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var origin_element := OriginSurfaceAnnotationElement.new(origin_surface)
    var destination_element := DestinationSurfaceAnnotationElement.new( \
            destination_surface)
    return [origin_element, destination_element]

static func _count_edges(edge_types_to_edges: Dictionary) -> int:
    var count := 0
    for edge_type in edge_types_to_edges:
        count += edge_types_to_edges[edge_type].size()
    return count
