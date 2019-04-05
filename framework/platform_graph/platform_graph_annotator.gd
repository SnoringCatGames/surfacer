extends Node2D
class_name PlatformGraphAnnotator

var graph: PlatformGraph

const SURFACE_DEPTH := 8.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_START := .8
const SURFACE_ALPHA_END := .1

func _init(graph: PlatformGraph) -> void:
    self.graph = graph

func _draw() -> void:
    _draw_surfaces(graph.floors, Global.UP)
    _draw_surfaces(graph.ceilings, Global.DOWN)
    _draw_surfaces(graph.right_walls, Global.LEFT)
    _draw_surfaces(graph.left_walls, Global.RIGHT)

func _draw_surfaces(surfaces: Array, normal: Vector2) -> void:
    var depth_division_size = SURFACE_DEPTH / SURFACE_DEPTH_DIVISIONS_COUNT
    var surface_depth_division_offset = normal * -depth_division_size
    
    var color: Color
    var polyline: PoolVector2Array
    var translation: Vector2
    var progress: float
    
    for surface in surfaces:
        color = Color.from_hsv(randf(), 0.8, 0.8, 1)
        
        # "Surfaces" can single vertices in the degenerate case.
        if surface.size() > 1:
            for i in range(SURFACE_DEPTH_DIVISIONS_COUNT):
                translation = surface_depth_division_offset * i
                polyline = translate_polyline(surface, translation)
                progress = i / (SURFACE_DEPTH_DIVISIONS_COUNT - 1.0)
                color.a = SURFACE_ALPHA_START + progress * (SURFACE_ALPHA_END - SURFACE_ALPHA_START)
                draw_polyline(polyline, color, depth_division_size)
#                Global.draw_dashed_polyline(self, polyline, color, 4.0, 3.0, 0.0, 2.0, false)
        else:
            color.a = 0.6
            draw_circle(surface[0], 8.0, color)

static func translate_polyline(vertices: PoolVector2Array, translation: Vector2) \
        -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    for i in range(vertices.size()):
        result[i] = vertices[i] + translation
    return result
