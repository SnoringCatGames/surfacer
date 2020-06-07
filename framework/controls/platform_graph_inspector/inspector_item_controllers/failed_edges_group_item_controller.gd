extends InspectorItemController
class_name FailedEdgesGroupItemController

const TYPE := InspectorItemType.FAILED_EDGES_GROUP
const IS_LEAF := false
const STARTS_COLLAPSED := true
const PREFIX := "Failed edge calculations"

var origin_surface: Surface
var destination_surface: Surface
var edge_type := EdgeType.UNKNOWN
# Array<FailedEdgeAttempt>
var failed_narrow_phase_edge_attempts: Array
# Array<FailedEdgeAttempt>
var failed_broad_phase_edge_attempts: Array
# Array<Edge>
var valid_edges: Array
# Array<JumpLandPositions>
var all_jump_land_positions: Array

func _init( \
        parent_item: TreeItem, \
        tree: Tree, \
        graph: PlatformGraph, \
        origin_surface: Surface, \
        destination_surface: Surface, \
        edge_type: int, \
        failed_narrow_phase_edge_attempts: Array, \
        valid_edges: Array, \
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
    self.all_jump_land_positions = all_jump_land_positions
    self.valid_edges = valid_edges
    self.failed_narrow_phase_edge_attempts = failed_narrow_phase_edge_attempts
    self.failed_broad_phase_edge_attempts = \
            _calculate_failed_broad_phase_edge_attempts()
    _post_init()

func _calculate_failed_broad_phase_edge_attempts() -> Array:
    # Collect the other neighbor jump-land positions that are used by valid
    # edges.
    var other_valid_jump_land_position_results := []
    var jump_land_positions: JumpLandPositions
    for valid_edge in valid_edges:
        jump_land_positions = JumpLandPositions.new( \
                valid_edge.start_position_along_surface, \
                valid_edge.end_position_along_surface, \
                valid_edge.velocity_start, \
                valid_edge.includes_extra_jump_duration, \
                valid_edge.includes_extra_wall_land_horizontal_speed, \
                false)
        other_valid_jump_land_position_results.push_back(jump_land_positions)
    
    var failed_broad_phase_edge_attempts := []
    var calculator := graph.player_params.get_edge_calculator(edge_type)
    var allows_close_jump_positions := \
            !(calculator is JumpInterSurfaceCalculator)
    var edge_result_metadata: EdgeCalcResultMetadata
    var failed_broad_phase_edge_attempt: FailedEdgeAttempt
    
    for jump_land_positions in all_jump_land_positions:
        if _do_jump_land_positions_match_a_valid_edge( \
                jump_land_positions, \
                valid_edges):
            continue
        
        edge_result_metadata = EdgeCalcResultMetadata.new(true)
        if !EdgeCalculator.broad_phase_check( \
                edge_result_metadata, \
                graph.collision_params, \
                jump_land_positions, \
                other_valid_jump_land_position_results, \
                allows_close_jump_positions):
            failed_broad_phase_edge_attempt = FailedEdgeAttempt.new( \
                    jump_land_positions, \
                    edge_result_metadata, \
                    calculator)
            failed_broad_phase_edge_attempts.push_back( \
                    failed_broad_phase_edge_attempt)
    
    return failed_broad_phase_edge_attempts

static func _do_jump_land_positions_match_a_valid_edge( \
        jump_land_positions: JumpLandPositions, \
        valid_edges: Array) -> bool:
    for valid_edge in valid_edges:
        if Geometry.are_points_equal_with_epsilon( \
                        valid_edge.start, \
                        jump_land_positions.jump_position.target_point) and \
                Geometry.are_points_equal_with_epsilon( \
                        valid_edge.end, \
                        jump_land_positions.land_position.target_point) and \
                Geometry.are_points_equal_with_epsilon( \
                        valid_edge.velocity_start, \
                        jump_land_positions.velocity_start):
            return true
    return false

func to_string() -> String:
    return "%s { failed_np_count=%s, failed_bp_count=%s }" % [ \
        InspectorItemType.get_type_string(type), \
        failed_narrow_phase_edge_attempts.size(), \
        failed_broad_phase_edge_attempts.size(), \
    ]

func get_text() -> String:
    return "%s [%s]" % [ \
        PREFIX, \
        failed_narrow_phase_edge_attempts.size() + \
                failed_broad_phase_edge_attempts.size(), \
    ]

func get_description() -> String:
    return "These failed edge calculations passed broad-phase checks " + \
            "before failing narrow-phase checks."

func get_has_children() -> bool:
    return failed_narrow_phase_edge_attempts.size() > 0 or \
            failed_broad_phase_edge_attempts.size() > 0

func find_and_expand_controller( \
        search_type: int, \
        metadata: Dictionary) -> bool:
    assert(search_type == InspectorSearchType.EDGE)
    metadata.were_children_ready_before = are_children_ready
    if !metadata.were_children_ready_before:
        _create_children_if_needed()
    _trigger_find_and_expand_controller_recursive( \
            search_type, \
            metadata)
    return true

func _find_and_expand_controller_recursive( \
        search_type: int, \
        metadata: Dictionary) -> void:
    var is_subtree_found: bool
    var child := tree_item.get_children()
    while child != null:
        is_subtree_found = child.get_metadata(0).find_and_expand_controller( \
                search_type, \
                metadata)
        if is_subtree_found:
            expand()
            return
        child = child.get_next()
    if !metadata.were_children_ready_before:
        _destroy_children_if_needed()

func _create_children_inner() -> void:
    for failed_edge_attempts in [failed_narrow_phase_edge_attempts, \
            failed_broad_phase_edge_attempts]:
        for failed_edge_attempt in failed_edge_attempts:
            FailedEdgeItemController.new( \
                    tree_item, \
                    tree, \
                    graph, \
                    failed_edge_attempt)

func _destroy_children_inner() -> void:
    # Do nothing.
    pass

func get_annotation_elements() -> Array:
    var elements := []
    var element: FailedEdgeAttemptAnnotationElement
    for failed_edge_attempts in [failed_narrow_phase_edge_attempts, \
            failed_broad_phase_edge_attempts]:
        for failed_edge_attempt in failed_edge_attempts:
            element = FailedEdgeAttemptAnnotationElement.new( \
                    failed_edge_attempt, \
                    AnnotationElementDefaults \
                            .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS, \
                    AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_COLOR_PARAMS, \
                    AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_LENGTH, \
                    AnnotationElementDefaults.FAILED_EDGE_ATTEMPT_DASH_GAP, \
                    AnnotationElementDefaults \
                            .FAILED_EDGE_ATTEMPT_DASH_STROKE_WIDTH, \
                    false)
            elements.push_back(element)
    return elements
