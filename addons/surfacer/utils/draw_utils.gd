extends Node

const SURFACE_DEPTH := 16.0
const SURFACE_DEPTH_DIVISIONS_COUNT := 8
const SURFACE_ALPHA_END_RATIO := .2

const EDGE_TRAJECTORY_WIDTH := 1.0

const EDGE_WAYPOINT_STROKE_WIDTH := EDGE_TRAJECTORY_WIDTH
const EDGE_WAYPOINT_RADIUS := 6.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_START_RADIUS := 3.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_END_RADIUS := EDGE_WAYPOINT_RADIUS
const EDGE_END_CONE_LENGTH := EDGE_WAYPOINT_RADIUS * 2.0

const EDGE_INSTRUCTION_INDICATOR_LENGTH := 24

const INSTRUCTION_INDICATOR_HEAD_LENGTH_RATIO := 0.35
const INSTRUCTION_INDICATOR_HEAD_WIDTH_RATIO := 0.3
const INSTRUCTION_INDICATOR_STRIKE_THROUGH_LENGTH_RATIO := 0.8
const INSTRUCTION_INDICATOR_STROKE_WIDTH := 1.0

const STRIKE_THROUGH_ANGLE := -PI / 3.0

static func draw_dashed_line( \
        canvas: CanvasItem, \
        from: Vector2, \
        to: Vector2, \
        color: Color, \
        dash_length: float, \
        dash_gap: float, \
        dash_offset: float = 0.0, \
        width: float = 1.0, \
        antialiased: bool = false) -> void:
    var segment_length := from.distance_to(to)
    var direction_normalized: Vector2 = (to - from).normalized()
    
    var current_length := dash_offset
    var current_dash_length: float
    var current_from: Vector2
    var current_to: Vector2
    
    while current_length < segment_length:
        current_dash_length = \
                dash_length if \
                current_length + dash_length <= segment_length else \
                segment_length - current_length
        
        current_from = from + direction_normalized * current_length
        current_to = from + direction_normalized * \
                (current_length + current_dash_length)
        
        canvas.draw_line( \
                current_from, \
                current_to, \
                color, \
                width, \
                antialiased)
        
        current_length += dash_length + dash_gap

# TODO: Update this to honor gaps across vertices.
static func draw_dashed_polyline( \
        canvas: CanvasItem, \
        vertices: PoolVector2Array, \
        color: Color, \
        dash_length: float, \
        dash_gap: float, \
        dash_offset: float = 0.0, \
        width: float = 1.0, \
        antialiased: bool = false) -> void:
    var from: Vector2
    var to: Vector2
    for i in range(vertices.size() - 1):
        from = vertices[i]
        to = vertices[i + 1]
        draw_dashed_line( \
                canvas, \
                from, \
                to, \
                color, \
                dash_length, \
                dash_gap, \
                dash_offset, \
                width, \
                antialiased)

static func draw_dashed_rectangle( \
        canvas: CanvasItem, \
        center: Vector2, \
        half_width_height: Vector2, \
        is_rotated_90_degrees: bool, \
        color: Color, \
        dash_length: float, \
        dash_gap: float, \
        dash_offset: float = 0.0, \
        stroke_width: float = 1.0, \
        antialiased: bool = false) -> void:
    var half_width := \
            half_width_height.y if \
            is_rotated_90_degrees else \
            half_width_height.x
    var half_height := \
            half_width_height.x if \
            is_rotated_90_degrees else \
            half_width_height.y

    var top_left := center + Vector2(-half_width, -half_height)
    var top_right := center + Vector2(half_width, -half_height)
    var bottom_right := center + Vector2(half_width, half_height)
    var bottom_left := center + Vector2(-half_width, half_height)
    
    draw_dashed_line( \
            canvas, \
            top_left, \
            top_right, \
            color, \
            dash_length, \
            dash_gap, \
            dash_offset, \
            stroke_width, \
            antialiased)
    draw_dashed_line( \
            canvas, \
            top_right, \
            bottom_right, \
            color, \
            dash_length, \
            dash_gap, \
            dash_offset, \
            stroke_width, \
            antialiased)
    draw_dashed_line( \
            canvas, \
            bottom_right, \
            bottom_left, \
            color, \
            dash_length, \
            dash_gap, \
            dash_offset, \
            stroke_width, \
            antialiased)
    draw_dashed_line( \
            canvas, \
            bottom_left, \
            top_left, \
            color, \
            dash_length, \
            dash_gap, \
            dash_offset, \
            stroke_width, \
            antialiased)

static func draw_surface( \
        canvas: CanvasItem, \
        surface: Surface, \
        color: Color, \
        depth := SURFACE_DEPTH) -> void:
    var surface_depth_division_size := depth / SURFACE_DEPTH_DIVISIONS_COUNT
    
    var vertices := surface.vertices
    var surface_depth_division_offset := \
            surface.normal * -surface_depth_division_size
    var alpha_start := color.a
    var alpha_end := alpha_start * SURFACE_ALPHA_END_RATIO
    
    var polyline: PoolVector2Array
    var translation: Vector2
    var progress: float
    
    # "Surfaces" can single vertices in the degenerate case.
    if vertices.size() > 1:
        for i in range(SURFACE_DEPTH_DIVISIONS_COUNT):
            translation = surface_depth_division_offset * i
            polyline = ScaffoldUtils.translate_polyline(vertices, translation)
            progress = i / (SURFACE_DEPTH_DIVISIONS_COUNT - 1.0)
            color.a = alpha_start + progress * (alpha_end - alpha_start)
            canvas.draw_polyline( \
                    polyline, \
                    color, \
                    surface_depth_division_size)
    else:
        canvas.draw_circle( \
                vertices[0], \
                6.0, \
                color)

static func draw_position_along_surface( \
        canvas: CanvasItem, \
        position: PositionAlongSurface, \
        target_point_color: Color, \
        t_color: Color, \
        target_point_radius := 4.0, \
        t_length := 16.0, \
        t_width := 4.0, \
        t_value_drawn := true, \
        target_point_drawn := false, \
        surface_drawn := false) -> void:
    # Optionally, annotate the t value.
    if t_value_drawn:
        if position.target_projection_onto_surface == Vector2.INF:
            position.target_projection_onto_surface = \
                    Geometry.project_point_onto_surface( \
                            position.target_point, \
                            position.surface)
        var normal := position.surface.normal
        var start := position.target_projection_onto_surface + \
                normal * t_length / 2.0
        var end := position.target_projection_onto_surface - \
                normal * t_length / 2.0
        canvas.draw_line( \
                start, \
                end, \
                t_color, \
                t_width)
    
    # Optionally, annotate the target point.
    if target_point_drawn:
        canvas.draw_circle( \
                position.target_point, \
                target_point_radius, \
                target_point_color)
    
    # Optionally, annotate the surface.
    if surface_drawn:
        draw_surface( \
                canvas, \
                position.surface, \
                target_point_color)

static func draw_x( \
        canvas: CanvasItem, \
        center: Vector2, \
        width: float, \
        height: float, \
        color: Color, \
        stroke_width: float) -> void:
    var half_width := width / 2.0
    var half_height := height / 2.0
    canvas.draw_line( \
            center + Vector2(-half_width, -half_height), \
            center + Vector2(half_width, half_height), \
            color, \
            stroke_width)
    canvas.draw_line( \
            center + Vector2(half_width, -half_height), \
            center + Vector2(-half_width, half_height), \
            color, \
            stroke_width)

static func draw_plus( \
        canvas: CanvasItem, \
        center: Vector2, \
        width: float, \
        height: float, \
        color: Color, \
        stroke_width: float) -> void:
    var half_width := width / 2.0
    var half_height := height / 2.0
    canvas.draw_line( \
            center + Vector2(-half_width, 0), \
            center + Vector2(half_width, 0), \
            color, \
            stroke_width)
    canvas.draw_line( \
            center + Vector2(0, -half_height), \
            center + Vector2(0, half_height), \
            color, \
            stroke_width)

static func draw_asterisk( \
        canvas: CanvasItem, \
        center: Vector2, \
        width: float, \
        height: float, \
        color: Color, \
        stroke_width: float) -> void:
    var plus_width := width
    var plus_height := height
    var x_width := plus_width * 0.8
    var x_height := plus_height * 0.8
    draw_x( \
            canvas, \
            center, \
            x_width, \
            x_height, \
            color, \
            stroke_width)
    draw_plus( \
            canvas, \
            center, \
            plus_width, \
            plus_height, \
            color, \
            stroke_width)

static func draw_checkmark( \
        canvas: CanvasItem, \
        position: Vector2, \
        width: float, \
        color: Color, \
        stroke_width: float) -> void:
    # We mostly treat the check mark as 90 degrees, divide the check mark into
    # thirds horizontally, and then position it so that the bottom-most point
    # of the checkmark is slightly below the target position. However, we then
    # give the right-right corner a slight adjustment upward, which makes the
    # checkmark slightly more accute than 90.
    var top_left_point := position + Vector2(-width / 3.0, -width / 6.0)
    var bottom_mid_point := position + Vector2(0, width / 6.0)
    var top_right_point := \
            position + Vector2(width * 2.0 / 3.0, -width / 2.0 * 1.33)
    
    canvas.draw_line( \
            top_left_point, \
            bottom_mid_point, \
            color, \
            stroke_width)
    canvas.draw_line( \
            bottom_mid_point, \
            top_right_point, \
            color, \
            stroke_width)

static func draw_instruction_indicator( \
        canvas: CanvasItem, \
        input_key: String, \
        is_pressed: bool, \
        position: Vector2, \
        length: float, \
        color: Color) -> void:
    var half_length := length / 2.0
    var end_offset_from_mid: Vector2
    match input_key:
        "jump":
            end_offset_from_mid = Vector2(0.0, -half_length)
        "move_left":
            end_offset_from_mid = Vector2(-half_length, 0.0)
        "move_right":
            end_offset_from_mid = Vector2(half_length, 0.0)
        _:
            ScaffoldUtils.error("Invalid input_key: %s" % input_key)
    
    var start := position - end_offset_from_mid
    var end := position + end_offset_from_mid
    var head_length := length * INSTRUCTION_INDICATOR_HEAD_LENGTH_RATIO
    var head_width := length * INSTRUCTION_INDICATOR_HEAD_WIDTH_RATIO
    var strike_through_length := \
            INF if \
            is_pressed else \
            length * INSTRUCTION_INDICATOR_STRIKE_THROUGH_LENGTH_RATIO
    
    draw_strike_through_arrow( \
            canvas, \
            start, \
            end, \
            head_length, \
            head_width, \
            strike_through_length, \
            color, \
            INSTRUCTION_INDICATOR_STROKE_WIDTH)

static func draw_arrow( \
        canvas: CanvasItem, \
        start: Vector2, \
        end: Vector2, \
        head_length: float, \
        head_width: float, \
        color: Color, \
        stroke_width: float) -> void:
    draw_strike_through_arrow( \
            canvas, \
            start, \
            end, \
            head_length, \
            head_width, \
            INF, \
            color, \
            stroke_width)

static func draw_strike_through_arrow( \
        canvas: CanvasItem, \
        start: Vector2, \
        end: Vector2, \
        head_length: float, \
        head_width: float, \
        strike_through_length: float, \
        color: Color, \
        stroke_width: float) -> void:
    # Calculate points in the arrow head.
    var start_to_end_angle := start.angle_to_point(end)
    var head_diff_1 := Vector2(head_length, -head_width * 0.5) \
            .rotated(start_to_end_angle)
    var head_diff_2 := Vector2(head_length, head_width * 0.5) \
            .rotated(start_to_end_angle)
    var head_end_1 := end + head_diff_1
    var head_end_2 := end + head_diff_2
    
    # Draw the arrow head.
    canvas.draw_line( \
            end, \
            head_end_1, \
            color, \
            stroke_width)
    canvas.draw_line( \
            end, \
            head_end_2, \
            color, \
            stroke_width)
    
    # Draw the arrow body.
    canvas.draw_line( \
            start, \
            end, \
            color, \
            stroke_width)
    
    # Draw the strike through.
    if strike_through_length != INF:
        var strike_through_angle := start_to_end_angle + STRIKE_THROUGH_ANGLE
        var strike_through_middle := start.linear_interpolate( \
                end, \
                0.5)
        var strike_through_half_length := strike_through_length / 2.0
        var strike_through_offset := Vector2( \
                cos(strike_through_angle) * strike_through_half_length, \
                sin(strike_through_angle) * strike_through_half_length)
        var strike_through_start := \
                strike_through_middle - strike_through_offset
        var strike_through_end := \
                strike_through_middle + strike_through_offset
        canvas.draw_line( \
                strike_through_start, \
                strike_through_end, \
                color, \
                stroke_width)

static func draw_diamond_outline( \
        canvas: CanvasItem, \
        center: Vector2, \
        width: float, \
        height: float, \
        color: Color, \
        stroke_width: float) -> void:
    var half_width := width / 2.0
    var half_height := height / 2.0
    canvas.draw_line( \
            center + Vector2(-half_width, 0), \
            center + Vector2(0, -half_height), \
            color, \
            stroke_width)
    canvas.draw_line(\
            center + Vector2(0, -half_height), \
            center + Vector2(half_width, 0), \
            color, \
            stroke_width)
    canvas.draw_line( \
            center + Vector2(half_width, 0), \
            center + Vector2(0, half_height), \
            color, \
            stroke_width)
    canvas.draw_line( \
            center + Vector2(0, half_height), \
            center + Vector2(-half_width, 0), \
            color, \
            stroke_width)

static func draw_shape_outline( \
        canvas: CanvasItem, \
        position: Vector2, \
        shape: Shape2D, \
        rotation: float, \
        color: Color, \
        thickness: float) -> void:
    var is_rotated_90_degrees = \
            abs(fmod(rotation + PI * 2, PI) - PI / 2) < Geometry.FLOAT_EPSILON
    
    # Ensure that collision boundaries are only ever axially aligned.
    assert(is_rotated_90_degrees or abs(rotation) < Geometry.FLOAT_EPSILON)
    
    if shape is CircleShape2D:
        draw_circle_outline( \
                canvas, \
                position, \
                shape.radius, \
                color, \
                thickness)
    elif shape is CapsuleShape2D:
        draw_capsule_outline( \
                canvas, \
                position, \
                shape.radius, \
                shape.height, \
                is_rotated_90_degrees, \
                color, \
                thickness)
    elif shape is RectangleShape2D:
        draw_rectangle_outline( \
                canvas, \
                position, \
                shape.extents, \
                is_rotated_90_degrees, \
                color, \
                thickness)
    else:
        ScaffoldUtils.error( \
                "Invalid Shape2D provided for draw_shape: %s. The " + \
                "supported shapes are: CircleShape2D, CapsuleShape2D, " + \
                "RectangleShape2D." % shape)

static func draw_circle_outline( \
        canvas: CanvasItem, \
        center: Vector2, \
        radius: float, \
        color: Color, \
        border_width := 1.0, \
        sector_arc_length := 4.0) -> void:
    draw_arc( \
            canvas, \
            center, \
            radius, \
            0.0, \
            2.0 * PI, \
            color, \
            border_width, \
            sector_arc_length)

static func draw_arc( \
        canvas: CanvasItem, \
        center: Vector2, \
        radius: float, \
        start_angle: float, \
        end_angle: float, \
        color: Color, \
        border_width := 1.0, \
        sector_arc_length := 4.0) -> void:
    var points := compute_arc_points( \
            center, \
            radius, \
            start_angle, \
            end_angle, \
            sector_arc_length)
    
    canvas.draw_polyline( \
            points, \
            color, \
            border_width)

static func compute_arc_points(
        center: Vector2, \
        radius: float, \
        start_angle: float, \
        end_angle: float, \
        sector_arc_length := 4.0) -> PoolVector2Array:
    assert(sector_arc_length > 0.0)
    
    var angle_diff := end_angle - start_angle
    var sector_count := floor(abs(angle_diff) * radius / sector_arc_length)
    var delta_theta := sector_arc_length / radius
    var theta := start_angle
    
    if angle_diff == 0:
        return PoolVector2Array([ \
                Vector2(cos(start_angle), sin(start_angle)) * radius + center])
    elif angle_diff < 0:
        delta_theta = -delta_theta
    
    var should_include_partial_sector_at_end := \
            abs(angle_diff) - sector_count * delta_theta > 0.01
    var vertex_count := sector_count + 1
    if should_include_partial_sector_at_end:
        vertex_count += 1
    
    var points := PoolVector2Array()
    points.resize(vertex_count)
    var vertex: Vector2
    
    for i in range(sector_count + 1):
        points[i] = Vector2(cos(theta), sin(theta)) * radius + center
        theta += delta_theta
    
    # Handle the fence-post problem.
    if should_include_partial_sector_at_end:
        points[vertex_count - 1] = \
                Vector2(cos(end_angle), sin(end_angle)) * radius + center
    
    return points

static func draw_rectangle_outline( \
        canvas: CanvasItem, \
        center: Vector2, \
        half_width_height: Vector2, \
        is_rotated_90_degrees: bool, \
        color: Color, \
        thickness := 1.0) -> void:
    var x_offset: float = \
            half_width_height.y if \
            is_rotated_90_degrees else \
            half_width_height.x
    var y_offset: float = \
            half_width_height.x if \
            is_rotated_90_degrees else \
            half_width_height.y
    
    var polyline := PoolVector2Array()
    polyline.resize(5)
    
    polyline[0] = center + Vector2(-x_offset, -y_offset)
    polyline[1] = center + Vector2(x_offset, -y_offset)
    polyline[2] = center + Vector2(x_offset, y_offset)
    polyline[3] = center + Vector2(-x_offset, y_offset)
    polyline[4] = polyline[0]
    
    # For some reason, the first and last line segments seem to have off-by-one
    # errors that would cause the segments to not be exactly horizontal and
    # vertical, so these offsets fix that.
    polyline[0] += Vector2(-0.5, 0.5)
    polyline[4] += Vector2(0.75, 0.0)
    
    canvas.draw_polyline( \
            polyline, \
            color, \
            thickness)

static func draw_capsule_outline( \
        canvas: CanvasItem, \
        center: Vector2, \
        radius: float, \
        height: float, \
        is_rotated_90_degrees: bool, \
        color: Color, \
        thickness := 1.0, \
        sector_arc_length := 4.0) -> void:
    var sector_count := ceil((PI * radius / sector_arc_length) / 2.0) * 2.0
    var delta_theta := PI / sector_count
    var theta := \
            PI / 2.0 if \
            is_rotated_90_degrees else \
            0.0
    var capsule_end_offset := \
            Vector2(height / 2.0, 0.0) if \
            is_rotated_90_degrees else \
            Vector2(0.0, height / 2.0)
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
    
    canvas.draw_polyline( \
            vertices, \
            color, \
            thickness)

static func draw_origin_marker( \
        canvas: CanvasItem, \
        target: Vector2, \
        color: Color, \
        radius := EDGE_START_RADIUS, \
        border_width := 1.0, \
        sector_arc_length := 3.0) -> void:
    draw_circle_outline( \
            canvas, \
            target, \
            radius, \
            color, \
            border_width, \
            sector_arc_length)

static func draw_destination_marker( \
        canvas: CanvasItem, \
        target: Vector2, \
        is_target_at_circle_center: bool, \
        surface_side: int, \
        color: Color, \
        cone_length := EDGE_END_CONE_LENGTH, \
        circle_radius := EDGE_END_RADIUS, \
        is_filled := false, \
        border_width := EDGE_WAYPOINT_STROKE_WIDTH, \
        sector_arc_length := 4.0) -> void:
    var normal := SurfaceSide.get_normal(surface_side)
    
    var cone_end_point: Vector2
    var circle_center: Vector2
    if is_target_at_circle_center:
        cone_end_point = target - normal * cone_length
        circle_center = target
    else:
        cone_end_point = target
        circle_center = target + normal * cone_length
    
    draw_ice_cream_cone( \
            canvas, \
            cone_end_point, \
            circle_center, \
            circle_radius, \
            color, \
            is_filled, \
            border_width, \
            sector_arc_length)

# This applies Thales's theorem to find the points of tangency between the line
# segments from the triangular portion and the circle
# (https://en.wikipedia.org/wiki/Thales%27s_theorem).
static func draw_ice_cream_cone( \
        canvas: CanvasItem, \
        cone_end_point: Vector2, \
        circle_center: Vector2, \
        circle_radius: float, \
        color: Color, \
        is_filled: bool, \
        border_width := 1.0, \
        sector_arc_length := 4.0) -> void:
    var distance_from_cone_end_point_to_circle_center := \
            cone_end_point.distance_to(circle_center)
    
    # Handle the degenerate case of when the cone-end-point lies within the
    # circle.
    if distance_from_cone_end_point_to_circle_center <= circle_radius:
        if is_filled:
            canvas.draw_circle( \
                circle_center, \
                circle_radius, \
                color)
        else:
            draw_circle_outline( \
                    canvas, \
                    circle_center, \
                    circle_radius, \
                    color, \
                    border_width, \
                    sector_arc_length)
        return
    
    var angle_from_circle_center_to_point_of_tangency := \
            acos(circle_radius / distance_from_cone_end_point_to_circle_center)
    var angle_from_circle_center_to_cone_end_point := \
            cone_end_point.angle_to_point(circle_center)
    
    var start_angle := angle_from_circle_center_to_cone_end_point + \
            angle_from_circle_center_to_point_of_tangency
    var end_angle := angle_from_circle_center_to_cone_end_point + \
            2.0 * PI - \
            angle_from_circle_center_to_point_of_tangency
    
    var points := compute_arc_points(
            circle_center, \
            circle_radius, \
            start_angle, \
            end_angle, \
            sector_arc_length)
    points.push_back(cone_end_point)
    points.push_back(points[0])
    
    if is_filled:
        canvas.draw_colored_polygon( \
                points, \
                color)
    else:
        canvas.draw_polyline( \
                points, \
                color, \
                border_width)

static func draw_path( \
        canvas: CanvasItem, \
        path: PlatformGraphPath, \
        stroke_width := EDGE_TRAJECTORY_WIDTH, \
        color := Color.white, \
        includes_waypoints := false, \
        includes_instruction_indicators := false, \
        includes_continuous_positions := false, \
        includes_discrete_positions := false) -> void:
    var vertices := PoolVector2Array()
    for edge in path.edges:
        vertices.append_array(_get_edge_trajectory_vertices(edge))
    canvas.draw_polyline( \
            vertices, \
            color, \
            stroke_width)

static func draw_edge( \
        canvas: CanvasItem, \
        edge: Edge, \
        stroke_width := EDGE_TRAJECTORY_WIDTH, \
        base_color := Color.white, \
        includes_waypoints := false, \
        includes_instruction_indicators := false, \
        includes_continuous_positions := true, \
        includes_discrete_positions := false) -> void:
    if base_color == Color.white:
        base_color = AnnotationElementDefaults \
                .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS.get_color()
    
    if edge is AirToAirEdge or \
            edge is AirToSurfaceEdge or \
            edge is FallFromWallEdge or \
            edge is FallFromFloorEdge or \
            edge is JumpInterSurfaceEdge or \
            edge is JumpFromSurfaceToAirEdge:
        _draw_edge_from_instructions_positions( \
                canvas, \
                edge, \
                stroke_width, \
                base_color, \
                includes_waypoints, \
                includes_instruction_indicators, \
                includes_continuous_positions, \
                includes_discrete_positions)
    elif edge is ClimbDownWallToFloorEdge or \
            edge is IntraSurfaceEdge or \
            edge is WalkToAscendWallFromFloorEdge:
        _draw_edge_from_end_points( \
                canvas, \
                edge, \
                stroke_width, \
                base_color, \
                includes_waypoints, \
                includes_instruction_indicators)
    elif edge is ClimbOverWallToFloorEdge:
        _draw_climb_over_wall_to_floor_edge( \
                canvas, \
                edge, \
                stroke_width, \
                base_color, \
                includes_waypoints, \
                includes_instruction_indicators)
    else:
        ScaffoldUtils.error("Unexpected Edge subclass: %s" % edge)

static func _draw_edge_from_end_points( \
        canvas: CanvasItem, \
        edge: Edge, \
        stroke_width: float, \
        base_color: Color, \
        includes_waypoints: bool, \
        includes_instruction_indicators: bool) -> void:
    canvas.draw_line( \
            edge.start, \
            edge.end, \
            base_color, \
            stroke_width)
    
    if includes_waypoints:
        var waypoint_color: Color = AnnotationElementDefaults \
                .WAYPOINT_COLOR_PARAMS.get_color()
        waypoint_color.h = base_color.h
        waypoint_color.a = base_color.a
        
        draw_destination_marker( \
                canvas, \
                edge.end, \
                true, \
                edge.end_position_along_surface.side, \
                waypoint_color)
        draw_origin_marker( \
                canvas, \
                edge.start, \
                waypoint_color)
    
    if includes_instruction_indicators:
        var instruction_color: Color = AnnotationElementDefaults \
                .INSTRUCTION_COLOR_PARAMS.get_color()
        instruction_color.h = base_color.h
        instruction_color.a = base_color.a
        
        # TODO: Draw instruction indicators.

static func _draw_climb_over_wall_to_floor_edge( \
        canvas: CanvasItem, \
        edge: ClimbOverWallToFloorEdge, \
        stroke_width: float, \
        base_color: Color, \
        includes_waypoints: bool, \
        includes_instruction_indicators: bool) -> void:
    var vertices := _get_edge_trajectory_vertices(edge)
    canvas.draw_polyline( \
            vertices, \
            base_color, \
            stroke_width)
    
    if includes_waypoints:
        var waypoint_color: Color = AnnotationElementDefaults \
                .WAYPOINT_COLOR_PARAMS.get_color()
        waypoint_color.h = base_color.h
        waypoint_color.a = base_color.a
        
        draw_destination_marker( \
                canvas, \
                edge.end, \
                true, \
                edge.end_position_along_surface.side, \
                waypoint_color)
        draw_origin_marker( \
                canvas, \
                edge.start, \
                waypoint_color)
    
    if includes_instruction_indicators:
        var instruction_color: Color = AnnotationElementDefaults \
                .INSTRUCTION_COLOR_PARAMS.get_color()
        instruction_color.h = base_color.h
        instruction_color.a = base_color.a
        
        # TODO: Draw instruction indicators.

static func _draw_edge_from_instructions_positions( \
        canvas: CanvasItem, \
        edge: Edge, \
        stroke_width: float, \
        discrete_trajectory_color: Color, \
        includes_waypoints: bool, \
        includes_instruction_indicators: bool, \
        includes_continuous_positions: bool, \
        includes_discrete_positions: bool, \
        origin_position_override := Vector2.INF) -> void:
    # Set up colors.
    var continuous_trajectory_color: Color = AnnotationElementDefaults \
            .EDGE_CONTINUOUS_TRAJECTORY_COLOR_PARAMS.get_color()
    continuous_trajectory_color.h = discrete_trajectory_color.h
    var waypoint_color: Color = AnnotationElementDefaults \
            .WAYPOINT_COLOR_PARAMS.get_color()
    waypoint_color.h = discrete_trajectory_color.h
    waypoint_color.a = discrete_trajectory_color.a
    var instruction_color: Color = AnnotationElementDefaults \
            .INSTRUCTION_COLOR_PARAMS.get_color()
    instruction_color.h = discrete_trajectory_color.h
    instruction_color.a = discrete_trajectory_color.a
    
    if includes_continuous_positions:
        # Draw the trajectory (as calculated via continuous equations of motion
        # during step calculations).
        var vertices := _get_edge_trajectory_vertices( \
                edge, \
                includes_continuous_positions)
        canvas.draw_polyline( \
                vertices, \
                continuous_trajectory_color, \
                stroke_width)
    if includes_discrete_positions:
        # Draw the trajectory (as approximated via discrete time steps during
        # instruction test calculations).
        var vertices := _get_edge_trajectory_vertices( \
                edge, \
                includes_discrete_positions)
        canvas.draw_polyline( \
                vertices, \
                discrete_trajectory_color, \
                stroke_width)
    
    if includes_waypoints:
        # Draw the intermediate waypoints.
        var waypoint_position: Vector2
        for i in range(edge.trajectory.waypoint_positions.size() - 1):
            waypoint_position = edge.trajectory.waypoint_positions[i]
            draw_circle_outline( \
                    canvas, \
                    waypoint_position, \
                    EDGE_WAYPOINT_RADIUS, \
                    waypoint_color, \
                    stroke_width, \
                    4.0)
        
        draw_destination_marker( \
                canvas, \
                edge.end, \
                true, \
                edge.end_position_along_surface.side, \
                waypoint_color)
        
        var origin_position := \
                origin_position_override if \
                origin_position_override != Vector2.INF else \
                edge.start
        draw_origin_marker( \
                canvas, \
                origin_position, \
                waypoint_color)
    
    if includes_instruction_indicators:
        # Draw the horizontal instruction positions.
        for instruction in edge.trajectory.horizontal_instructions:
            draw_instruction_indicator( \
                    canvas, \
                    instruction.input_key, \
                    instruction.is_pressed, \
                    instruction.position, \
                    EDGE_INSTRUCTION_INDICATOR_LENGTH, \
                    instruction_color)
        
        # Draw the vertical instruction end position.
        if edge.trajectory.jump_instruction_end != null:
            draw_instruction_indicator( \
                    canvas, \
                    "jump", \
                    false, \
                    edge.trajectory.jump_instruction_end.position, \
                    EDGE_INSTRUCTION_INDICATOR_LENGTH, \
                    instruction_color)

static func _get_edge_trajectory_vertices( \
        edge: Edge, \
        is_continuous := true) -> PoolVector2Array:
    match edge.edge_type:
        EdgeType.AIR_TO_AIR_EDGE, \
        EdgeType.AIR_TO_SURFACE_EDGE, \
        EdgeType.FALL_FROM_FLOOR_EDGE, \
        EdgeType.FALL_FROM_WALL_EDGE, \
        EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
        EdgeType.JUMP_INTER_SURFACE_EDGE:
            var vertices := \
                    edge.trajectory.frame_continuous_positions_from_steps if \
                    is_continuous else \
                    edge.trajectory.frame_discrete_positions_from_test
            if vertices.empty():
                vertices.push_back(edge.start)
            vertices.push_back(edge.end)
            return vertices
        EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE, \
        EdgeType.INTRA_SURFACE_EDGE, \
        EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE:
            return PoolVector2Array([ \
                edge.start, \
                edge.end, \
            ])
        EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE:
            var mid_point := Vector2(edge.start.x, edge.end.y)
            return PoolVector2Array([ \
                edge.start, \
                mid_point, \
                edge.end, \
            ])
        EdgeType.UNKNOWN, \
        _:
            ScaffoldUtils.error()
            return PoolVector2Array()
