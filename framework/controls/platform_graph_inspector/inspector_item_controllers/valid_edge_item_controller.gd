extends InspectorItemController
class_name ValidEdgeItemController

const TYPE := InspectorItemType.VALID_EDGE
const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge: Edge
var edge_result_metadata: EdgeCalcResultMetadata

var edge_calc_result_metadata_controller: EdgeCalcResultMetadataItemController

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        edge: Edge) \
        .( \
        TYPE, \
        IS_LEAF, \
        STARTS_COLLAPSED, \
        parent_item, \
        tree, \
        graph) -> void:
    assert(edge != null)
    self.edge = edge
    _post_init()

func to_string() -> String:
    return "%s { %s [%s, %s] }" % [ \
        InspectorItemType.get_type_string(type), \
        EdgeType.get_type_string(edge.type), \
        str(edge.start), \
        str(edge.end), \
    ]

func get_text() -> String:
    return "[%s, %s]" % [ \
        str(edge.start), \
        str(edge.end), \
    ]

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    if Geometry.are_points_equal_with_epsilon( \
                    edge.start, \
                    metadata.start, \
                    0.01) and \
            Geometry.are_points_equal_with_epsilon( \
                    edge.end, \
                    metadata.end, \
                    0.01):
        expand()
        select()
        return true
    else:
        return false

func _create_children_inner() -> void:
    if edge_result_metadata == null:
        _calculate_edge_calc_result_metadata()
    edge_calc_result_metadata_controller = EdgeCalcResultMetadataItemController.new( \
            tree_item, \
            tree, \
            graph, \
            edge, \
            edge_result_metadata)

func _calculate_edge_calc_result_metadata() -> void:
    edge_result_metadata = EdgeCalcResultMetadata.new(true)
    edge.calculator.calculate_edge( \
            edge_result_metadata, \
            graph.collision_params, \
            edge.start_position_along_surface, \
            edge.end_position_along_surface, \
            edge.velocity_start, \
            edge.includes_extra_jump_duration, \
            edge.includes_extra_wall_land_horizontal_speed)
    assert(!edge_result_metadata.failed_before_creating_steps)

func _destroy_children_inner() -> void:
    edge_calc_result_metadata_controller = null

func get_annotation_elements() -> Array:
    var element := EdgeAnnotationElement.new( \
            edge, \
            true, \
            true, \
            true)
    return [element]
