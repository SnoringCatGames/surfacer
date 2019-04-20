extends Node2D
class_name ComputerPlatformGraphNavigatorAnnotator

var ORIGIN_COLOR = Color.from_hsv(0.66, 0.6, 0.9, 0.8)
const ORIGIN_TARGET_POINT_RADIUS := 4.0
const ORIGIN_T_LENGTH := 16.0
const ORIGIN_T_WIDTH := 4.0

var MID_POINT_COLOR = Color.from_hsv(0.75, 0.6, 0.9, 0.3)
const MID_POINT_TARGET_POINT_RADIUS := 4.0
const MID_POINT_T_LENGTH := 16.0
const MID_POINT_T_WIDTH := 4.0

var DESTINATION_COLOR = Color.from_hsv(0.33, 0.6, 0.9, 0.6)
const DESTINATION_TARGET_POINT_RADIUS := 4.0
const DESTINATION_T_LENGTH := 16.0
const DESTINATION_T_WIDTH := 4.0

var EDGE_COLOR = Color.from_hsv(0.75, 0.8, 0.9, 0.35)
var MOVEMENT_ALONG_SURFACE_COLOR = Color.from_hsv(0.86, 0.6, 0.9, 0.25)
const EDGE_TRAJECTORY_WIDTH := 4.0

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
    var previous_end: PositionAlongSurface = path.surface_origin
    
    # Annotate the edges.
    for edge in path.edges:
        # Annotate the movement along the surface from the end-position of the previous edge.
        draw_line(previous_end.target_point, edge.start.target_point, \
                MOVEMENT_ALONG_SURFACE_COLOR, EDGE_TRAJECTORY_WIDTH)
        
        # Annotate the actual edge.
        DrawUtils.draw_position_along_surface(canvas, edge.start, MID_POINT_COLOR, \
                MID_POINT_COLOR, MID_POINT_TARGET_POINT_RADIUS, MID_POINT_T_LENGTH, \
                MID_POINT_T_WIDTH, true)
        DrawUtils.draw_position_along_surface(canvas, edge.end, MID_POINT_COLOR, MID_POINT_COLOR, \
                MID_POINT_TARGET_POINT_RADIUS, MID_POINT_T_LENGTH, MID_POINT_T_WIDTH, true)
        # TODO: Draw the realistic edge trajectory?
        draw_line(edge.start.target_point, edge.end.target_point, \
                EDGE_COLOR, EDGE_TRAJECTORY_WIDTH)
        
        previous_end = edge.end
    
    # Annotate the movement along the surface from the end-position of the previous edge.
    draw_line(previous_end.target_point, path.surface_destination.target_point, \
            MOVEMENT_ALONG_SURFACE_COLOR, EDGE_TRAJECTORY_WIDTH)
    
    # Annotate the optional movements to/from air at the start and end of the path
    if path.has_start_instructions:
        draw_line(path.start_instructions_origin, path.surface_origin.target_point, \
                ORIGIN_COLOR, EDGE_TRAJECTORY_WIDTH)
    if path.has_end_instructions:
        draw_line(path.end_instructions_destination, path.surface_destination.target_point, \
                DESTINATION_COLOR, EDGE_TRAJECTORY_WIDTH)
    
    # Annotate the origin and destination points.
    DrawUtils.draw_position_along_surface(canvas, path.surface_origin, ORIGIN_COLOR, \
            ORIGIN_COLOR, ORIGIN_TARGET_POINT_RADIUS, ORIGIN_T_LENGTH, ORIGIN_T_WIDTH, true)
    DrawUtils.draw_position_along_surface(canvas, path.surface_destination, DESTINATION_COLOR, \
            DESTINATION_COLOR, DESTINATION_TARGET_POINT_RADIUS, DESTINATION_T_LENGTH, \
            DESTINATION_T_WIDTH, true)
