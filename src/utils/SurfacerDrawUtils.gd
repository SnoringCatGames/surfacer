class_name SurfacerDrawUtils
extends DrawUtils

const EDGE_TRAJECTORY_WIDTH := 1.0

const EDGE_WAYPOINT_STROKE_WIDTH := EDGE_TRAJECTORY_WIDTH
const EDGE_WAYPOINT_RADIUS := 6.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_START_RADIUS := 3.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_END_RADIUS := EDGE_WAYPOINT_RADIUS
const EDGE_END_CONE_LENGTH := EDGE_WAYPOINT_RADIUS * 2.0

const EDGE_INSTRUCTION_INDICATOR_LENGTH := 24

const ADJACENT_VERTEX_TOO_CLOSE_DISTANCE_SQUARED_THRESHOLD := 0.25

static func draw_origin_marker(
        canvas: CanvasItem,
        target: Vector2,
        color: Color,
        radius := EDGE_START_RADIUS,
        border_width := 1.0,
        sector_arc_length := 3.0) -> void:
    draw_circle_outline(
            canvas,
            target,
            radius,
            color,
            border_width,
            sector_arc_length)

static func draw_destination_marker(
        canvas: CanvasItem,
        target: Vector2,
        is_target_at_circle_center: bool,
        surface_side: int,
        color: Color,
        cone_length := EDGE_END_CONE_LENGTH,
        circle_radius := EDGE_END_RADIUS,
        is_filled := false,
        border_width := EDGE_WAYPOINT_STROKE_WIDTH,
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
    
    draw_ice_cream_cone(
            canvas,
            cone_end_point,
            circle_center,
            circle_radius,
            color,
            is_filled,
            border_width,
            sector_arc_length)

static func draw_path(
        canvas: CanvasItem,
        path: PlatformGraphPath,
        stroke_width := EDGE_TRAJECTORY_WIDTH,
        color := Color.white,
        trim_front_end_radius := 0.0,
        trim_back_end_radius := 0.0,
        includes_waypoints := false,
        includes_instruction_indicators := false,
        includes_continuous_positions := false,
        includes_discrete_positions := false) -> void:
    var vertices := PoolVector2Array([0])
    for edge in path.edges:
        # The end positions of adjacent edges should be identical, so remove
        # one of them.
        vertices.resize(vertices.size() - 1)
        vertices.append_array(_get_edge_trajectory_vertices(edge))
    if trim_front_end_radius > 0.0:
        vertices = _trim_front_end(
                vertices,
                trim_front_end_radius)
    if trim_back_end_radius > 0.0:
        vertices = _trim_back_end(
                vertices,
                trim_back_end_radius)
    canvas.draw_polyline(
            vertices,
            color,
            stroke_width)

static func _trim_front_end(
        vertices: PoolVector2Array,
        trim_radius: float) -> PoolVector2Array:
    if vertices.empty():
        return vertices
    
    var trim_radius_squared := trim_radius * trim_radius
    var end_position := vertices[0]
    
    var front_index := 1
    for i in range(1, vertices.size()):
        if vertices[i].distance_squared_to(end_position) < trim_radius_squared:
            front_index = i + 1
        else:
            break
    
    if front_index >= vertices.size():
        return PoolVector2Array()
    
    front_index -= 1
    
    var start_replacement := \
            Gs.geometry.get_intersection_of_segment_and_circle(
                    vertices[front_index + 1],
                    vertices[front_index],
                    end_position,
                    trim_radius)
    
    vertices = Gs.utils.sub_pool_vector2_array(
            vertices,
            front_index)
    
    vertices[0] = start_replacement
    
    return vertices

static func _trim_back_end(
        vertices: PoolVector2Array,
        trim_radius: float) -> PoolVector2Array:
    if vertices.empty():
        return vertices
    
    var trim_radius_squared := trim_radius * trim_radius
    var count := vertices.size()
    var end_position := vertices[vertices.size() - 1]
    
    var back_index := count - 2
    for i in range(1, count):
        i = count - i - 1
        if vertices[i].distance_squared_to(end_position) < trim_radius_squared:
            back_index = i - 1
        else:
            break
    
    if back_index < 0:
        return PoolVector2Array()
    
    back_index += 1
    
    var end_replacement := \
            Gs.geometry.get_intersection_of_segment_and_circle(
                    vertices[back_index - 1],
                    vertices[back_index],
                    end_position,
                    trim_radius)
    
    vertices = Gs.utils.sub_pool_vector2_array(
            vertices,
            0,
            back_index + 1)
    
    vertices[vertices.size() - 1] = end_replacement
    
    return vertices

static func draw_edge(
        canvas: CanvasItem,
        edge: Edge,
        stroke_width := EDGE_TRAJECTORY_WIDTH,
        base_color := Color.white,
        includes_waypoints := false,
        includes_instruction_indicators := false,
        includes_continuous_positions := true,
        includes_discrete_positions := false) -> void:
    if base_color == Color.white:
        base_color = Surfacer.ann_defaults \
                .EDGE_DISCRETE_TRAJECTORY_COLOR_PARAMS.get_color()
    
    if edge.includes_air_trajectory:
        _draw_edge_from_instructions_positions(
                canvas,
                edge,
                stroke_width,
                base_color,
                includes_waypoints,
                includes_instruction_indicators,
                includes_continuous_positions,
                includes_discrete_positions)
    else:
        _draw_edge_from_end_points(
                canvas,
                edge,
                stroke_width,
                base_color,
                includes_waypoints,
                includes_instruction_indicators)

static func _draw_edge_from_end_points(
        canvas: CanvasItem,
        edge: Edge,
        stroke_width: float,
        base_color: Color,
        includes_waypoints: bool,
        includes_instruction_indicators: bool) -> void:
    canvas.draw_line(
            edge.get_start(),
            edge.get_end(),
            base_color,
            stroke_width)
    
    if includes_waypoints:
        var waypoint_color: Color = Surfacer.ann_defaults \
                .WAYPOINT_COLOR_PARAMS.get_color()
        waypoint_color.h = base_color.h
        waypoint_color.a = base_color.a
        
        draw_destination_marker(
                canvas,
                edge.get_end(),
                true,
                edge.end_position_along_surface.side,
                waypoint_color)
        draw_origin_marker(
                canvas,
                edge.get_start(),
                waypoint_color)
    
    if includes_instruction_indicators:
        var instruction_color: Color = Surfacer.ann_defaults \
                .INSTRUCTION_COLOR_PARAMS.get_color()
        instruction_color.h = base_color.h
        instruction_color.a = base_color.a
        
        # TODO: Draw instruction indicators.

static func _draw_edge_from_instructions_positions(
        canvas: CanvasItem,
        edge: Edge,
        stroke_width: float,
        discrete_trajectory_color: Color,
        includes_waypoints: bool,
        includes_instruction_indicators: bool,
        includes_continuous_positions: bool,
        includes_discrete_positions: bool,
        origin_position_override := Vector2.INF) -> void:
    # Set up colors.
    var continuous_trajectory_color: Color = Surfacer.ann_defaults \
            .EDGE_CONTINUOUS_TRAJECTORY_COLOR_PARAMS.get_color()
    continuous_trajectory_color.h = discrete_trajectory_color.h
    var waypoint_color: Color = Surfacer.ann_defaults \
            .WAYPOINT_COLOR_PARAMS.get_color()
    waypoint_color.h = discrete_trajectory_color.h
    waypoint_color.a = discrete_trajectory_color.a
    var instruction_color: Color = Surfacer.ann_defaults \
            .INSTRUCTION_COLOR_PARAMS.get_color()
    instruction_color.h = discrete_trajectory_color.h
    instruction_color.a = discrete_trajectory_color.a
    
    if includes_continuous_positions:
        # Draw the trajectory (as calculated via continuous equations of motion
        # during step calculations).
        var vertices := _get_edge_trajectory_vertices(
                edge,
                includes_continuous_positions)
        canvas.draw_polyline(
                vertices,
                continuous_trajectory_color,
                stroke_width)
    if includes_discrete_positions:
        # Draw the trajectory (as approximated via discrete time steps during
        # instruction test calculations).
        var vertices := _get_edge_trajectory_vertices(
                edge,
                includes_discrete_positions)
        canvas.draw_polyline(
                vertices,
                discrete_trajectory_color,
                stroke_width)
    
    if includes_waypoints:
        # Draw the intermediate waypoints.
        var waypoint_position: Vector2
        for i in edge.trajectory.waypoint_positions.size() - 1:
            waypoint_position = edge.trajectory.waypoint_positions[i]
            draw_circle_outline(
                    canvas,
                    waypoint_position,
                    EDGE_WAYPOINT_RADIUS,
                    waypoint_color,
                    stroke_width,
                    4.0)
        
        draw_destination_marker(
                canvas,
                edge.get_end(),
                true,
                edge.end_position_along_surface.side,
                waypoint_color)
        
        var origin_position := \
                origin_position_override if \
                origin_position_override != Vector2.INF else \
                edge.get_start()
        draw_origin_marker(
                canvas,
                origin_position,
                waypoint_color)
    
    if includes_instruction_indicators:
        # Draw the horizontal instruction positions.
        for instruction in edge.trajectory.horizontal_instructions:
            draw_instruction_indicator(
                    canvas,
                    instruction.input_key,
                    instruction.is_pressed,
                    instruction.position,
                    EDGE_INSTRUCTION_INDICATOR_LENGTH,
                    instruction_color)
        
        # Draw the vertical instruction end position.
        if edge.trajectory.jump_instruction_end != null:
            draw_instruction_indicator(
                    canvas,
                    "j",
                    false,
                    edge.trajectory.jump_instruction_end.position,
                    EDGE_INSTRUCTION_INDICATOR_LENGTH,
                    instruction_color)

static func _get_edge_trajectory_vertices(
        edge: Edge,
        is_continuous := true,
        removes_too_close_vertices := false) -> PoolVector2Array:
    match edge.edge_type:
        EdgeType.AIR_TO_AIR_EDGE, \
        EdgeType.AIR_TO_SURFACE_EDGE, \
        EdgeType.FALL_FROM_FLOOR_EDGE, \
        EdgeType.FALL_FROM_WALL_EDGE, \
        EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE, \
        EdgeType.JUMP_FROM_SURFACE_TO_AIR_EDGE, \
        EdgeType.JUMP_INTER_SURFACE_EDGE:
            var vertices := \
                    edge.trajectory.frame_continuous_positions_from_steps if \
                    is_continuous else \
                    edge.trajectory.frame_discrete_positions_from_test
            if vertices.empty():
                vertices.push_back(edge.get_start())
            vertices.push_back(edge.get_end())
            if removes_too_close_vertices:
                vertices = _remove_too_close_neighbors(vertices)
            return vertices
        EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE, \
        EdgeType.INTRA_SURFACE_EDGE, \
        EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE:
            return PoolVector2Array([
                edge.get_start(),
                edge.get_end(),
            ])
        EdgeType.UNKNOWN, \
        _:
            Gs.logger.error()
            return PoolVector2Array()

static func _remove_too_close_neighbors(
        vertices: PoolVector2Array) -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    var previous_vertex := vertices[0]
    result[0] = previous_vertex
    var result_size := 1
    
    for index in range(1, vertices.size()):
        var vertex := vertices[index]
        if vertex.distance_squared_to(previous_vertex) > \
                ADJACENT_VERTEX_TOO_CLOSE_DISTANCE_SQUARED_THRESHOLD:
            previous_vertex = vertex
            result[result_size] = previous_vertex
            result_size += 1
    
    result.resize(result_size)
    return result
