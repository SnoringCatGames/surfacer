extends InspectorItemController
class_name SurfacesTopLevelGroupItemController

const HUE_MIN := 0.0
const HUE_MAX := 1.0
const SATURATION := 0.9
const VALUE := 0.9
const ALPHA := 0.6
const DEPTH := 16.0

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
        metadata: Dictionary) -> InspectorItemController:
    expand()
    
    var side: int = \
            metadata.surface.side if \
            search_type == InspectorSearchType.SURFACE else \
            metadata.origin_surface.side
    match side:
        SurfaceSide.FLOOR:
            return floors_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.LEFT_WALL:
            return left_walls_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.RIGHT_WALL:
            return right_walls_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        SurfaceSide.CEILING:
            return ceilings_item_controller.find_and_expand_controller( \
                    search_type, \
                    metadata)
        _:
            Utils.error("Invalid SurfaceSide: %s" % SurfaceSide.get_side_string(side))
            return null

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
    var color_params := ColorParamsFactory.create_hsv_color_params_with_constant_sva( \
            HUE_MIN, \
            HUE_MAX, \
            SATURATION, \
            VALUE, \
            ALPHA)
    var elements := []
    var element: SurfaceAnnotationElement
    for surface in graph.surfaces_set:
        element = SurfaceAnnotationElement.new( \
                surface, \
                color_params, \
                DEPTH)
        elements.push_back(element)
    return elements
