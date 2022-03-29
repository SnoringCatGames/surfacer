class_name PlatformGraphInspectorSelector
extends Node2D


var inspector

var first_target: PositionAlongSurface
var previous_first_target: PositionAlongSurface
# Array<JumpLandPositions>
var possible_jump_land_positions := []
# Array<AnnotationElement>
var current_annotation_elements := []

var selection_time := -1.0


func _init(inspector) -> void:
    self.inspector = inspector


func _process(_delta: float) -> void:
    if first_target != previous_first_target:
        previous_first_target = first_target
        update()


func _unhandled_input(event: InputEvent) -> void:
    if Sc.gui.is_player_interaction_enabled and \
            event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and event.control:
        # The player is ctrl+clicking.
        
        var click_position: Vector2 = \
                Sc.utils.get_level_touch_position(event)
        
        # TODO: Update SurfaceStore APIs to not need the character to be given.
        if !is_instance_valid(Sc.level.player_character):
            first_target = null
            return
        
        var surface_position := \
                SurfaceFinder.find_closest_position_on_a_surface(
                        click_position,
                        Sc.level.player_character,
                        SurfaceReachability.ANY)
        if !is_instance_valid(surface_position):
            first_target = null
            return
        
        if first_target == null:
            # Selecting the jump position.
            first_target = surface_position
            possible_jump_land_positions = []
        else:
            # Selecting the land position.
            
            var character_category_name: String = \
                    Su.graph_inspector.last_selected_character_category_name
            
            if character_category_name == "":
                # We don't know what character to base our inspection on.
                first_target = null
                return
            
            var movement_params: MovementParameters = \
                    Su.movement.character_movement_params[
                        character_category_name]
            possible_jump_land_positions = JumpLandPositionsUtils \
                    .calculate_jump_land_positions_for_surface_pair(
                            movement_params,
                            first_target.surface,
                            surface_position.surface)
            
            selection_time = Sc.time.get_play_time()
            
            # TODO: Add support for configuring edge type and graph from radio
            #       buttons in the inspector?
            var graph: PlatformGraph = \
                    Sc.level.graph_parser.platform_graphs[
                        character_category_name]
            inspector.select_edge_or_surface(
                    first_target,
                    surface_position,
                    EdgeType.JUMP_FROM_SURFACE_EDGE,
                    graph)
            first_target = null
        
    elif event is InputEventKey and \
            event.scancode == KEY_CONTROL and \
            !event.pressed:
        # The player is releasing the ctrl key.
        first_target = null


func _draw() -> void:
    Sc.annotators.element_annotator \
            .erase_all(current_annotation_elements)
    current_annotation_elements.clear()
    
    if first_target != null:
        # So far, the player has only selected the first surface in the edge
        # pair.
        _draw_selected_origin()
    else:
        _draw_possible_jump_land_positions()


func _draw_selected_origin() -> void:
    Sc.draw.draw_dashed_polyline(
            self,
            first_target.surface.vertices,
            Sc.annotators.params.inspector_select_origin_surface_color.sample(),
            Sc.annotators.params.inspector_select_origin_surface_dash_length,
            Sc.annotators.params.inspector_select_origin_surface_dash_gap,
            0.0,
            Sc.annotators.params.inspector_select_origin_surface_dash_stroke_width)
    Sc.draw.draw_circle_outline(
            self,
            first_target.target_point,
            Sc.annotators.params.inspector_select_origin_position_radius,
            Sc.annotators.params.inspector_select_origin_surface_color.sample(),
            Sc.annotators.params.inspector_select_origin_surface_dash_stroke_width)


func _draw_possible_jump_land_positions() -> void:
    for jump_land_positions in possible_jump_land_positions:
        current_annotation_elements.push_back(
                JumpLandPositionsAnnotationElement.new(jump_land_positions))
    
    Sc.annotators.element_annotator \
            .add_all(current_annotation_elements)


func clear() -> void:
    first_target = null
    possible_jump_land_positions = []
    update()
    selection_time = -1.0


func should_selection_have_been_handled_in_tree_by_now() -> bool:
    return selection_time + \
    Sc.annotators.params \
            .inspector_select_delay_for_tree_to_handle_inspector_selection_threshold < \
            Sc.time.get_play_time()
