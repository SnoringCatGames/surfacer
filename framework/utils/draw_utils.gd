extends Node
class_name DrawUtils

const SURFACE_DEPTH := 16.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_END_RATIO := .2

const SURFACE_DEPTH_DIVISION_SIZE := SURFACE_DEPTH / SURFACE_DEPTH_DIVISIONS_COUNT

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
    var surface_depth_division_offset = surface.normal * -SURFACE_DEPTH_DIVISION_SIZE
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
            canvas.draw_polyline(polyline, color, SURFACE_DEPTH_DIVISION_SIZE)
#            Utils.draw_dashed_polyline(self, polyline, color, 4.0, 3.0, 0.0, 2.0, false)
    else:
        canvas.draw_circle(vertices[0], 6.0, color)

static func draw_position_along_surface(canvas: CanvasItem, position: PositionAlongSurface, \
        target_point_color: Color, t_color: Color, target_point_radius := 4.0, t_length := 16.0, \
        t_width := 4.0, t_value_drawn := true, target_point_drawn := false, \
        surface_drawn := false) -> void:
    # Optionally, annotate the t value.
    if t_value_drawn:
        if position.target_projection_onto_surface == Vector2.INF:
            position.target_projection_onto_surface = \
                    Geometry.project_point_onto_surface(position.target_point, position.surface)
        var normal = position.surface.normal
        var start = position.target_projection_onto_surface + normal * t_length / 2
        var end = position.target_projection_onto_surface - normal * t_length / 2
        canvas.draw_line(start, end, t_color, t_width)
    
    # Optionally, annotate the target point.
    if target_point_drawn:
        canvas.draw_circle(position.target_point, target_point_radius, \
                target_point_color)
    
    # Optionally, annotate the surface.
    if surface_drawn:
        draw_surface(canvas, position.surface, target_point_color)

static func draw_x(canvas: CanvasItem, center: Vector2, width: float, height: float, color: Color, \
        stroke_width: float) -> void:
    var half_width := width / 2.0
    var half_height := height / 2.0
    canvas.draw_line(center + Vector2(-half_width, -half_height), \
            center + Vector2(half_width, half_height), color, stroke_width)
    canvas.draw_line(center + Vector2(half_width, -half_height), \
            center + Vector2(-half_width, half_height), color, stroke_width)

static func draw_plus(canvas: CanvasItem, center: Vector2, width: float, height: float, \
        color: Color, stroke_width: float) -> void:
    var half_width := width / 2.0
    var half_height := height / 2.0
    canvas.draw_line(center + Vector2(-half_width, 0), center + Vector2(half_width, 0), color, \
            stroke_width)
    canvas.draw_line(center + Vector2(0, -half_height), center + Vector2(0, half_height), color, \
            stroke_width)

static func draw_shape_outline(canvas: CanvasItem, position: Vector2, shape: Shape2D, \
        rotation: float, color: Color, thickness: float) -> void:
    var is_rotated_90_degrees = abs(fmod(rotation + PI * 2, PI) - PI / 2) < Geometry.FLOAT_EPSILON
    
    # Ensure that collision boundaries are only ever axially aligned.
    assert(is_rotated_90_degrees or abs(rotation) < Geometry.FLOAT_EPSILON)
    
    if shape is CircleShape2D:
        draw_circle_outline(canvas, position, shape.radius, color, thickness)
    elif shape is CapsuleShape2D:
        draw_capsule_outline(canvas, position, shape.radius, shape.height, is_rotated_90_degrees, \
                color, thickness)
    elif shape is RectangleShape2D:
        draw_rectangle_outline( \
                canvas, position, shape.extents, is_rotated_90_degrees, color, thickness)
    else:
        Utils.error("Invalid Shape2D provided for draw_shape: %s. The supported shapes are: " + \
                "CircleShape2D, CapsuleShape2D, RectangleShape2D." % shape)

static func draw_circle_outline(canvas: CanvasItem, center: Vector2, radius: float, color: Color, \
        border_width := 1.0, sector_arc_length := 4.0) -> void:
    var sector_count := ceil(2.0 * PI * radius / sector_arc_length)
    var delta_theta := 2.0 * PI / sector_count
    var theta := 0.0
    var vertices := PoolVector2Array()
    vertices.resize(sector_count + 1)
    var vertex: Vector2
    
    for i in range(sector_count + 1):
        vertices[i] = Vector2(cos(theta), sin(theta)) * radius + center
        theta += delta_theta
    
    canvas.draw_polyline(vertices, color, border_width)

static func draw_rectangle_outline(canvas: CanvasItem, center: Vector2, \
        half_width_height: Vector2, is_rotated_90_degrees: bool, color: Color, \
        thickness := 1.0) -> void:
    var x_offset: float = half_width_height.y if is_rotated_90_degrees else half_width_height.x
    var y_offset: float = half_width_height.x if is_rotated_90_degrees else half_width_height.y
    
    var polyline := PoolVector2Array()
    polyline.resize(5)
    
    polyline[0] = center + Vector2(-x_offset, -y_offset)
    polyline[1] = center + Vector2(x_offset, -y_offset)
    polyline[2] = center + Vector2(x_offset, y_offset)
    polyline[3] = center + Vector2(-x_offset, y_offset)
    polyline[4] = polyline[0]
    
    # For some reason, the first and last line segments seem to have off-by-one errors that would
    # cause the segments to not be exactly horizontal and vertical, so these offsets fix that.
    polyline[0] += Vector2(-0.5, 0.5)
    polyline[4] += Vector2(0.75, 0.0)
    
    canvas.draw_polyline(polyline, color, thickness)

static func draw_capsule_outline(canvas: CanvasItem, center: Vector2, radius: float, \
        height: float, is_rotated_90_degrees: bool, color: Color, thickness := 1.0, \
        sector_arc_length := 4.0) -> void:
    var sector_count := ceil((PI * radius / sector_arc_length) / 2.0) * 2.0
    var delta_theta := PI / sector_count
    var theta := PI / 2.0 if is_rotated_90_degrees else 0.0
    var capsule_end_offset := \
            Vector2(height / 2.0, 0.0) if is_rotated_90_degrees else Vector2(0.0, height / 2.0)
    var end_center := center - capsule_end_offset
    var vertices := PoolVector2Array()
    var vertex_count := (sector_count + 1) * 2 + 1
    vertices.resize(vertex_count)
    var vertex: Vector2
    
    for i in range(sector_count + 1):
        vertices[i] = Vector2(cos(theta), sin(theta)) * radius + end_center
        theta += delta_theta
    
    end_center = center + capsule_end_offset
    theta -= delta_theta
    
    for i in range(sector_count + 1, (sector_count + 1) * 2):
        vertices[i] = Vector2(cos(theta), sin(theta)) * radius + end_center
        theta += delta_theta
    
    vertices[vertex_count - 1] = vertices[0]
    
    canvas.draw_polyline(vertices, color, thickness)
