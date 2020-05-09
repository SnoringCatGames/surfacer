extends Node2D
class_name PlatformGraphInspector

# FIXME: LEFT OFF HERE: --------------------------------------
# - Figure out how to expand/collapse certain items by default.

signal platform_graph_selected
signal surface_selected
signal edge_attempt_selected
signal edge_step_selected

var global

# Array<PlatformGraph>
var graphs: Array

var tree_view: Tree
var tree_root: TreeItem

# Array<TreeItem>
var current_selected_step_items := []

func _init(graphs: Array) -> void:
    self.graphs = graphs

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
    
    var floors_item := tree_view.create_item(graph_item)
    floors_item.collapsed = true
    var left_walls_item := tree_view.create_item(graph_item)
    left_walls_item.collapsed = true
    var right_walls_item := tree_view.create_item(graph_item)
    right_walls_item.collapsed = true
    var ceilings_item := tree_view.create_item(graph_item)
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
        
        _draw_surface_item( \
                surface, \
                graph, \
                parent_item)
    
    floors_item.set_text( \
            0, \
            "Floors [%s]" % graph.counts.FLOOR)
    left_walls_item.set_text( \
            0, \
            "Left walls [%s]" % graph.counts.LEFT_WALL)
    right_walls_item.set_text( \
            0, \
            "Right walls [%s]" % graph.counts.RIGHT_WALL)
    ceilings_item.set_text( \
            0, \
            "Ceilings [%s]" % graph.counts.CEILING)
    
    var global_counts_item := tree_view.create_item(graph_item)
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
    for type_name in EdgeType.keys():
        edge_type_count_item = tree_view.create_item(global_counts_item)
        edge_type_count_item.set_text( \
                0, \
                "%s %ss" % [ \
                        graph.counts[type_name], \
                        type_name, \
                        ])

func _draw_surface_item( \
        surface: Surface, \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var surface_item := tree_view.create_item(parent_item)
    var text := "%s [%s, %s]" % [ \
            SurfaceSide.get_side_string(surface.side), \
            surface.first_point, \
            surface.last_point, \
            ]
    surface_item.set_text( \
            0, \
            text)
    surface_item.set_metadata( \
            0, \
            surface)
    surface_item.collapsed = true
    
    var edge: Edge
    var edge_item: TreeItem
    
    for origin_node in graph.surfaces_to_outbound_nodes[surface]:
        for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
            edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
            
            edge_item = tree_view.create_item(surface_item)
            text = "%s [%s, %s]" % [ \
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

func _on_tree_item_selected() -> void:
    var item := tree_view.get_selected()
    var metadata = item.get_metadata(0)
    
    _log_item_selected(item)
    
    # Ensure this node (and each of its ancestors) is expanded.
    while item != tree_root:
        item.collapsed = false
        item = item.get_parent()
    
    # FIXME: ----------------------- Scroll to the correct spot.
    
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
                "edge_attempt_selected", \
                metadata)
    elif metadata is MovementCalcStepDebugState:
        _select_step_item(metadata)
        emit_signal( \
                "edge_step_selected", \
                metadata)
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
    elif metadata is MovementCalcStepDebugState:
        print_message = metadata.to_string()
    else:
        Utils.error("Invalid metadata object stored on TreeItem: %s" % metadata)
    
    print("PlatformGraphInspector item selected: %s" % print_message)

func _draw_step_items_for_edge_attempt( \
        edge_attempt: MovementCalcOverallDebugState, \
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
        step_attempt: MovementCalcStepDebugState, \
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

func _select_step_item(step: MovementCalcStepDebugState) -> void:
    current_selected_step_items = _find_step_items(step)
    
    # Mark all matching tree items.
    for i in range(current_selected_step_items.size()):
        var tree_item: TreeItem = current_selected_step_items[i]
        var text := _get_step_item_text( \
                step, \
                i, \
                true)
        tree_item.set_text(0, text)

func _clear_selected_step_items() -> void:
    # Unmark all previously selected tree items.
    for i in range(current_selected_step_items.size()):
        var tree_item: TreeItem = current_selected_step_items[i]
        var step: MovementCalcStepDebugState = tree_item.get_metadata(0)
        var text := _get_step_item_text( \
                step, \
                i, \
                false)
        tree_item.set_text( \
                0, \
                text)
    
    current_selected_step_items.clear()

func _get_step_item_text( \
        step: MovementCalcStepDebugState, \
        description_index: int, \
        is_selected: bool) -> String:
    return "%s%s: %s%s%s" % [ \
            "*" if \
                    is_selected else \
                    "",
            step.index + 1, \
            "[BT] " if \
                    step.is_backtracking and description_index == 0 \
                    else "", \
            "[RF] " if \
                    step.replaced_a_fake and description_index == 0 else \
                    "", \
            step.description_list[description_index], \
        ]

func _find_step_items(step: MovementCalcStepDebugState) -> Array:
    # FIXME: -----------------------
    # - Will need to have first stored failed attempts for surfaces.
    pass
    return []
