class_name EdgeAttemptItemController
extends InspectorItemController

const IS_LEAF := false
const STARTS_COLLAPSED := true

var edge_attempt: EdgeAttempt
var edge_result_metadata: EdgeCalcResultMetadata

func _init( \
        type,
        parent_item: TreeItem,
        tree: Tree,
        graph: PlatformGraph,
        edge_attempt: EdgeAttempt) \
        .( \
        type,
        IS_LEAF,
        STARTS_COLLAPSED,
        parent_item,
        tree,
        graph) -> void:
    assert(edge_attempt != null)
    self.edge_attempt = edge_attempt

func find_and_expand_controller( \
        search_type: int,
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    if Gs.geometry.are_points_equal_with_epsilon( \
                    edge_attempt.get_start(),
                    metadata.start,
                    0.01) and \
            Gs.geometry.are_points_equal_with_epsilon( \
                    edge_attempt.get_end(),
                    metadata.end,
                    0.01):
        expand()
        select()
        # TODO: This deferred select call shouldn't be necessary.
        call_deferred("select")
        return true
    else:
        return false

func _create_children_inner() -> void:
    if edge_result_metadata == null:
        edge_result_metadata = _calculate_edge_calc_result_metadata( \
                edge_attempt,
                graph)
    var get_annotation_elements_funcref := \
            funcref(self, "get_annotation_elements")
    
    var text: String
    var description: String
    
    text = "%s(%d,%d): Origin" % [
        SurfaceSide.get_prefix(edge_attempt.get_start_surface().side),
        edge_attempt.get_start().x,
        edge_attempt.get_start().y,
    ]
    description = \
            "The start position for this edge attempt is %s, along a %s." % [
        edge_attempt.get_start(),
        SurfaceSide.get_string(edge_attempt.get_start_surface().side),
    ]
    DescriptionItemController.new( \
            tree_item,
            tree,
            graph,
            text,
            description,
            get_annotation_elements_funcref)
    
    text = "%s(%d,%d): Destination" % [
        SurfaceSide.get_prefix(edge_attempt.get_end_surface().side),
        edge_attempt.get_end().x,
        edge_attempt.get_end().y,
    ]
    description = \
            "The end position for this edge attempt is %s, along a %s." % [
        edge_attempt.get_end(),
        SurfaceSide.get_string(edge_attempt.get_end_surface().side),
    ]
    DescriptionItemController.new( \
            tree_item,
            tree,
            graph,
            text,
            description,
            get_annotation_elements_funcref)
    
    text = "%s: Start velocity" % edge_attempt.velocity_start
    description = \
            "The start velocity for this edge attempt is %s." % \
            edge_attempt.velocity_start
    DescriptionItemController.new( \
            tree_item,
            tree,
            graph,
            text,
            description,
            get_annotation_elements_funcref)
    
    EdgeCalcResultMetadataItemController.new( \
            tree_item,
            tree,
            graph,
            edge_attempt,
            edge_result_metadata)
    
    EdgeCalcProfilerGroupItemController.new( \
            tree_item,
            tree,
            graph,
            edge_result_metadata)

static func _calculate_edge_calc_result_metadata( \
        edge_attempt: EdgeAttempt,
        graph: PlatformGraph) -> EdgeCalcResultMetadata:
    var edge_result_metadata := EdgeCalcResultMetadata.new(true, false)
    edge_attempt.calculator.calculate_edge( \
            edge_result_metadata,
            graph.collision_params,
            edge_attempt.start_position_along_surface,
            edge_attempt.end_position_along_surface,
            edge_attempt.velocity_start,
            edge_attempt.includes_extra_jump_duration,
            edge_attempt.includes_extra_wall_land_horizontal_speed)
    return edge_result_metadata

func _destroy_children_inner() -> void:
    # Do nothing.
    pass
