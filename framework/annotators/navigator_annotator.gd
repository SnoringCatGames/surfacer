extends Node2D
class_name NavigatorAnnotator

var CURRENT_PATH_COLOR := \
        Colors.opacify(Colors.PURPLE, Colors.ALPHA_FAINT)
var PREVIOUS_PATH_COLOR := \
        Colors.opacify(Colors.PURPLE, Colors.ALPHA_XFAINT)
var DESTINATION_INDICATOR_FILL_COLOR := \
        Colors.opacify(Colors.PURPLE, Colors.ALPHA_XXFAINT)
var DESTINATION_INDICATOR_STROKE_COLOR := \
        Colors.opacify(Colors.PURPLE, Colors.ALPHA_SLIGHTLY_FAINT)
var ORIGIN_INDICATOR_FILL_COLOR := \
        DESTINATION_INDICATOR_FILL_COLOR
var ORIGIN_INDICATOR_STROKE_COLOR := \
        DESTINATION_INDICATOR_STROKE_COLOR

const ORIGIN_INDICATOR_RADIUS := 16.0
const DESTINATIAN_INDICATOR_LENGTH := 64.0
const DESTINATION_INDICATOR_RADIUS := 16.0

const INDICATOR_STROKE_WIDTH := 1.0

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath

func _init(navigator: Navigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if previous_path != null:
        _draw_path( \
                previous_path, \
                PREVIOUS_PATH_COLOR)
    if current_path != null:
        _draw_path( \
                current_path, \
                CURRENT_PATH_COLOR)
        
        # Draw the origin indicator.
        self.draw_circle( \
                navigator.current_path.origin, \
                ORIGIN_INDICATOR_RADIUS, \
                ORIGIN_INDICATOR_FILL_COLOR)
        DrawUtils.draw_circle_outline( \
                self, \
                navigator.current_path.origin, \
                ORIGIN_INDICATOR_RADIUS, \
                ORIGIN_INDICATOR_STROKE_COLOR, \
                INDICATOR_STROKE_WIDTH, \
                4.0)
        
        # Draw the destination indicator.
        var cone_end_point := navigator.current_destination.target_projection_onto_surface
        var circle_center := cone_end_point + navigator.current_destination.surface.normal * \
                (DESTINATIAN_INDICATOR_LENGTH - DESTINATION_INDICATOR_RADIUS)
        DrawUtils.draw_ice_cream_cone( \
                self, \
                cone_end_point, \
                circle_center, \
                DESTINATION_INDICATOR_RADIUS, \
                DESTINATION_INDICATOR_FILL_COLOR, \
                true, \
                INF, \
                4.0)
        DrawUtils.draw_ice_cream_cone( \
                self, \
                cone_end_point, \
                circle_center, \
                DESTINATION_INDICATOR_RADIUS, \
                DESTINATION_INDICATOR_STROKE_COLOR, \
                false, \
                INDICATOR_STROKE_WIDTH, \
                4.0)

func check_for_update() -> void:
    if navigator.current_path != current_path:
        current_path = navigator.current_path
        update()
    if navigator.previous_path != previous_path:
        previous_path = navigator.previous_path
        update()

func _draw_path( \
        path: PlatformGraphPath, \
        color: Color) -> void:
    for edge in path.edges:
        DrawUtils.draw_edge( \
                self, \
                edge, \
                true, \
                false, \
                false, \
                color)
