class_name SurfacerDrawUtils
extends DrawUtils


const SQRT_TWO := sqrt(2.0)

const EDGE_TRAJECTORY_WIDTH := 1.0

const EDGE_WAYPOINT_STROKE_WIDTH := EDGE_TRAJECTORY_WIDTH
const EDGE_WAYPOINT_RADIUS := 6.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_START_RADIUS := 3.0 * EDGE_WAYPOINT_STROKE_WIDTH
const EDGE_END_RADIUS := EDGE_WAYPOINT_RADIUS
const EDGE_END_CONE_LENGTH := EDGE_WAYPOINT_RADIUS * 2.0

const PATH_DOWNBEAT_HASH_LENGTH := EDGE_TRAJECTORY_WIDTH * 5
const PATH_OFFBEAT_HASH_LENGTH := EDGE_TRAJECTORY_WIDTH * 3

const EDGE_INSTRUCTION_INDICATOR_LENGTH := 24

const IN_AIR_DESTINATION_INDICATOR_CONE_COUNT := 3
const IN_AIR_DESTINATION_INDICATOR_SIZE_RATIO := 0.8

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
        destination: PositionAlongSurface,
        is_based_on_target_point: bool,
        color: Color,
        cone_length := EDGE_END_CONE_LENGTH,
        circle_radius := EDGE_END_RADIUS,
        is_filled := false,
        border_width := EDGE_WAYPOINT_STROKE_WIDTH,
        sector_arc_length := 4.0) -> void:
    if destination.surface != null:
        # Draw a cone pointing toward the surface.
        
        var normal := SurfaceSide.get_normal(destination.side)
        
        var cone_end_point: Vector2
        var circle_center: Vector2
        if is_based_on_target_point:
            cone_end_point = destination.target_point - normal * cone_length
            circle_center = destination.target_point
        else:
            cone_end_point = destination.target_projection_onto_surface
            circle_center = \
                    destination.target_projection_onto_surface + \
                    normal * cone_length
        
        draw_ice_cream_cone(
                canvas,
                cone_end_point,
                circle_center,
                circle_radius,
                color,
                is_filled,
                border_width,
                sector_arc_length)
    else:
        # Draw an X centered on the target point.
        
        var cone_end_point := destination.target_point
        
        var cone_center_displacement := \
                cone_length * SQRT_TWO / 2.0 * \
                IN_AIR_DESTINATION_INDICATOR_SIZE_RATIO
        var circle_centers := [
            cone_end_point + Vector2(
                    cone_center_displacement,
                    cone_center_displacement),
            cone_end_point + Vector2(
                    -cone_center_displacement,
                    cone_center_displacement),
            cone_end_point + Vector2(
                    -cone_center_displacement,
                    -cone_center_displacement),
            cone_end_point + Vector2(
                    cone_center_displacement,
                    -cone_center_displacement),
        ]
        
        for i in IN_AIR_DESTINATION_INDICATOR_CONE_COUNT:
            var circle_offset := Vector2(0.0, -cone_center_displacement) \
                    .rotated((2.0 * PI * i) / \
                            IN_AIR_DESTINATION_INDICATOR_CONE_COUNT)
            draw_ice_cream_cone(
                    canvas,
                    cone_end_point,
                    cone_end_point + circle_offset,
                    circle_radius * IN_AIR_DESTINATION_INDICATOR_SIZE_RATIO,
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
    var vertices := PoolVector2Array()
    for edge in path.edges:
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


# NOTE: Calculating a distance-based segment instead of a duration-based
#       segment may be more intuitive, but it's a much more expensive
#       operation. There are two reasons for this:
# -   Trajectory vertices are already calculated according to time
#     intervals--rather than distance intervals.
# -   And distance calculations would require performing many sqrt calls for
#     adjacent vertices each frame, as well as allocating and resizing unknown
#     space for arrays to store this data.
static func draw_path_duration_segment(
        canvas: CanvasItem,
        path: PlatformGraphPath,
        segment_time_start: float,
        segment_time_end: float,
        stroke_width := EDGE_TRAJECTORY_WIDTH,
        color := Color.white,
        trim_front_end_radius := 0.0,
        trim_back_end_radius := 0.0) -> void:
    var vertices: PoolVector2Array
    var edge_start_time := 0.0
    var has_segment_started := false
    for edge in path.edges:
        var edge_end_time: float = edge_start_time + edge.duration
        var is_start_of_segment := \
                !has_segment_started and \
                edge_end_time > segment_time_start
        var is_end_of_segment := edge_end_time > segment_time_end
        
        var edge_vertices: PoolVector2Array
        if has_segment_started or \
                is_start_of_segment:
            edge_vertices = _get_edge_trajectory_vertices(edge, false)
        
        # Calculate the index and point at the start of the segment.
        var index_before_segment := -1
        var first_vertex_in_segment: Vector2
        if is_start_of_segment:
            var time_of_index_before: float
            var time_of_index_after: float
            if edge.trajectory != null:
                index_before_segment = \
                        int((segment_time_start - edge_start_time) / \
                                Time.PHYSICS_TIME_STEP)
                index_before_segment = \
                        min(index_before_segment, edge_vertices.size() - 1)
                time_of_index_before = \
                        edge_start_time + \
                        index_before_segment * Time.PHYSICS_TIME_STEP
                time_of_index_after = \
                        time_of_index_before + Time.PHYSICS_TIME_STEP
            else:
                index_before_segment = 0
                time_of_index_before = edge_start_time
                time_of_index_after = edge_end_time
            
            # Calculate a temp point that aligns with the time boundary.
            if index_before_segment == edge_vertices.size() - 1:
                first_vertex_in_segment = \
                        edge_vertices[edge_vertices.size() - 1]
            else:
                var weight := \
                        (segment_time_start - time_of_index_before) / \
                        (time_of_index_after - time_of_index_before)
                first_vertex_in_segment = lerp(
                        edge_vertices[index_before_segment],
                        edge_vertices[index_before_segment + 1],
                        weight)
        
        # Calculate the index and point at the end of the segment.
        var index_after_segment := -1
        var last_vertex_in_segment: Vector2
        if is_end_of_segment:
            var time_of_index_before: float
            var time_of_index_after: float
            if edge.trajectory != null:
                index_after_segment = \
                        int((segment_time_end - edge_start_time) / \
                                Time.PHYSICS_TIME_STEP) + 1
                index_after_segment = \
                        min(index_after_segment, edge_vertices.size() - 1)
                time_of_index_after = \
                        edge_start_time + \
                        index_after_segment * Time.PHYSICS_TIME_STEP
                time_of_index_before = \
                        time_of_index_after - Time.PHYSICS_TIME_STEP
            else:
                index_after_segment = 1
                time_of_index_before = edge_start_time
                time_of_index_after = edge_end_time
            
            # Calculate a temp point that aligns with the time boundary.
            if index_after_segment == 0:
                last_vertex_in_segment = edge_vertices[0]
            else:
                var weight := \
                        (segment_time_end - time_of_index_before) / \
                        (time_of_index_after - time_of_index_before)
                last_vertex_in_segment = lerp(
                        edge_vertices[index_after_segment - 1],
                        edge_vertices[index_after_segment],
                        weight)
        
        if is_start_of_segment and \
                is_end_of_segment:
            # Capture part of the edge.
            vertices = Gs.utils.sub_pool_vector2_array(
                    edge_vertices,
                    index_before_segment,
                    index_after_segment + 1 - index_before_segment)
            # Substitute the first and last vertices for a temp end point that
            # aligns with the time boundary.
            vertices[0] = first_vertex_in_segment
            vertices[vertices.size() - 1] = last_vertex_in_segment
            break
        elif is_start_of_segment:
            has_segment_started = true
            # Capture part of the edge.
            vertices = Gs.utils.sub_pool_vector2_array(
                    edge_vertices,
                    index_before_segment)
            # Substitute the first vertex for a temp end point that aligns with
            # the time boundary.
            vertices[0] = first_vertex_in_segment
        elif is_end_of_segment:
            # Capture part of the edge.
            var sub_edge_vertices := Gs.utils.sub_pool_vector2_array(
                    edge_vertices,
                    0,
                    index_after_segment + 1)
            vertices.append_array(sub_edge_vertices)
            # Substitute the last vertex for a temp end point that aligns with
            # the time boundary.
            vertices[vertices.size() - 1] = last_vertex_in_segment
            break
        elif has_segment_started:
            # Capture the entire edge.
            vertices.append_array(edge_vertices)
        else:
            # We haven't reached the segment yet.
            pass
        
        edge_start_time = edge_end_time
    
    if trim_front_end_radius > 0.0:
        vertices = _trim_front_end(
                vertices,
                trim_front_end_radius)
    if trim_back_end_radius > 0.0:
        vertices = _trim_back_end(
                vertices,
                trim_back_end_radius)
    
    if vertices.size() < 2:
        return
    
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


static func draw_beat_hashes(
        canvas: CanvasItem,
        beats: Array,
        downbeat_hash_length := PATH_DOWNBEAT_HASH_LENGTH,
        offbeat_hash_length := PATH_OFFBEAT_HASH_LENGTH,
        downbeat_stroke_width := EDGE_TRAJECTORY_WIDTH,
        offbeat_stroke_width := EDGE_TRAJECTORY_WIDTH,
        downbeat_color := Color.white,
        offbeat_color := Color.white) -> void:
    for beat in beats:
        var hash_length: float
        var stroke_width: float
        var color: Color
        if beat.is_downbeat:
            hash_length = downbeat_hash_length
            stroke_width = downbeat_stroke_width
            color = downbeat_color
        else:
            hash_length = offbeat_hash_length
            stroke_width = offbeat_stroke_width
            color = offbeat_color
        
        var hash_half_displacement: Vector2 = \
                hash_length * beat.direction.tangent() / 2.0
        var hash_from: Vector2 = beat.position + hash_half_displacement
        var hash_to: Vector2 = beat.position - hash_half_displacement
        
        canvas.draw_line(
                hash_from,
                hash_to,
                color,
                stroke_width,
                false)


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
                edge.end_position_along_surface,
                true,
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
                true,
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
                true,
                includes_discrete_positions)
        canvas.draw_polyline(
                vertices,
                discrete_trajectory_color,
                stroke_width)
    
    if includes_waypoints:
        # Draw the intermediate waypoints.
        for i in edge.trajectory.waypoint_positions.size() - 1:
            var waypoint_position: Vector2 = \
                    edge.trajectory.waypoint_positions[i]
            draw_circle_outline(
                    canvas,
                    waypoint_position,
                    EDGE_WAYPOINT_RADIUS,
                    waypoint_color,
                    stroke_width,
                    4.0)
        
        draw_destination_marker(
                canvas,
                edge.end_position_along_surface,
                true,
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
        includes_end_points := true,
        is_continuous := true,
        removes_too_close_vertices := false) -> PoolVector2Array:
    if edge.trajectory != null:
        var vertices := \
                edge.trajectory.frame_continuous_positions_from_steps if \
                is_continuous else \
                edge.trajectory.frame_discrete_positions_from_test
        if includes_end_points:
            if vertices.empty():
                vertices.push_back(edge.get_start())
            vertices.push_back(edge.get_end())
        if removes_too_close_vertices:
            vertices = _remove_too_close_neighbors(vertices)
        return vertices
    else:
        return PoolVector2Array([
            edge.get_start(),
            edge.get_end(),
        ])


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
