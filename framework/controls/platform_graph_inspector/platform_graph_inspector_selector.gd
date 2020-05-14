extends Node2D
class_name PlatformGraphInspectorSelector

var ORIGIN_SURFACE_SELECTION_COLOR := Colors.opacify(Colors.ORANGE, Colors.ALPHA_FAINT)

const ORIGIN_SURFACE_SELECTION_DASH_LENGTH := 6.0
const ORIGIN_SURFACE_SELECTION_DASH_GAP := 8.0
const ORIGIN_SURFACE_SELECTION_DASH_STROKE_WIDTH := 4.0

const ORIGIN_POSITION_RADIUS := 5.0

var inspector
var global

var first_target: PositionAlongSurface
var previous_first_target: PositionAlongSurface

func _init(inspector) -> void:
    self.inspector = inspector

func _ready() -> void:
    self.global = $"/root/Global"

func _process(delta: float) -> void:
    if first_target != previous_first_target:
        previous_first_target = first_target
        update()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and \
            event.button_index == BUTTON_LEFT and \
            !event.pressed and event.control:
        # The user is ctrl+clicking.
        
        var click_position: Vector2 = global.current_level.get_global_mouse_position()
        var surface_position := SurfaceParser.find_closest_position_on_a_surface( \
                click_position, \
                global.current_player_for_clicks)
        
        if first_target == null:
            first_target = surface_position
        else:
            # FIXME: Add support for configuring edge type and graph from radio buttons in the
            #        inspector.
            inspector.select_edge_or_edge_attempt( \
                    first_target, \
                    surface_position, \
                    EdgeType.JUMP_INTER_SURFACE_EDGE, \
                    global.current_player_for_clicks.graph)
            first_target = null
        
    elif event is InputEventKey and \
            event.scancode == KEY_CONTROL and \
            !event.pressed:
        # The user is releasing the ctrl key.
        first_target = null

func _draw() -> void:
    if first_target != null:
        # So far, the user has only selected the first surface in the edge pair.
        _draw_selected_origin()

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
