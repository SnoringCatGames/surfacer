extends Node2D
class_name PlatformGraphInspectorSelector

var ORIGIN_SURFACE_SELECTION_COLOR := Colors.opacify( \
        Colors.ORANGE, \
        Colors.ALPHA_FAINT)

const ORIGIN_SURFACE_SELECTION_DASH_LENGTH := 6.0
const ORIGIN_SURFACE_SELECTION_DASH_GAP := 8.0
const ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH := 4.0

const ORIGIN_POSITION_RADIUS := 5.0

const CLICK_POSITION_DISTANCE_SQUARED_THRESHOLD := 10000

var inspector

var first_target: PositionAlongSurface
var previous_first_target: PositionAlongSurface
# Array<JumpLandPositions>
var possible_jump_land_positions := []
# Array<AnnotationElement>
var current_annotation_elements := []

func _init(inspector) -> void:
    self.inspector = inspector

func _process(delta: float) -> void:
    if first_target != previous_first_target:
        previous_first_target = first_target
        update()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and event.control:
        # The user is ctrl+clicking.
        
        var click_position: Vector2 = \
                Global.current_level.get_global_mouse_position()
        var surface_position := \
                SurfaceParser.find_closest_position_on_a_surface( \
                        click_position, \
                        Global.current_player_for_clicks)
        
        if first_target == null:
            # Selecting the jump position.
            first_target = surface_position
        else:
            # Selecting the land position.
            
            possible_jump_land_positions = JumpLandPositionsUtils \
                    .calculate_jump_land_positions_for_surface_pair( \
                            Global.current_player_for_clicks.movement_params, \
                            first_target.surface, \
                            surface_position.surface)
            
            # FIXME: Add support for configuring edge type and graph from radio
            #        buttons in the inspector.
            inspector.select_edge_or_surface( \
                    first_target, \
                    surface_position, \
                    EdgeType.JUMP_INTER_SURFACE_EDGE, \
                    Global.current_player_for_clicks.graph)
            first_target = null
        
    elif event is InputEventKey and \
            event.scancode == KEY_CONTROL and \
            !event.pressed:
        # The user is releasing the ctrl key.
        first_target = null

func _draw() -> void:
    Global.element_annotator.erase_all(current_annotation_elements)
    current_annotation_elements.clear()
    
    if first_target != null:
        # So far, the user has only selected the first surface in the edge pair.
        _draw_selected_origin()
    else:
        _draw_possible_jump_land_positions()

func _draw_selected_origin() -> void:
    DrawUtils.draw_dashed_polyline( \
            self, \
            first_target.surface.vertices, \
            ORIGIN_SURFACE_SELECTION_COLOR, \
            ORIGIN_SURFACE_SELECTION_DASH_LENGTH, \
            ORIGIN_SURFACE_SELECTION_DASH_GAP, \
            0.0, \
            ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH)
    DrawUtils.draw_circle_outline( \
            self, \
            first_target.target_point, \
            ORIGIN_POSITION_RADIUS, \
            ORIGIN_SURFACE_SELECTION_COLOR, \
            ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH)

func _draw_possible_jump_land_positions() -> void:
    var element: JumpLandPositionsAnnotationElement
    for jump_land_positions in possible_jump_land_positions:
        element = JumpLandPositionsAnnotationElement.new(jump_land_positions)
        current_annotation_elements.push_back(element)
    
    Global.element_annotator.add_all(current_annotation_elements)
