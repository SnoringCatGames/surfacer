extends InspectorItemController
class_name SurfacesTopLevelGroupItemController

const TYPE := InspectorItemType.SURFACES_TOP_LEVEL_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := false
const PREFIX := "Surfaces"

# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<Edge>>>>
var surfaces_to_surfaces_to_edge_types_to_valid_edges := {}
# Dictionary<Surface, Dictionary<Surface, Dictionary<EdgeType, Array<FailedEdgeAttempt>>>>
var surfaces_to_surfaces_to_edge_types_to_failed_edges := {}

var floors_item_controller: FloorsItemController
var left_walls_item_controller: LeftWallsItemController
var right_walls_item_controller: RightWallsItemController
var ceilings_item_controller: CeilingsItemController

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        surfaces_to_surfaces_to_edge_types_to_valid_edges: Dictionary, \
        surfaces_to_surfaces_to_edge_types_to_failed_edges: Dictionary) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    self.surfaces_to_surfaces_to_edge_types_to_valid_edges = \
            surfaces_to_surfaces_to_edge_types_to_valid_edges
    self.surfaces_to_surfaces_to_edge_types_to_failed_edges = \
            surfaces_to_surfaces_to_edge_types_to_failed_edges
    _post_init()

func get_text() -> String:
    return "%s [%s]" % [ \
        PREFIX, \
        graph.counts.total_surfaces, \
    ]

func to_string() -> String:
    return "%s { count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        graph.counts.total_surfaces, \
    ]

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
    var side: int = \
            metadata.surface.side if \
            search_type == InspectorSearchType.SURFACE else \
            metadata.origin_surface.side
    match side:
        SurfaceSide.FLOOR:
            floors_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.LEFT_WALL:
            left_walls_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.RIGHT_WALL:
            right_walls_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.CEILING:
            ceilings_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        _:
            Utils.error("Invalid SurfaceSide: %s" % SurfaceSide.get_side_string(side))

func _create_children_inner() -> void:
    floors_item_controller = FloorsItemController.new( \
            tree_item, \
            tree, \
            graph, \
            surfaces_to_surfaces_to_edge_types_to_valid_edges, \
            surfaces_to_surfaces_to_edge_types_to_failed_edges)
    left_walls_item_controller = LeftWallsItemController.new( \
            tree_item, \
            tree, \
            graph, \
            surfaces_to_surfaces_to_edge_types_to_valid_edges, \
            surfaces_to_surfaces_to_edge_types_to_failed_edges)
    right_walls_item_controller = RightWallsItemController.new( \
            tree_item, \
            tree, \
            graph, \
            surfaces_to_surfaces_to_edge_types_to_valid_edges, \
            surfaces_to_surfaces_to_edge_types_to_failed_edges)
    ceilings_item_controller = CeilingsItemController.new( \
            tree_item, \
            tree, \
            graph, \
            surfaces_to_surfaces_to_edge_types_to_valid_edges, \
            surfaces_to_surfaces_to_edge_types_to_failed_edges)

func _destroy_children_inner() -> void:
    floors_item_controller.destroy()
    floors_item_controller = null
    left_walls_item_controller.destroy()
    left_walls_item_controller = null
    right_walls_item_controller.destroy()
    right_walls_item_controller = null
    ceilings_item_controller.destroy()
    ceilings_item_controller = null

func get_annotation_elements() -> Array:
    return get_annotation_elements_from_graph(graph)

static func get_annotation_elements_from_graph(graph: PlatformGraph) -> Array:
    var elements := []
    var element: SurfaceAnnotationElement
    for surface in graph.surfaces_set:
        element = SurfaceAnnotationElement.new( \
                surface, \
                AnnotationElementDefaults.SURFACE_COLOR_PARAMS, \
                AnnotationElementDefaults.SURFACE_DEPTH)
        elements.push_back(element)
    return elements
