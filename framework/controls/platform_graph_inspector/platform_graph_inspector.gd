extends Node2D
class_name PlatformGraphInspector

signal platform_graph_selected
signal surface_selected
signal edge_selected
signal failed_edge_attempt_selected
signal edge_step_selected

const JUMP_CALCULATORS := [ \
    EdgeType.JUMP_INTER_SURFACE_EDGE, \
    EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
]

const EDGE_TYPES_TO_SKIP := [ \
    EdgeType.AIR_TO_AIR_EDGE, \
    EdgeType.AIR_TO_SURFACE_EDGE, \
    EdgeType.INTRA_SURFACE_EDGE, \
    EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
    EdgeType.UNKNOWN, \
]

var global

var inspector_selector: PlatformGraphInspectorSelector

# Array<PlatformGraph>
var graphs: Array

var tree_view: Tree
var tree_root: TreeItem

# Array<TreeItem>
var current_selected_step_items := []

func _init(graphs: Array) -> void:
    self.graphs = graphs

func _enter_tree() -> void:
    inspector_selector = PlatformGraphInspectorSelector.new(self)
    add_child(inspector_selector)

func _ready() -> void:
    global = $"/root/Global"
    
    tree_view = Tree.new()
    tree_view.rect_min_size = Vector2( \
            0.0, \
            DebugPanel.SECTIONS_HEIGHT)
    tree_view.hide_root = true
    tree_view.hide_folding = false
    tree_view.connect( \
            "item_selected", \
            self, \
            "_on_tree_item_selected")
    global.debug_panel.add_section(tree_view)

func _draw() -> void:
    # FIXME: Only clear parts that actually need to be cleared.
    
    # Clear any previous items.
    tree_view.clear()
    tree_root = tree_view.create_item()
    
    for graph in graphs:
        _draw_platform_graph_item( \
                graph, \
                tree_root)

func _draw_platform_graph_item( \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var graph_item := tree_view.create_item(parent_item)
    graph_item.set_text( \
            0, \
            "Platform graph [%s]" % graph.movement_params.name)
    graph_item.set_metadata( \
            0, \
            graph)
    graph_item.collapsed = false
    
    _draw_top_level_edges( \
            graph, \
            graph_item)
    _draw_top_level_surfaces( \
            graph, \
            graph_item)
    _draw_global_counts( \
            graph, \
            graph_item)

func _draw_top_level_edges( \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var edges_item := tree_view.create_item(parent_item)
    edges_item.set_text( \
            0, \
            "Edges [%s]" % graph.counts.total_edges)
    edges_item.collapsed = true
    
    # Dictionary<EdgeType, TreeItem>
    var edge_type_to_tree_item := {}
    
    var type_name: String
    var edge_type_item: TreeItem
    
    for edge_type in EdgeType.values():
        if EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        type_name = EdgeType.get_type_string(edge_type)
        edge_type_item = tree_view.create_item(edges_item)
        edge_type_item.set_text( \
                0, \
                "%ss [%s]" % [ \
                        type_name, \
                        graph.counts[type_name], \
                        ])
        edge_type_item.collapsed = true
        edge_type_to_tree_item[edge_type] = edge_type_item
    
    var edge: Edge
    
    for origin_surface in graph.surfaces_set:
        for origin_node in graph.surfaces_to_outbound_nodes[origin_surface]:
            for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
                edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
                parent_item = edge_type_to_tree_item[edge.type]
                
                _draw_top_level_edge_item( \
                        edge, \
                        graph, \
                        parent_item)

func _draw_top_level_surfaces( \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var surfaces_item := tree_view.create_item(parent_item)
    surfaces_item.set_text( \
            0, \
            "Surfaces [%s]" % graph.counts.total_surfaces)
    surfaces_item.collapsed = true
    
    var floors_item: TreeItem
    if graph.counts.FLOOR > 0:
        floors_item = tree_view.create_item(surfaces_item)
        floors_item.set_text( \
                0, \
                "Floors [%s]" % graph.counts.FLOOR)
        floors_item.collapsed = true
    
    var left_walls_item: TreeItem
    if graph.counts.LEFT_WALL > 0:
        left_walls_item = tree_view.create_item(surfaces_item)
        left_walls_item.set_text( \
                0, \
                "Left walls [%s]" % graph.counts.LEFT_WALL)
        left_walls_item.collapsed = true
    
    var right_walls_item: TreeItem
    if graph.counts.RIGHT_WALL > 0:
        right_walls_item = tree_view.create_item(surfaces_item)
        right_walls_item.set_text( \
                0, \
                "Right walls [%s]" % graph.counts.RIGHT_WALL)
        right_walls_item.collapsed = true
    
    var ceilings_item: TreeItem
    if graph.counts.CEILING > 0:
        ceilings_item = tree_view.create_item(surfaces_item)
        ceilings_item.set_text( \
                0, \
                "Ceilings [%s]" % graph.counts.CEILING)
        ceilings_item.collapsed = true
    
    for surface in graph.surfaces_set:
        match surface.side:
            SurfaceSide.FLOOR:
                parent_item = floors_item
            SurfaceSide.LEFT_WALL:
                parent_item = left_walls_item
            SurfaceSide.RIGHT_WALL:
                parent_item = right_walls_item
            SurfaceSide.CEILING:
                parent_item = ceilings_item
            _:
                Utils.error()
        
        _draw_top_level_surface_item( \
                surface, \
                graph, \
                parent_item)

func _draw_global_counts( \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var global_counts_item := tree_view.create_item(parent_item)
    global_counts_item.set_text( \
            0, \
            "Global counts")
    global_counts_item.collapsed = false
    
    var total_surfaces_item := tree_view.create_item(global_counts_item)
    total_surfaces_item.set_text( \
            0, \
            "%s total surfaces" % graph.counts.total_surfaces)
    
    var total_edges_item := tree_view.create_item(global_counts_item)
    total_edges_item.set_text( \
            0, \
            "%s total edges" % graph.counts.total_edges)
    
    var edge_type_count_item: TreeItem
    var type_name: String
    for edge_type in EdgeType.values():
        if EDGE_TYPES_TO_SKIP.find(edge_type) >= 0:
            continue
        
        type_name = EdgeType.get_type_string(edge_type)
        edge_type_count_item = tree_view.create_item(global_counts_item)
        edge_type_count_item.set_text( \
                0, \
                "%s %ss" % [ \
                        graph.counts[type_name], \
                        type_name, \
                        ])

func _draw_top_level_edge_item( \
        edge: Edge, \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var edge_item := tree_view.create_item(parent_item)
    var text := "[%s, %s]" % [ \
            edge.start, \
            edge.end, \
            ]
    edge_item.set_text( \
            0, \
            text)
    edge_item.set_metadata( \
            0, \
            edge)
    edge_item.collapsed = true
    var placeholder_child_item := tree_view.create_item(edge_item)

func _draw_top_level_surface_item( \
        surface: Surface, \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var origin_surface_item := tree_view.create_item(parent_item)
    var text := "%s [%s, %s]" % [ \
            SurfaceSide.get_side_string(surface.side), \
            surface.first_point, \
            surface.last_point, \
            ]
    origin_surface_item.set_text( \
            0, \
            text)
    origin_surface_item.set_metadata( \
            0, \
            surface)
    origin_surface_item.collapsed = true
    
    # FIXME: ------------ Override styling for this item.
    var valid_edges_count_item := tree_view.create_item(origin_surface_item)
    
    # FIXME: ------------ Override styling for this item.
    var destination_surfaces_description_item := tree_view.create_item(origin_surface_item)
    destination_surfaces_description_item.set_text( \
            0, \
            "_Destination surfaces_")
    
    var counts := { \
        valid_edges = 0, \
    }
    
    var destination_surface_to_tree_item := {}
    var destination_surface_to_edge_type_to_tree_item := {}
    
    var destination_surface: Surface
    var edge: Edge
    
    # Valid edges.
    for origin_node in graph.surfaces_to_outbound_nodes[surface]:
        for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
            destination_surface = destination_node.surface
            edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
            _draw_edge_or_edge_attempt( \
                    edge, \
                    graph, \
                    origin_surface_item, \
                    destination_surface, \
                    destination_surface_to_tree_item, \
                    destination_surface_to_edge_type_to_tree_item, \
                    counts)
    
    # Failed edge attempts.
    for failed_edge_attempt in graph.surfaces_to_failed_edge_attempts[surface]:
        destination_surface = failed_edge_attempt.destination_surface
        _draw_edge_or_edge_attempt( \
                failed_edge_attempt, \
                graph, \
                origin_surface_item, \
                destination_surface, \
                destination_surface_to_tree_item, \
                destination_surface_to_edge_type_to_tree_item, \
                counts)
    
    valid_edges_count_item.set_text( \
            0, \
            "_%s valid outbound edges_" % counts.valid_edges)

class EdgeTypeItemMetadata:
    var edge_type := EdgeType.UNKNOWN
    var valid_edge_count := 0
    var failed_edges_item: TreeItem
    func _init( \
            edge_type: int, \
            valid_edge_count: int, \
            failed_edges_item: TreeItem) -> void:
        self.edge_type = edge_type
        self.valid_edge_count = valid_edge_count
        self.failed_edges_item = failed_edges_item

func _draw_edge_or_edge_attempt( \
        edge_or_edge_attempt: Reference, \
        graph: PlatformGraph, \
        origin_surface_item: TreeItem, \
        destination_surface: Surface, \
        destination_surface_to_tree_item: Dictionary, \
        destination_surface_to_edge_type_to_tree_item: Dictionary, \
        counts: Dictionary) -> void:
    var is_valid_edge := edge_or_edge_attempt is Edge
    var edge_type: int = \
            edge_or_edge_attempt.type if \
            is_valid_edge else \
            edge_or_edge_attempt.edge_type
    
    var destination_surface_item: TreeItem
    var edge_type_item: TreeItem
    var failed_edges_item: TreeItem
    var edge_type_to_tree_item: Dictionary
    var edge_type_item_metadata: EdgeTypeItemMetadata
    
    # Nest the edge-type-aggegration items underneath destination-surface items.
    if !destination_surface_to_tree_item.has(destination_surface):
        destination_surface_item = tree_view.create_item(origin_surface_item)
        var text := "%s [%s, %s]" % [ \
                SurfaceSide.get_side_string(destination_surface.side), \
                destination_surface.first_point, \
                destination_surface.last_point, \
                ]
        destination_surface_item.set_text( \
                0, \
                text)
        destination_surface_item.set_metadata( \
                0, \
                destination_surface)
        destination_surface_item.collapsed = true
        destination_surface_to_tree_item[destination_surface] = destination_surface_item
        edge_type_to_tree_item = {}
        destination_surface_to_edge_type_to_tree_item[destination_surface] = \
                edge_type_to_tree_item
    else:
        destination_surface_item = destination_surface_to_tree_item[destination_surface]
        edge_type_to_tree_item = \
                destination_surface_to_edge_type_to_tree_item[destination_surface]
    
    # Nest the edge items underneath edge-type-aggegration items.
    if !edge_type_to_tree_item.has(edge_type):
        edge_type_item = tree_view.create_item(destination_surface_item)
        edge_type_item.set_text( \
                0, \
                "%ss" % EdgeType.get_type_string(edge_type))
        edge_type_item.collapsed = true
        edge_type_to_tree_item[edge_type] = edge_type_item
        
        failed_edges_item = tree_view.create_item(edge_type_item)
        failed_edges_item.set_text( \
                0, \
                "Failed edge calculations (which passed broad-phase checks)")
        failed_edges_item.collapsed = true
        
        edge_type_item_metadata = EdgeTypeItemMetadata.new( \
                edge_type, \
                0, \
                failed_edges_item)
        edge_type_item.set_metadata( \
                0, \
                edge_type_item_metadata)
    else:
        edge_type_item = edge_type_to_tree_item[edge_type]
        edge_type_item_metadata = edge_type_item.get_metadata(0)
        failed_edges_item = edge_type_item_metadata.failed_edges_item
    
    if is_valid_edge:
        # Create the valid-edge item.
        var edge: Edge = edge_or_edge_attempt
        var index: int = edge_type_item_metadata.valid_edge_count
        var edge_item := tree_view.create_item(edge_type_item, index)
        var text := "%s [%s, %s]" % [ \
                edge.name, \
                edge.start, \
                edge.end, \
                ]
        edge_item.set_text( \
                0, \
                text)
        edge_item.set_metadata( \
                0, \
                edge)
        edge_item.collapsed = true
        var placeholder_child_item := tree_view.create_item(edge_item)
        edge_type_item_metadata.valid_edge_count += 1
        counts.valid_edges += 1
    else:
        # Create the failed-edge-attempt item.
        var failed_edge_attempt: FailedEdgeAttempt = edge_or_edge_attempt
        var failed_edge_attempt_item = tree_view.create_item(failed_edges_item)
        var text := "%s [%s, %s]" % [ \
                EdgeCalcResultType.get_result_string( \
                        failed_edge_attempt.edge_calc_result_type) if \
                failed_edge_attempt.edge_calc_result_type != \
                        EdgeCalcResultType.WAYPOINT_INVALID else \
                WaypointValidity.get_validity_string( \
                        failed_edge_attempt.waypoint_validity), \
                str(failed_edge_attempt.start), \
                str(failed_edge_attempt.end), \
                ]
        failed_edge_attempt_item.set_text( \
                0, \
                text)
        failed_edge_attempt_item.set_metadata( \
                0, \
                failed_edge_attempt)
        failed_edge_attempt_item.collapsed = true
        var placeholder_child_item := tree_view.create_item(failed_edge_attempt_item)

func _on_tree_item_selected() -> void:
    var item := tree_view.get_selected()
    var metadata = item.get_metadata(0)
    
    _log_item_selected(item)
    
    # Ensure this node (and each of its ancestors) is expanded.
    while item != tree_root:
        item.collapsed = false
        item = item.get_parent()
    
    _clear_selected_step_items()
    
    if metadata == null:
        # Do nothing.
        pass
    elif metadata is PlatformGraph:
        emit_signal( \
                "platform_graph_selected", \
                metadata)
    elif metadata is Surface:
        emit_signal( \
                "surface_selected", \
                metadata)
    elif metadata is Edge:
        emit_signal( \
                "edge_selected", \
                metadata)
    elif metadata is FailedEdgeAttempt:
        emit_signal( \
                "failed_edge_attempt_selected", \
                metadata)
    elif metadata is EdgeStepCalcResultMetadata:
        _select_edge_step_items_from_tree_item(item)
        emit_signal( \
                "edge_step_selected", \
                metadata)
    # FIXME: ------------------ Handle final metadata types for the steps/fails/etc.
    else:
        Utils.error("Invalid metadata object stored on TreeItem: %s" % metadata)

func _log_item_selected(item: TreeItem) -> void:
    var metadata = item.get_metadata(0)
    
    var print_message: String
    if metadata == null:
        print_message = item.get_text(0)
    elif metadata is PlatformGraph:
        print_message = metadata.to_string()
    elif metadata is Surface:
        print_message = metadata.to_string()
    elif metadata is Edge:
        print_message = metadata.to_string()
    elif metadata is FailedEdgeAttempt:
        print_message = metadata.to_string()
    elif metadata is EdgeStepCalcResultMetadata:
        print_message = metadata.to_string()
    # FIXME: ------------------ Handle final metadata types for the steps/fails/etc.
    else:
        Utils.error("Invalid metadata object stored on TreeItem: %s" % metadata)
    
    print("PlatformGraphInspector item selected: %s" % print_message)

func _draw_step_items_for_edge_attempt( \
        edge_attempt: EdgeCalcResultMetadata, \
        edge_item: TreeItem) -> void:
    if !edge_attempt.failed_before_creating_steps:
        # Draw rows for each step-attempt.
        for step_attempt in edge_attempt.children_step_attempts:
            _draw_step_item( \
                    step_attempt, \
                    edge_item)
    else:
        # Draw a message for the invalid edge.
        var tree_item := tree_view.create_item(edge_item)
        tree_item.set_text( \
                0, \
                EdgeCalculationTrajectoryAnnotator.INVALID_EDGE_TEXT)

func _draw_step_item( \
        step_attempt: EdgeStepCalcResultMetadata, \
        parent_item: TreeItem) -> void:
    # Draw the row for the given step-attempt.
    var tree_item := tree_view.create_item(parent_item)
    var text := _get_step_item_text( \
            step_attempt, \
            0, \
            false)
    tree_item.set_text( \
            0, \
            text)
    tree_item.set_metadata( \
            0, \
            step_attempt)
    
    # Recursively draw rows for each child step-attempt.
    for child_step_attempt in step_attempt.children_step_attempts:
        _draw_step_item( \
                child_step_attempt, \
                tree_item)
    
    if step_attempt.description_list.size() > 1:
        # Draw a closing row for the given step-attempt.
        var tree_item_2 := tree_view.create_item(parent_item)
        text = _get_step_item_text( \
                step_attempt, \
                1, \
                false)
        tree_item_2.set_text( \
                0, \
                text)
        tree_item.set_metadata( \
                0, \
                step_attempt)

func select_edge_or_edge_attempt( \
        start_position: PositionAlongSurface, \
        end_position: PositionAlongSurface, \
        edge_type: int, \
        graph: PlatformGraph) -> void:
    var tree_item := _find_canonical_edge_or_edge_attempt_item( \
            start_position.surface, \
            end_position.surface, \
            start_position.target_point, \
            end_position.target_point, \
            edge_type, \
            graph)
    
    if tree_item != null:
        tree_item.select(0)
        
        # Expand all ancestor items.
        while tree_item != tree_root:
            tree_item.collapsed = false
            tree_item = tree_item.get_parent()
        
        # FIXME: ----------------
        # - Instantiate state as needed.
        # - Don't collapse anything, so don't destroy any state.
    
    # FIXME: -----------------------
    # - Move failed edge subtrees to exist as siblings to valid under the destination surface and
    #   edge type subtrees.
    # - Select the destination surface as a fall-back.
    # - De-select any currently selected steps.
    
    # FIXME: ----------------------- Scroll to the correct spot.

func _select_edge_step_items_from_tree_item(item: TreeItem) -> void:
    var step_result_metadata: EdgeStepCalcResultMetadata = item.get_metadata(0)
    assert(step_result_metadata is EdgeStepCalcResultMetadata)
    
    current_selected_step_items = []
    for child in item.get_parent():
        if child.get_metadata() == step_result_metadata:
            current_selected_step_items.push_back(child)
    
    _set_selected_step_items_text( \
            current_selected_step_items, \
            step_result_metadata)

static func _set_selected_step_items_text( \
        items: Array, \
        step_result_metadata: EdgeStepCalcResultMetadata) -> void:
    for i in range(items.size()):
        items[i].set_text( \
                0, \
                _get_step_item_text( \
                        step_result_metadata, \
                        i, \
                        true))

func _clear_selected_step_items() -> void:
    # Unmark all previously selected tree items.
    for i in range(current_selected_step_items.size()):
        var tree_item: TreeItem = current_selected_step_items[i]
        var step_attempt: EdgeStepCalcResultMetadata = tree_item.get_metadata(0)
        var text := _get_step_item_text( \
                step_attempt, \
                i, \
                false)
        tree_item.set_text( \
                0, \
                text)
    
    current_selected_step_items.clear()

static func _get_step_item_text( \
        step_attempt: EdgeStepCalcResultMetadata, \
        description_index: int, \
        is_selected: bool) -> String:
    return "%s%s: %s%s%s" % [ \
            "*" if \
                    is_selected else \
                    "",
            step_attempt.index + 1, \
            "[BT] " if \
                    step_attempt.is_backtracking and description_index == 0 \
                    else "", \
            "[RF] " if \
                    step_attempt.replaced_a_fake and description_index == 0 else \
                    "", \
            step_attempt.description_list[description_index], \
        ]

func _find_canonical_surface_item( \
        surface: Surface, \
        graph: PlatformGraph) -> TreeItem:
    var surface_side_label_prefix: String
    match surface.side:
        SurfaceSide.FLOOR:
            surface_side_label_prefix = "Floors"
        SurfaceSide.LEFT_WALL:
            surface_side_label_prefix = "Left walls"
        SurfaceSide.RIGHT_WALL:
            surface_side_label_prefix = "Right walls"
        SurfaceSide.CEILING:
            surface_side_label_prefix = "Ceilings"
        _:
            Utils.error("Invalid SurfaceSide: %s" % surface.side)
    
    for graph_item in tree_root.get_children():
        if graph_item.get_metadata(0) != graph:
            continue
        for graph_child_item in graph_item.get_children():
            if !graph_child_item.get_text(0).begins_with("Surfaces"):
                continue
            for surfaces_child_item in graph_child_item.get_children():
                if !surfaces_child_item.get_text(0).begins_with(surface_side_label_prefix):
                    continue
                for surface_item in surfaces_child_item.get_children():
                    if surface_item.get_metadata(0) != surface:
                        continue
                    return surface_item
    
    Utils.error("Canonical TreeItem not found for Surface: %s" % surface.to_string())
    return null

func _find_canonical_edge_or_edge_attempt_item( \
        start_surface: Surface, \
        end_surface: Surface, \
        target_start: Vector2, \
        target_end: Vector2, \
        edge_type: int, \
        graph: PlatformGraph, \
        throws_on_not_found := false) -> TreeItem:
    # Determine which start/end positions to check.
    var is_a_jump_calculator := JUMP_CALCULATORS.find(edge_type) >= 0
    var all_jump_land_positions := \
            JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                    graph.movement_params, \
                    start_surface, \
                    end_surface, \
                    is_a_jump_calculator)
    var closest_jump_land_positions := _find_closest_jump_land_positions( \
            target_start, \
            target_end, \
            all_jump_land_positions)
    var start := closest_jump_land_positions.jump_position.target_point
    var end := closest_jump_land_positions.land_position.target_point
    
    var origin_surface_item := _find_canonical_surface_item( \
            start_surface, \
            graph)
    
    var edge_type_string := EdgeType.get_type_string(edge_type)
    var valid_edge: Edge
    var failed_edge: FailedEdgeAttempt
    
    if origin_surface_item != null:
        for destination_surface_item in origin_surface_item.get_children():
            if destination_surface_item.get_metadata(0) != end_surface:
                continue
            for edge_type_item in destination_surface_item.get_children():
                if !edge_type_item.get_text(0).begins_with(edge_type_string):
                    continue
                for edge_type_child_item in edge_type_item.get_children():
                    if !edge_type_child_item.get_text(0) != \
                            "Failed edge calculations (which passed broad-phase checks)":
                        # Considering a valid-edge item.
                        valid_edge = edge_type_child_item.get_metadata(0)
                        if Geometry.are_points_equal_with_epsilon( \
                                        valid_edge.start, \
                                        start, \
                                        0.01) and \
                                Geometry.are_points_equal_with_epsilon( \
                                        valid_edge.end, \
                                        end, \
                                        0.01):
                            return edge_type_child_item
                    else:
                        # Consider failed-edge items.
                        for failed_edge_item in edge_type_child_item.get_children():
                            failed_edge = failed_edge_item.get_metadata(0)
                            if Geometry.are_points_equal_with_epsilon( \
                                            failed_edge.start, \
                                            start, \
                                            0.01) and \
                                    Geometry.are_points_equal_with_epsilon( \
                                            failed_edge.end, \
                                            end, \
                                            0.01):
                                return failed_edge_item
    
    if throws_on_not_found:
        Utils.error("Canonical TreeItem not found for Edge step: " + \
                "start=%s, " + \
                "end=%s, " + \
                "end_type=%s," + \
                "player_name=%s" % [ \
                str(start), \
                str(end), \
                EdgeType.get_type_string(edge_type), \
                graph.movement_params.name, \
                ])
    
    return null

static func _find_closest_jump_land_positions( \
        target_jump_position: Vector2, \
        target_land_position: Vector2, \
        all_jump_land_positions: Array) -> JumpLandPositions:
    var closest_jump_land_positions: JumpLandPositions
    var closest_distance_sum := INF
    var current_distance_sum: float
    
    for jump_land_positions in all_jump_land_positions:
        current_distance_sum = \
                target_jump_position.distance_to(jump_land_positions.jump_position) + \
                target_land_position.distance_to(jump_land_positions.land_position)
        if current_distance_sum < closest_distance_sum:
            closest_jump_land_positions = jump_land_positions
            closest_distance_sum = current_distance_sum
    
    return closest_jump_land_positions
