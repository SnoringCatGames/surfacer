extends Node2D
class_name NavigatorAnnotator

var EDGE_COLOR = Colors.opacify(Colors.PURPLE, Colors.ALPHA_XFAINT)
const TRAJECTORY_WIDTH := 4.0

var NODE_COLOR = Colors.opacify(Colors.PURPLE_D, Colors.ALPHA_XFAINT)
const NODE_TARGET_POINT_RADIUS := 6.0
const NODE_T_LENGTH := 16.0
const NODE_T_WIDTH := 4.0

var navigator: Navigator
var path: PlatformGraphPath

func _init(navigator: Navigator) -> void:
    self.navigator = navigator

func _draw() -> void:
    if navigator.is_currently_navigating:
        _draw_path(self, navigator.current_path)

func check_for_update() -> void:
    if navigator.current_path != path:
        path = navigator.current_path
        update()

func _draw_path(canvas: CanvasItem, path: PlatformGraphPath) -> void:
    for edge in path.edges:
        # Draw edge start position.
        canvas.draw_circle(edge.start, NODE_TARGET_POINT_RADIUS, NODE_COLOR)
        
        # Draw edge.
        if edge is InterSurfaceEdge or \
                edge is AirToSurfaceEdge or \
                edge is AirToAirEdge or \
                edge is SurfaceToAirEdge:
            draw_polyline(edge.instructions.frame_discrete_positions_from_test, EDGE_COLOR, \
                    TRAJECTORY_WIDTH)
        elif edge is IntraSurfaceEdge:
            draw_line(edge.start, edge.end, EDGE_COLOR, TRAJECTORY_WIDTH)
        else:
            Utils.error()
    
    # Draw final end position.
    canvas.draw_circle(path.destination, NODE_TARGET_POINT_RADIUS, \
            NODE_COLOR)
