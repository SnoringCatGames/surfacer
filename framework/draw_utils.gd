extends Node
class_name DrawUtils

const SURFACE_DEPTH := 8.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_END_RATIO := .2

const DEPTH_DIVISION_SIZE := SURFACE_DEPTH / SURFACE_DEPTH_DIVISIONS_COUNT

static func draw_empty_circle(canvas: CanvasItem, center: Vector2, radius: float, color: Color, \
        border_width := 1.0, sector_arc_length := 4.0) -> void:
    var sector_count := ceil(2.0 * PI * radius / sector_arc_length)
    var delta_theta := 2.0 * PI / sector_count
    var theta := 0.0
    var vertices = PoolVector2Array()
    vertices.resize(sector_count + 1)
    var vertex: Vector2
    
    for i in range(sector_count + 1):
        vertices[i] = Vector2(cos(theta), sin(theta)) * radius + center
        theta += delta_theta
    
    canvas.draw_polyline(vertices, color, border_width)

static func draw_dashed_line(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, \
        dash_length: float, dash_gap: float, dash_offset: float = 0.0, \
        width: float = 1.0, antialiased: bool = false) -> void:
    var segment_length := from.distance_to(to)
    var direction_normalized: Vector2 = (to - from).normalized()
    
    var current_length := dash_offset
    var current_dash_length: float
    var current_from: Vector2
    var current_to: Vector2
    
    while current_length < segment_length:
        current_dash_length = dash_length if current_length + dash_length <= segment_length \
                else segment_length - current_length
        
        current_from = from + direction_normalized * current_length
        current_to = from + direction_normalized * (current_length + current_dash_length)
        
        canvas.draw_line(current_from, current_to, color, width, antialiased)
        
        current_length += dash_length + dash_gap

# TODO: Update this to honor gaps across vertices.
static func draw_dashed_polyline(canvas: CanvasItem, vertices: PoolVector2Array, color: Color, \
        dash_length: float, dash_gap: float, dash_offset: float = 0.0, \
        width: float = 1.0, antialiased: bool = false) -> void:
    var from: Vector2
    var to: Vector2
    for i in range(vertices.size() - 1):
        from = vertices[i]
        to = vertices[i + 1]
        draw_dashed_line(canvas, from, to, color, dash_length, dash_gap, dash_offset, width, \
                antialiased)

static func draw_surface(canvas: CanvasItem, surface: Surface, color: Color) -> void:
    var vertices = surface.vertices
    var surface_depth_division_offset = surface.normal * -DEPTH_DIVISION_SIZE
    var alpha_start = color.a
    var alpha_end = alpha_start * SURFACE_ALPHA_END_RATIO
    
    var polyline: PoolVector2Array
    var translation: Vector2
    var progress: float
    
    # "Surfaces" can single vertices in the degenerate case.
    if vertices.size() > 1:
        for i in range(SURFACE_DEPTH_DIVISIONS_COUNT):
            translation = surface_depth_division_offset * i
            polyline = Utils.translate_polyline(vertices, translation)
            progress = i / (SURFACE_DEPTH_DIVISIONS_COUNT - 1.0)
            color.a = alpha_start + progress * (alpha_end - alpha_start)
            canvas.draw_polyline(polyline, color, DEPTH_DIVISION_SIZE)
#            Utils.draw_dashed_polyline(self, polyline, color, 4.0, 3.0, 0.0, 2.0, false)
    else:
        canvas.draw_circle(vertices[0], 6.0, color)

static func draw_position_along_surface(canvas: CanvasItem, position: PositionAlongSurface, \
        target_point_color: Color, t_color: Color, target_point_radius := 4.0, t_length := 16.0, \
        t_width := 4.0) -> void:
    # Annotate the target point.
    canvas.draw_circle(position.target_point, target_point_radius, \
            target_point_color)
    
    # Annotate the t value.
    if position.target_projection_onto_surface == null:
        position.target_projection_onto_surface = \
                Geometry.project_point_onto_surface(position.target_point, position.surface)
    var normal = position.surface.normal
    var start = position.target_projection_onto_surface + normal * t_length / 2
    var end = position.target_projection_onto_surface - normal * t_length / 2
    canvas.draw_line(start, end, t_color, t_width)
