extends Node2D
class_name NavigatorAnnotator

var navigator: Navigator
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath

func _init(navigator: Navigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if previous_path != null:
        _draw_path( \
                previous_path, \
                AnnotationElementDefaults.NAVIGATOR_PREVIOUS_PATH_COLOR)
    if current_path != null:
        _draw_path( \
                current_path, \
                AnnotationElementDefaults.NAVIGATOR_CURRENT_PATH_COLOR)
        
        # Draw the origin indicator.
        self.draw_circle( \
                navigator.current_path.origin, \
                AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS, \
                AnnotationElementDefaults \
                        .NAVIGATOR_ORIGIN_INDICATOR_FILL_COLOR)
        DrawUtils.draw_circle_outline( \
                self, \
                navigator.current_path.origin, \
                AnnotationElementDefaults.NAVIGATOR_ORIGIN_INDICATOR_RADIUS, \
                AnnotationElementDefaults \
                        .NAVIGATOR_ORIGIN_INDICATOR_STROKE_COLOR, \
                AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH, \
                4.0)
        
        # Draw the destination indicator.
        var cone_end_point := \
                navigator.current_destination.target_projection_onto_surface
        var cone_length: float = \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATIAN_INDICATOR_LENGTH - \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS
        DrawUtils.draw_destination_marker( \
                self, \
                cone_end_point, \
                false, \
                navigator.current_destination.surface.side, \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_FILL_COLOR, \
                cone_length, \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS, \
                true, \
                INF, \
                4.0)
        DrawUtils.draw_destination_marker( \
                self, \
                cone_end_point, \
                false, \
                navigator.current_destination.surface.side, \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_STROKE_COLOR, \
                cone_length, \
                AnnotationElementDefaults \
                        .NAVIGATOR_DESTINATION_INDICATOR_RADIUS, \
                false, \
                AnnotationElementDefaults.NAVIGATOR_INDICATOR_STROKE_WIDTH, \
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
