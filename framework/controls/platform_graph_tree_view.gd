extends Node2D
class_name PlatformGraphTreeView

# FIXME: LEFT OFF HERE: --------------------------------------
# - Figure out how to expand/collapse certain items by default.

signal platform_graph_selected
signal surface_selected
signal edge_attempt_selected
signal edge_step_selected

var global

# Array<PlatformGraph>
var graphs: Array

var step_tree_view: Tree
var step_tree_root: TreeItem

## Dictionary<TreeItem, MovementCalcStepDebugState>
#var tree_item_to_step_attempt := {}
## Dictionary<MovementCalcStepDebugState, Array<TreeItem>>
#var step_attempt_to_tree_items := {}
#
## Array<TreeItem>
#var current_highlighted_tree_items := []
#
#var edge_attempt: MovementCalcOverallDebugState

func _init(graphs: Array) -> void:
    self.graphs = graphs

func _ready() -> void:
    global = $"/root/Global"
    
    step_tree_view = Tree.new()
    step_tree_view.rect_min_size = Vector2( \
            0.0, \
            DebugPanel.SECTIONS_HEIGHT)
    step_tree_view.hide_root = true
    step_tree_view.hide_folding = true
    step_tree_view.connect( \
            "item_selected", \
            self, \
            "_on_tree_item_selected")
    global.debug_panel.add_section(step_tree_view)

func _draw() -> void:
    # FIXME: Only clear parts that actually need to be cleared.
    
    # Clear any previous items.
    step_tree_view.clear()
    step_tree_root = step_tree_view.create_item()
    
    for graph in graphs:
        _draw_platform_graph_item( \
                graph, \
                step_tree_root)

func _draw_platform_graph_item( \
        graph: PlatformGraph, \
        parent_item: TreeItem) -> void:
    var graph_item := step_tree_view.create_item(parent_item)
    graph_item.set_text( \
            0, \
            "Platform graph [%s]" % graph.movement_params.name)
    graph_item.set_metadata( \
            0, \
            graph)
    
    var floors_item := step_tree_view.create_item(graph_item)
    var left_walls_item := step_tree_view.create_item(graph_item)
    var right_walls_item := step_tree_view.create_item(graph_item)
    var ceilings_item := step_tree_view.create_item(graph_item)
    
    var global_counts := {
        floor = 0,
        left_wall = 0,
        right_wall = 0,
        ceiling = 0,
    }
    
    var edge_type_keys := [
        "AirToAirEdge",
        "AirToSurfaceEdge",
        "ClimbDownWallToFloorEdge",
        "ClimbOverWallToFloorEdge",
        "FallFromFloorEdge",
        "FallFromWallEdge",
        "IntraSurfaceEdge",
        "JumpFromSurfaceToAirEdge",
        "JumpInterSurfaceEdge",
        "WalkToAscendWallFromFloorEdge",
    ]
    
    for edge_type_key in edge_type_keys:
        global_counts[edge_type_key] = 0
    
    for surface in graph.surfaces_set:
        match surface.side:
            SurfaceSide.FLOOR:
                parent_item = floors_item
                global_counts.floor += 1
            SurfaceSide.LEFT_WALL:
                parent_item = left_walls_item
                global_counts.left_wall += 1
            SurfaceSide.RIGHT_WALL:
                parent_item = right_walls_item
                global_counts.right_wall += 1
            SurfaceSide.CEILING:
                parent_item = ceilings_item
                global_counts.ceiling += 1
            _:
                Utils.error()
        
        _draw_surface_item( \
                surface, \
                graph, \
                global_counts, \
                parent_item)
    
    floors_item.set_text( \
            0, \
            "Floors [%s]" % global_counts.floor)
    left_walls_item.set_text( \
            0, \
            "Left walls [%s]" % global_counts.left_wall)
    right_walls_item.set_text( \
            0, \
            "Right walls [%s]" % global_counts.right_wall)
    ceilings_item.set_text( \
            0, \
            "Ceilings [%s]" % global_counts.ceiling)
    
    var global_counts_item := step_tree_view.create_item(graph_item)
    global_counts_item.set_text( \
            0, \
            "Global counts")
    
    var total_surfaces_item := step_tree_view.create_item(global_counts_item)
    total_surfaces_item.set_text( \
            0, \
            "%s total surfaces" % graph.surfaces_set.size())
    
    var total_edges_item := step_tree_view.create_item(global_counts_item)
    var total_edges_count := 0
    for edge_type_key in edge_type_keys:
        total_edges_count += global_counts[edge_type_key]
    total_edges_item.set_text( \
            0, \
            "%s total edges" % total_edges_count)
    
    for key in global_counts:
        step_tree_view \
                .create_item(global_counts_item) \
                .set_text( \
                        0, \
                        "%s %ss" % [ \
                                global_counts[key], \
                                key \
                                ])

func _draw_surface_item( \
        surface: Surface, \
        graph: PlatformGraph, \
        global_counts: Dictionary, \
        parent_item: TreeItem) -> void:
    var surface_item := step_tree_view.create_item(parent_item)
    var text := "%s [%s, %s]" % [ \
            SurfaceSide.get_side_string(surface.side), \
            surface.first_point, \
            surface.last_point \
            ]
    surface_item.set_text( \
            0, \
            text)
    surface_item.set_metadata( \
            0, \
            surface)
    
    var edge: Edge
    var edge_item: TreeItem
    
    for origin_node in graph.surfaces_to_outbound_nodes[surface]:
        for destination_node in graph.nodes_to_nodes_to_edges[origin_node]:
            edge = graph.nodes_to_nodes_to_edges[origin_node][destination_node]
            
            edge_item = step_tree_view.create_item(surface_item)
            text = "%s [%s, %s]" % [ \
                    edge.name, \
                    edge.start, \
                    edge.end \
                    ]
            edge_item.set_text( \
                    0, \
                    text)
            edge_item.set_metadata( \
                    0, \
                    edge)
            
            global_counts[edge.name] += 1

#func _draw() -> void:
#    # FIXME: Only clear parts that actually need to be cleared.
#
#    # Clear any previous items.
#    step_tree_view.clear()
#    step_tree_root = step_tree_view.create_item()
#    tree_item_to_step_attempt.clear()
#    step_attempt_to_tree_items.clear()
#    current_highlighted_tree_items.clear()
#
#    if edge_attempt != null:
#        _draw_step_tree_panel()
#
#func _draw_step_tree_panel() -> void:
#    if !edge_attempt.failed_before_creating_steps:
#        # Draw rows for each step-attempt.
#        for step_attempt in edge_attempt.children_step_attempts:
#            _draw_step_tree_item( \
#                    step_attempt, \
#                    step_tree_root)
#    else:
#        # Draw a message for the invalid edge.
#        var tree_item := step_tree_view.create_item(step_tree_root)
#        tree_item.set_text( \
#                0, \
#                EdgeCalculationTrajectoryAnnotator.INVALID_EDGE_TEXT)
#        tree_item_to_step_attempt[tree_item] = null
#        step_attempt_to_tree_items[null] = [tree_item]
#
#func _draw_step_tree_item( \
#        step_attempt: MovementCalcStepDebugState, \
#        parent_tree_item: TreeItem) -> void:
#    # Draw the row for the given step-attempt.
#    var tree_item := step_tree_view.create_item(parent_tree_item)
#    var text := _get_tree_item_text( \
#            step_attempt, \
#            0, \
#            false)
#    tree_item.set_text( \
#            0, \
#            text)
#    tree_item_to_step_attempt[tree_item] = step_attempt
#    step_attempt_to_tree_items[step_attempt] = [tree_item]
#
#    # Recursively draw rows for each child step-attempt.
#    for child_step_attempt in step_attempt.children_step_attempts:
#        _draw_step_tree_item( \
#                child_step_attempt, \
#                tree_item)
#
#    if step_attempt.description_list.size() > 1:
#        # Draw a closing row for the given step-attempt.
#        var tree_item_2 := step_tree_view.create_item(parent_tree_item)
#        text = _get_tree_item_text( \
#                step_attempt, \
#                1, \
#                false)
#        tree_item_2.set_text( \
#                0, \
#                text)
#        tree_item_to_step_attempt[tree_item_2] = step_attempt
#        step_attempt_to_tree_items[step_attempt].push_back(tree_item_2)

func _on_tree_item_selected() -> void:
    var selected_tree_item := step_tree_view.get_selected()
    
    # FIXME: -----------------------
    # - Determine the type of the tree item.
    # - Expand recursively to the correct spot.
    # - Scroll to the correct spot.
    pass
    
#    if !tree_item_to_step_attempt.has(selected_tree_item):
#        Utils.error("Invalid tree-view item state")
#        return
#
#    var selected_step_attempt: MovementCalcStepDebugState = \
#            tree_item_to_step_attempt[selected_tree_item]
#    if selected_step_attempt != null:
#        _on_step_selected(selected_step_attempt)
#        emit_signal( \
#                "step_selected", \
#                selected_step_attempt)

#func _on_step_selected(selected_step_attempt: MovementCalcStepDebugState) -> void:
#    var tree_item: TreeItem
#    var old_highlighted_step_attempt: MovementCalcStepDebugState
#    var text: String
#
#    # Unmark previously matching tree items.
#    for i in range(current_highlighted_tree_items.size()):
#        tree_item = current_highlighted_tree_items[i]
#        old_highlighted_step_attempt = tree_item_to_step_attempt[tree_item]
#        text = _get_tree_item_text( \
#                old_highlighted_step_attempt, \
#                i, \
#                false)
#        tree_item.set_text(0, text)
#
#    current_highlighted_tree_items = step_attempt_to_tree_items[selected_step_attempt]
#
#    # Mark all matching tree items.
#    for i in range(current_highlighted_tree_items.size()):
#        tree_item = current_highlighted_tree_items[i]
#        text = _get_tree_item_text( \
#                selected_step_attempt, \
#                i, \
#                true)
#        tree_item.set_text(0, text)
#
#func _get_tree_item_text( \
#        step_attempt: MovementCalcStepDebugState, \
#        description_index: int, \
#        includes_highlight_marker: bool) -> String:
#    return "%s%s: %s%s%s" % [ \
#            "*" if \
#                    includes_highlight_marker else \
#                    "",
#            step_attempt.index + 1, \
#            "[BT] " if \
#                    step_attempt.is_backtracking and description_index == 0 \
#                    else "", \
#            "[RF] " if \
#                    step_attempt.replaced_a_fake and description_index == 0 else \
#                    "", \
#            step_attempt.description_list[description_index], \
#        ]
