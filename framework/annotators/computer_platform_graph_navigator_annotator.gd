extends Node2D
class_name ComputerPlatformGraphNavigatorAnnotator

const ORIGIN_TARGET_POINT_RADIUS := 4.0
var ORIGIN_COLOR = Color.from_hsv(0.66, 0.6, 0.9, 1.0)
const ORIGIN_T_LENGTH := 16.0
const ORIGIN_T_WIDTH := 4.0

const MID_POINT_TARGET_POINT_RADIUS := 4.0
const MID_POINT_T_LENGTH := 16.0
const MID_POINT_T_WIDTH := 4.0

const DESTINATION_TARGET_POINT_RADIUS := 4.0
var DESTINATION_COLOR = Color.from_hsv(0.33, 0.6, 0.9, 1.0)
const DESTINATION_T_LENGTH := 16.0
const DESTINATION_T_WIDTH := 4.0

var navigator: PlatformGraphNavigator
var path: PlatformGraphPath

func _init(navigator: PlatformGraphNavigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if navigator.is_currently_navigating:
        _draw_path(self, navigator.current_path)

func check_for_update() -> void:
    if navigator.current_path != path:
        path = navigator.current_path
        update()

func _draw_path(canvas: CanvasItem, path: PlatformGraphPath) -> void:
    # FIXME: Draw the optional movements to/from air at the start and end of the path
    
    DrawUtils.draw_position_along_surface(canvas, path.surface_origin, ORIGIN_COLOR, \
            ORIGIN_COLOR, ORIGIN_TARGET_POINT_RADIUS, ORIGIN_T_LENGTH, ORIGIN_T_WIDTH, true)
    DrawUtils.draw_position_along_surface(canvas, path.surface_destination, DESTINATION_COLOR, \
            DESTINATION_COLOR, DESTINATION_TARGET_POINT_RADIUS, DESTINATION_T_LENGTH, \
            DESTINATION_T_WIDTH, true)
    
    var color := Color.from_hsv(randf(), 0.9, 0.9, 0.3)
    var edge: PlatformGraphEdge = path.edges[0]
    
    DrawUtils.draw_position_along_surface(canvas, edge.end, color, color, \
            MID_POINT_TARGET_POINT_RADIUS, MID_POINT_T_LENGTH, MID_POINT_T_WIDTH)
    # FIXME: Draw edge line.
    
    for i in range(1, path.edges.size()):
        edge = path.edges[i]
        color = Color.from_hsv(randf(), 0.9, 0.9, 0.3)
        DrawUtils.draw_position_along_surface(canvas, edge.start, color, color, \
                MID_POINT_TARGET_POINT_RADIUS, MID_POINT_T_LENGTH, MID_POINT_T_WIDTH, true)
        DrawUtils.draw_position_along_surface(canvas, edge.end, color, color, \
                MID_POINT_TARGET_POINT_RADIUS, MID_POINT_T_LENGTH, MID_POINT_T_WIDTH, true)
        # FIXME: Draw edge line.
