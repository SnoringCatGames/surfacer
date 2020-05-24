extends Node2D
class_name PlatformGraphInspector

signal platform_graph_selected
signal surface_selected
signal edge_selected
signal failed_edge_attempt_selected
signal edge_step_selected

var global

var element_annotator: ElementAnnotator

var inspector_selector: PlatformGraphInspectorSelector

# Array<AnnotationElement>
var current_annotation_elements := []

# Array<PlatformGraph>
var graphs: Array

# Dictionary<String, PlatformGraphItemController>
var graph_item_controllers := {}

var tree: Tree
var tree_root: TreeItem

var _is_ready := false

func _init(graphs: Array) -> void:
    self.graphs = graphs

func _enter_tree() -> void:
    inspector_selector = PlatformGraphInspectorSelector.new(self)
    add_child(inspector_selector)
    _populate_tree()

func _ready() -> void:
    global = $"/root/Global"
    element_annotator = global.element_annotator
    global.debug_panel.add_section(tree)
    _is_ready = true
    call_deferred("_select_initial_item")

func _populate_tree() -> void:
    tree = Tree.new()
    tree.rect_min_size = Vector2( \
            0.0, \
            DebugPanel.SECTIONS_HEIGHT)
    tree.hide_root = true
    tree.hide_folding = false
    tree.connect( \
            "item_selected", \
            self, \
            "_on_tree_item_selected")
    tree.connect( \
            "item_collapsed", \
            self, \
            "_on_tree_item_expansion_toggled")
    
    tree_root = tree.create_item()
    
    for graph in graphs:
        graph_item_controllers[graph.movement_params.name] = PlatformGraphItemController.new( \
                tree_root, \
                tree, \
                graph)

func _select_initial_item() -> void:
    var player_to_debug: String = \
            global.DEBUG_PARAMS.limit_parsing.player_name if \
            global.DEBUG_PARAMS.has("limit_parsing") and \
                    global.DEBUG_PARAMS.limit_parsing.has("player_name") else \
            null
    if player_to_debug != null:
        graph_item_controllers[player_to_debug] \
                .find_and_expand_controller( \
                        InspectorSearchType.EDGES_TOP_LEVEL_GROUP, \
                        {})

func _on_tree_item_selected() -> void:
    var item := tree.get_selected()
    var controller = item.get_metadata(0)
    
    for element in current_annotation_elements:
        element_annotator.erase(element)
    
    current_annotation_elements = controller.get_annotation_elements()
    for element in current_annotation_elements:
        element_annotator.add(element)
    
    controller.call_deferred("on_item_selected")
    
    # FIXME: --------------------------------
    
#    _log_item_selected(item)
#
#    # Ensure this node (and each of its ancestors) is expanded.
#    while item != tree_root:
#        item.collapsed = false
#        item = item.get_parent()
#
#    _clear_selected_step_items()
#
#    if controller == null:
#        # Do nothing.
#        pass
#    elif controller is PlatformGraph:
#        emit_signal( \
#                "platform_graph_selected", \
#                controller)
#    elif controller is Surface:
#        emit_signal( \
#                "surface_selected", \
#                controller)
#    elif controller is Edge:
#        emit_signal( \
#                "edge_selected", \
#                controller)
#    elif controller is FailedEdgeAttempt:
#        emit_signal( \
#                "failed_edge_attempt_selected", \
#                controller)
#    elif controller is EdgeStepCalcResultMetadata:
#        _select_edge_step_items_from_tree_item(item)
#        emit_signal( \
#                "edge_step_selected", \
#                controller)
#    elif controller is EdgeTypeInSurfacesGroupItemController:
#        # Do nothing.
#        pass
#    # FIXME: ------------------ Handle final controller types for the steps/fails/etc.
#    else:
#        Utils.error("Invalid controller object stored on TreeItem: %s" % controller)

static func _log_item_selected(item: TreeItem) -> void:
    var controller = item.get_metadata(0)
    
    # FIXME: --------------------------------
#    var print_message: String
#    if controller == null:
#        print_message = item.get_text(0)
#    elif controller is PlatformGraph:
#        print_message = controller.to_string()
#    elif controller is Surface:
#        print_message = controller.to_string()
#    elif controller is Edge:
#        print_message = controller.to_string()
#    elif controller is FailedEdgeAttempt:
#        print_message = controller.to_string()
#    elif controller is EdgeStepCalcResultMetadata:
#        print_message = controller.to_string()
#    elif controller is EdgeTypeInSurfacesGroupItemController:
#        print_message = controller.to_string()
#    # FIXME: ------------------ Handle final controller types for the steps/fails/etc.
#    else:
#        Utils.error("Invalid controller object stored on TreeItem: %s" % controller)
#
#    print("PlatformGraphInspector item selected: %s" % print_message)

func _on_tree_item_expansion_toggled(item: TreeItem) -> void:
    var controller: InspectorItemController = item.get_metadata(0)
    assert(controller != null)
    if item.collapsed:
        controller.call_deferred("on_item_collapsed")
    else:
        controller.call_deferred("on_item_expanded")

func select_edge_or_surface( \
        start_position: PositionAlongSurface, \
        end_position: PositionAlongSurface, \
        edge_type: int, \
        graph: PlatformGraph) -> void:
    if start_position.surface == end_position.surface:
        _select_canonical_surface_item_controller( \
                start_position.surface, \
                graph)
    else:
        _select_canonical_edge_or_edge_attempt_item_controller( \
                start_position.surface, \
                end_position.surface, \
                start_position.target_point, \
                end_position.target_point, \
                edge_type, \
                graph)

func _select_canonical_surface_item_controller( \
        surface: Surface, \
        graph: PlatformGraph) -> void:
    if graph_item_controllers.has(graph.movement_params.name):
        graph_item_controllers[graph.movement_params.name] \
                .find_and_expand_controller( \
                        InspectorSearchType.SURFACE, \
                        {surface = surface})

func _select_canonical_edge_or_edge_attempt_item_controller( \
        start_surface: Surface, \
        end_surface: Surface, \
        target_start: Vector2, \
        target_end: Vector2, \
        edge_type: int, \
        graph: PlatformGraph, \
        throws_on_not_found := false) -> void:
    # Determine which start/end positions to check.
    var is_a_jump_calculator := InspectorItemController.JUMP_CALCULATORS.find(edge_type) >= 0
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    graph.movement_params, \
                    start_surface, \
                    end_surface, \
                    is_a_jump_calculator)
    var start := Vector2.INF
    var end := Vector2.INF
    if !all_jump_land_positions.empty():
        var closest_jump_land_positions := _find_closest_jump_land_positions( \
                target_start, \
                target_end, \
                all_jump_land_positions)
        start = closest_jump_land_positions.jump_position.target_point
        end = closest_jump_land_positions.land_position.target_point
    
    if graph_item_controllers.has(graph.movement_params.name):
        var metadata := { \
            origin_surface = start_surface, \
            destination_surface = end_surface, \
            start = start, \
            end = end, \
            edge_type = edge_type, \
        }
        graph_item_controllers[graph.movement_params.name] \
                .find_and_expand_controller( \
                        InspectorSearchType.EDGE, \
                        metadata)

static func _find_closest_jump_land_positions( \
        target_jump_position: Vector2, \
        target_land_position: Vector2, \
        all_jump_land_positions: Array) -> JumpLandPositions:
    var closest_jump_land_positions: JumpLandPositions
    var closest_distance_sum := INF
    var current_distance_sum: float
    
    for jump_land_positions in all_jump_land_positions:
        current_distance_sum = \
                target_jump_position.distance_to(jump_land_positions.jump_position.target_point) + \
                target_land_position.distance_to(jump_land_positions.land_position.target_point)
        if current_distance_sum < closest_distance_sum:
            closest_jump_land_positions = jump_land_positions
            closest_distance_sum = current_distance_sum
    
    return closest_jump_land_positions
