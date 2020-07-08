extends Tree
class_name PlatformGraphInspector

# INSPECTOR STRUCTURE:
# - Platform graph [player_name]
#   - Edges [#]
#     - [#] Edges calculated with increasing jump height
#       - JUMP_INTER_SURFACE_EDGEs [#]
#         - [(x,y), (x,y)]
#           - EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT [1]
#             - 1: Movement is valid.
#             - ...
#         - ...
#       - ...
#     - [#] Edges calculated without increasing jump height
#       - ...
#     - [#] Edges calculated with one step
#       - ...
#   - Surfaces [#]
#     - FLOORs [#]
#       - [(x,y), (x,y)]
#         - _# valid outbound edges_
#         - _Destination surfaces:_
#         - FLOOR [(x,y), (x,y)]
#           - JUMP_INTER_SURFACE_EDGEs [#]
#             - [(x,y), (x,y)]
#               - EDGE_VALID_WITH_INCREASING_JUMP_HEIGHT [1]
#                 - 1: Movement is valid.
#                 - ...
#             - ...
#             - Failed edge calculations [#]
#               - REASON_FOR_FAILING [(x,y), (x,y)]
#                 - REASON_FOR_FAILING [#]
#                   - 1: Step result info
#                     - 2: Step result info
#                     - ...
#                   - ...
#                 - ...
#               - ...
#           - ...
#         - ...
#       - ...
#     - ...
#   - Global counts
#     - # total surfaces
#     - # total edges
#     - # JUMP_INTER_SURFACE_EDGEs
#     - ...

var inspector_selector: PlatformGraphInspectorSelector

# Array<AnnotationElement>
var current_annotation_elements := []

# Array<PlatformGraph>
var graphs: Array

# Dictionary<String, PlatformGraphItemController>
var graph_item_controllers := {}

var root: TreeItem

var _should_be_populated := false

var _find_and_expand_controller_recursive_count := 0

var has_focus := false

var _focused_control: Control

func _init() -> void:
    hide_root = true
    hide_folding = false
    connect( \
            "item_selected", \
            self, \
            "_on_tree_item_selected")
    connect( \
            "item_collapsed", \
            self, \
            "_on_tree_item_expansion_toggled")
    
    root = create_item()

func _ready() -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    
    inspector_selector = PlatformGraphInspectorSelector.new(self)
    Global.canvas_layers.annotation_layer.add_child(inspector_selector)

func _process(delta_sec: float) -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    
    var next_focused_control := get_focus_owner()
    if _focused_control != next_focused_control:
        _focused_control = next_focused_control
        
        if _focused_control != null:
            if _focused_control == self:
                has_focus = true
                return
            
            var parent := _focused_control.get_parent_control()
            while parent != null:
                if parent == self:
                    has_focus = true
                    return
                parent = parent.get_parent_control()
        
        has_focus = false

func _gui_input(event: InputEvent) -> void:
    # Godot seems to have a bug where many clicks in the tree are
    # false-negatives. This at least prevents them from being consumed as
    # clicks within the level.
    accept_event()

func release_focus() -> void:
    grab_focus()
    .release_focus()

func populate() -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    
    _should_be_populated = true
    
    for graph in graphs:
        graph_item_controllers[graph.movement_params.name] = \
                PlatformGraphItemController.new( \
                        root, \
                        self, \
                        graph)
    
    if !graphs.empty():
        call_deferred("_select_initial_item")

func clear() -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    
    release_focus()
    _clear_selection()
    _should_be_populated = false
    .clear()

func set_graphs(graphs: Array) -> void:
    if !Config.DEBUG_PARAMS.is_inspector_enabled:
        return
    
    self.graphs = graphs
    if _should_be_populated:
        if !self.graphs.empty():
            clear()
        populate()

func _select_initial_item() -> void:
    if !Config.DEBUG_PARAMS.has("limit_parsing") or \
            !Config.DEBUG_PARAMS.limit_parsing.has("player_name"):
        # Don't select anything if we don't know the player to target.
        return
    
    var limit_parsing: Dictionary = Config.DEBUG_PARAMS.limit_parsing
    var player_name: String = limit_parsing.player_name
    
    if limit_parsing.has("edge") and \
            limit_parsing.edge.has("origin"):
        var graph: PlatformGraph = graph_item_controllers[player_name].graph
        var debug_edge: Dictionary = limit_parsing.edge
        var debug_origin: Dictionary = debug_edge.origin
        
        var origin_start_vertex: Vector2 = \
                debug_origin.surface_start_vertex if \
                debug_origin.has("surface_start_vertex") else \
                Vector2.INF
        var origin_end_vertex: Vector2 = \
                debug_origin.surface_end_vertex if \
                debug_origin.has("surface_end_vertex") else \
                Vector2.INF
        var origin_epsilon: float = \
                debug_origin.epsilon if \
                debug_origin.has("epsilon") else \
                10.0
        var origin_surface := _find_matching_surface( \
                origin_start_vertex, \
                origin_end_vertex, \
                origin_epsilon, \
                graph)
        
        if origin_surface != null:
            var destination_surface: Surface
            var debug_destination: Dictionary
            if debug_edge.has("destination"):
                debug_destination = debug_edge.destination
                var destination_start_vertex: Vector2 = \
                        debug_destination.surface_start_vertex if \
                        debug_destination.has("surface_start_vertex") else \
                        Vector2.INF
                var destination_end_vertex: Vector2 = \
                        debug_destination.surface_end_vertex if \
                        debug_destination.has("surface_end_vertex") else \
                        Vector2.INF
                var destination_epsilon: float = \
                        debug_destination.epsilon if \
                        debug_destination.has("epsilon") else \
                        10.0
                destination_surface = _find_matching_surface( \
                        destination_start_vertex, \
                        destination_end_vertex, \
                        destination_epsilon, \
                        graph)
                
                # TODO: Add support for searching for:
                #       - InspectorItemType.DESTINATION_SURFACE
                #       - InspectorItemType.EDGE_TYPE_IN_SURFACES_GROUP
                
                if debug_origin.has("position") and \
                        debug_destination.has("position") and \
                        limit_parsing.has("edge_type"):
                    # Search for the matching edge item.
                    _select_canonical_edge_or_edge_attempt_item_controller( \
                            origin_surface, \
                            destination_surface, \
                            debug_origin.position, \
                            debug_destination.position, \
                            limit_parsing.edge_type, \
                            graph)
                    return
                elif destination_surface != null:
                    # Search for the matching origin surface item.
                    _select_canonical_destination_surface_item_controller( \
                            origin_surface, \
                            destination_surface, \
                            graph)
                    return
            
            # Search for the matching origin surface item.
            _select_canonical_origin_surface_item_controller( \
                    origin_surface, \
                    graph)
            return
    
    # TODO: Add support for search for:
    #       - InspectorItemType.FLOORS
    #       - InspectorItemType.LEFT_WALLS
    #       - InspectorItemType.RIGHT_WALLS
    #       - InspectorItemType.CEILINGS
    
    # By default, just select the top-level edges group.
    _trigger_find_and_expand_controller( \
            player_name, \
            InspectorSearchType.EDGES_GROUP, \
            {})

func _find_matching_surface( \
        start_vertex: Vector2, \
        end_vertex: Vector2, \
        epsilon: float, \
        graph: PlatformGraph) -> Surface:
    if start_vertex != Vector2.INF or \
            end_vertex != Vector2.INF:
        var does_start_vertex_match: bool
        var does_end_vertex_match: bool
        var surface: Surface
        for surface in graph.surfaces_set:
            does_start_vertex_match = start_vertex == Vector2.INF or \
                    Geometry.are_points_equal_with_epsilon( \
                            surface.first_point, \
                            start_vertex, \
                            epsilon)
            does_end_vertex_match = end_vertex == Vector2.INF or \
                    Geometry.are_points_equal_with_epsilon( \
                            surface.last_point, \
                            end_vertex, \
                            epsilon)
            if does_start_vertex_match and does_end_vertex_match:
                return surface
    return null

func _on_tree_item_selected() -> void:
    var item := get_selected()
    var controller: InspectorItemController = item.get_metadata(0)
    
    Global.element_annotator.erase_all(current_annotation_elements)
    
    current_annotation_elements = controller.get_annotation_elements()
    Global.element_annotator.add_all(current_annotation_elements)
    
    if !get_is_find_and_expand_in_progress():
        Global.selection_description.set_text(controller.get_description())
    
    controller.call_deferred("on_item_selected")

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
        _select_canonical_origin_surface_item_controller( \
                start_position.surface, \
                graph)
    else:
        _select_canonical_edge_or_edge_attempt_item_controller( \
                start_position.surface, \
                end_position.surface, \
                start_position.target_projection_onto_surface, \
                end_position.target_projection_onto_surface, \
                edge_type, \
                graph)

func _select_canonical_origin_surface_item_controller( \
        origin_surface: Surface, \
        graph: PlatformGraph) -> void:
    if graph_item_controllers.has(graph.movement_params.name):
        var metadata := {
            origin_surface = origin_surface, \
        }
        _trigger_find_and_expand_controller( \
                graph.movement_params.name, \
                InspectorSearchType.ORIGIN_SURFACE, \
                metadata)

func _select_canonical_destination_surface_item_controller( \
        origin_surface: Surface, \
        destination_surface: Surface, \
        graph: PlatformGraph) -> void:
    if graph_item_controllers.has(graph.movement_params.name):
        var metadata := {
            origin_surface = origin_surface, \
            destination_surface = destination_surface, \
        }
        _trigger_find_and_expand_controller( \
                graph.movement_params.name, \
                InspectorSearchType.DESTINATION_SURFACE, \
                metadata)

func _select_canonical_edge_or_edge_attempt_item_controller( \
        start_surface: Surface, \
        end_surface: Surface, \
        target_projection_start: Vector2, \
        target_projection_end: Vector2, \
        edge_type: int, \
        graph: PlatformGraph, \
        throws_on_not_found := false) -> void:
    # Determine which start/end positions to check.
    var all_jump_land_positions := JumpLandPositionsUtils \
            .calculate_jump_land_positions_for_surface_pair( \
                    graph.movement_params, \
                    start_surface, \
                    end_surface)
    var jump_position: PositionAlongSurface
    var land_position: PositionAlongSurface
    if !all_jump_land_positions.empty():
        var closest_jump_land_positions := _find_closest_jump_land_positions( \
                target_projection_start, \
                target_projection_end, \
                all_jump_land_positions)
        jump_position = closest_jump_land_positions.jump_position
        land_position = closest_jump_land_positions.land_position
        
        # Show a descriptive message if the selection clicks were too far from
        # any jump-land positions.
        if jump_position.target_projection_onto_surface \
                        .distance_squared_to(target_projection_start) > \
                        PlatformGraphInspectorSelector\
                                .CLICK_POSITION_DISTANCE_SQUARED_THRESHOLD or \
                land_position.target_projection_onto_surface \
                        .distance_squared_to(target_projection_end) > \
                        PlatformGraphInspectorSelector \
                                .CLICK_POSITION_DISTANCE_SQUARED_THRESHOLD:
            _clear_selection()
            Global.selection_description.set_text( \
                    SelectionDescription.NO_MATCHING_JUMP_LAND_POSITIONS)
            return
    
    if graph_item_controllers.has(graph.movement_params.name):
        var metadata := { \
            origin_surface = start_surface, \
            destination_surface = end_surface, \
            start = jump_position.target_point, \
            end = land_position.target_point, \
            edge_type = edge_type, \
        }
        _trigger_find_and_expand_controller( \
                graph.movement_params.name, \
                InspectorSearchType.EDGE, \
                metadata)

func _trigger_find_and_expand_controller( \
        player_name: String, \
        search_type: int, \
        metadata: Dictionary) -> void:
    _increment_find_and_expand_controller_recursive_count()
    graph_item_controllers[player_name].find_and_expand_controller( \
            search_type, \
            metadata)
    _decrement_find_and_expand_controller_recursive_count()
    _poll_is_find_and_expand_in_progress( \
            player_name, \
            search_type, \
            metadata)

func _on_find_and_expand_complete( \
        player_name: String, \
        search_type: int, \
        metadata: Dictionary) -> void:
    print("Inspector search complete: player_name=%s, search_type=%s" % [ \
        player_name, \
        InspectorSearchType.get_type_string(search_type), \
    ])
    
    var item := get_selected()
    var controller: InspectorItemController = item.get_metadata(0)
    
    var selection_failure_message := ""
    match search_type:
        InspectorSearchType.EDGE:
            if controller.type != InspectorItemType.VALID_EDGE and \
                    controller.type != InspectorItemType.FAILED_EDGE:
                selection_failure_message = \
                        SelectionDescription.NO_POSITIONS_PASSING_BROAD_PHASE
        InspectorSearchType.ORIGIN_SURFACE:
            assert(controller.type == InspectorItemType.ORIGIN_SURFACE)
        InspectorSearchType.DESTINATION_SURFACE:
            assert(controller.type == InspectorItemType.DESTINATION_SURFACE)
        InspectorSearchType.EDGES_GROUP:
            assert(controller.type == InspectorItemType.EDGES_GROUP)
        _:
            Utils.error("Invalid InspectorSearchType: %s" % \
                    InspectorSearchType.get_type_string(search_type))
    
    if selection_failure_message != "":
        Global.selection_description.set_text(selection_failure_message)
    else:
        Global.selection_description.set_text(controller.get_description())

func get_is_find_and_expand_in_progress() -> bool:
    return _find_and_expand_controller_recursive_count > 0

func _increment_find_and_expand_controller_recursive_count() -> void:
    _find_and_expand_controller_recursive_count += 1

func _decrement_find_and_expand_controller_recursive_count() -> void:
    _find_and_expand_controller_recursive_count -= 1

func _poll_is_find_and_expand_in_progress( \
        player_name: String, \
        search_type: int, \
        metadata: Dictionary) -> void:
    if get_is_find_and_expand_in_progress():
        call_deferred( \
                "_poll_is_find_and_expand_in_progress", \
                player_name, \
                search_type, \
                metadata)
    else:
        _on_find_and_expand_complete( \
                player_name, \
                search_type, \
                metadata)

func _clear_selection() -> void:
    # Deselect the current TreeItem selection.
    var item := get_selected()
    if item != null:
        item.deselect(0)
    
    # Remove the current annotations.
    Global.element_annotator.erase_all(current_annotation_elements)
    current_annotation_elements = []

static func _find_closest_jump_land_positions( \
        target_jump_position: Vector2, \
        target_land_position: Vector2, \
        all_jump_land_positions: Array) -> JumpLandPositions:
    var closest_jump_land_positions: JumpLandPositions
    var closest_distance_sum := INF
    var current_distance_sum: float
    
    for jump_land_positions in all_jump_land_positions:
        current_distance_sum = \
                target_jump_position.distance_to( \
                        jump_land_positions.jump_position.target_point) + \
                target_land_position.distance_to( \
                        jump_land_positions.land_position.target_point)
        if current_distance_sum < closest_distance_sum:
            closest_jump_land_positions = jump_land_positions
            closest_distance_sum = current_distance_sum
    
    return closest_jump_land_positions
