tool
class_name SurfacerDrawUtils
extends ScaffolderDrawUtils


const SQRT_TWO := sqrt(2.0)


func draw_surface(
        canvas: CanvasItem,
        surface: Surface,
        color: Color,
        depth: float = Sc.annotators.params.surface_depth) -> void:
    var vertices := surface.vertices
    var vertex_count := vertices.size()
    
    assert(vertex_count > 0)
    
    if vertex_count == 1:
        # Handle the degenerate case: One point in the surface.
        draw_single_vertex_surface(
                canvas,
                surface,
                color,
                depth)
        return
    
    var preceding_vertices := surface.counter_clockwise_neighbor.vertices
    if preceding_vertices.size() <= 1:
        preceding_vertices = \
                surface.counter_clockwise_neighbor \
                .counter_clockwise_neighbor.vertices
        assert(preceding_vertices.size() > 1)
    var first_segment_preceding_point: Vector2 = \
            preceding_vertices[preceding_vertices.size() - 2]
    
    var following_vertices := surface.clockwise_neighbor.vertices
    if following_vertices.size() <= 1:
        following_vertices = \
                surface.clockwise_neighbor.clockwise_neighbor.vertices
        assert(following_vertices.size() > 1)
    var last_segment_following_point: Vector2 = following_vertices[1]
    
    if vertex_count == 2:
        # Two points in the surface.
        draw_surface_segment(
                canvas,
                vertices[0],
                vertices[1],
                first_segment_preceding_point,
                last_segment_following_point,
                surface,
                color,
                depth)
        
    else:
        # At least three points in the surface.
        
        # Draw the first segment.
        draw_surface_segment(
                canvas,
                vertices[0],
                vertices[1],
                first_segment_preceding_point,
                vertices[2],
                surface,
                color,
                depth)
        
        # Draw the middle segments.
        for i in range(1, vertex_count - 2):
            draw_surface_segment(
                    canvas,
                    vertices[i],
                    vertices[i + 1],
                    vertices[i - 1],
                    vertices[i + 2],
                    surface,
                    color,
                    depth)
        
        # Draw the last segment.
        draw_surface_segment(
                canvas,
                vertices[vertex_count - 2],
                vertices[vertex_count - 1],
                vertices[vertex_count - 3],
                last_segment_following_point,
                surface,
                color,
                depth)


func draw_surface_segment(
        canvas: CanvasItem,
        segment_start: Vector2,
        segment_end: Vector2,
        preceding_point: Vector2,
        following_point: Vector2,
        surface: Surface,
        color: Color,
        depth: float) -> void:
    # Calculate the delta for both ends of the segment between depth iterations.
    
    var displacement := segment_end - segment_start
    var segment_normal: Vector2 = \
            Sc.geometry.get_segment_normal(segment_start, segment_end)
    
    var surface_depth_division_size: float = \
            depth / Sc.annotators.params.surface_depth_divisions_count
    var segment_depth_division_offset := \
            segment_normal * -surface_depth_division_size
    var half_segment_depth_division_offset := \
            segment_depth_division_offset / 2.0
    
    var segment_direction := \
            (segment_end - segment_start).normalized()
    var preceding_segment_direction := \
            (segment_start - preceding_point).normalized()
    var following_segment_direction := \
            (following_point - segment_end).normalized()
    
    var preceding_angular_bisector_direction_non_normalized := \
            (-preceding_segment_direction + segment_direction) if \
            preceding_segment_direction != segment_direction else \
            segment_direction.tangent()
    var preceding_angular_bisector_segment_end_offset := \
            preceding_angular_bisector_direction_non_normalized * 1000
    var preceding_angular_bisector_segment_start := \
            segment_start - preceding_angular_bisector_segment_end_offset
    var preceding_angular_bisector_segment_end := \
            segment_start + preceding_angular_bisector_segment_end_offset
    
    var following_angular_bisector_direction_non_normalized := \
            (-segment_direction + following_segment_direction) if \
            segment_direction != following_segment_direction else \
            segment_direction.tangent()
    var following_angular_bisector_segment_end_offset := \
            following_angular_bisector_direction_non_normalized * 1000
    var following_angular_bisector_segment_start := \
            segment_end - following_angular_bisector_segment_end_offset
    var following_angular_bisector_segment_end := \
            segment_end + following_angular_bisector_segment_end_offset
    
    var elongated_next_depth_division_segment_start := \
            segment_start - displacement * 1000 + \
            segment_depth_division_offset
    var elongated_next_depth_division_segment_end := \
            segment_end + displacement * 1000 + \
            segment_depth_division_offset
    
    var next_depth_division_segment_start := \
            Sc.geometry.get_intersection_of_segments(
                    elongated_next_depth_division_segment_start,
                    elongated_next_depth_division_segment_end,
                    preceding_angular_bisector_segment_start,
                    preceding_angular_bisector_segment_end)
    var next_depth_division_segment_end := \
            Sc.geometry.get_intersection_of_segments(
                    elongated_next_depth_division_segment_start,
                    elongated_next_depth_division_segment_end,
                    following_angular_bisector_segment_start,
                    following_angular_bisector_segment_end)
    
    var surface_depth_division_start_delta := \
            next_depth_division_segment_start - \
            segment_start
    var surface_depth_division_end_delta := \
            next_depth_division_segment_end - \
            segment_end
    
    # ---
    
    var alpha_start := color.a
    var alpha_end: float = alpha_start * Sc.annotators.params.surface_alpha_end_ratio
    
    for i in Sc.annotators.params.surface_depth_divisions_count:
        var current_depth_segment_start: Vector2 = \
                segment_start + \
                surface_depth_division_start_delta * i
        var current_depth_segment_end: Vector2 = \
                segment_end + \
                surface_depth_division_end_delta * i
        
        var progress: float = \
                i / (Sc.annotators.params.surface_depth_divisions_count - 1.0)
        progress = Sc.utils.ease_by_name(progress, "ease_out")
        color.a = alpha_start + progress * (alpha_end - alpha_start)
        
        canvas.draw_line(
                current_depth_segment_start,
                current_depth_segment_end,
                color,
                surface_depth_division_size)


func draw_single_vertex_surface(
        canvas: CanvasItem,
        surface: Surface,
        color: Color,
        depth: float = Sc.annotators.params.surface_depth) -> void:
    var point: Vector2 = surface.vertices[0]
    
    var alpha_start: float = Sc.annotators.params.surface_alpha_end_ratio
    var alpha_delta: float = \
            (color.a - alpha_start) / \
            Sc.annotators.params.surface_depth_divisions_count
    
    var color_start := color
    color_start.a = alpha_start
    var color_overlay := color
    # TODO: This is a quick hack to make the gradient more exponential.
    color_overlay.a = alpha_delta * 0.3
    
    var radius := depth
    var delta_radius: float = \
            depth / Sc.annotators.params.surface_depth_divisions_count
    
    canvas.draw_circle(point, radius, color_start)
    
    for i in range(1, Sc.annotators.params.surface_depth_divisions_count):
        radius -= delta_radius
        canvas.draw_circle(point, radius, color_overlay)
        # TODO: This is a quick hack to make the gradient more exponential.
        color_overlay.a *= 1.8


func draw_position_along_surface(
        canvas: CanvasItem,
        position: PositionAlongSurface,
        target_point_color: Color,
        t_color: Color,
        target_point_radius := 4.0,
        t_length_in_surface := 8.0,
        t_length_out_of_surface := 8.0,
        t_width := 4.0,
        t_value_drawn := true,
        target_point_drawn := false,
        surface_drawn := false) -> void:
    # Optionally, annotate the t value.
    if t_value_drawn:
        if position.target_projection_onto_surface == Vector2.INF:
            position.target_projection_onto_surface = \
                    Sc.geometry.project_point_onto_surface(
                            position.target_point,
                            position.surface)
        var normal := position.surface.normal
        var start := position.target_projection_onto_surface + \
                normal * t_length_out_of_surface
        var end := position.target_projection_onto_surface - \
                normal * t_length_in_surface
        canvas.draw_line(
                start,
                end,
                t_color,
                t_width)
    
    # Optionally, annotate the target point.
    if target_point_drawn:
        canvas.draw_circle(
                position.target_point,
                target_point_radius,
                target_point_color)
    
    # Optionally, annotate the surface.
    if surface_drawn:
        draw_surface(
                canvas,
                position.surface,
                target_point_color)


func draw_origin_marker(
        canvas: CanvasItem,
        target: Vector2,
        color: Color,
        radius: float = Sc.annotators.params.edge_start_radius,
        border_width := 1.0,
        sector_arc_length := 3.0) -> void:
    draw_circle_outline(
            canvas,
            target,
            radius,
            color,
            border_width,
            sector_arc_length)


func draw_destination_marker(
        canvas: CanvasItem,
        destination: PositionAlongSurface,
        is_based_on_target_point: bool,
        color: Color,
        cone_length: float = Sc.annotators.params.edge_end_cone_length,
        circle_radius: float = Sc.annotators.params.edge_end_radius,
        is_filled := false,
        border_width: float = Sc.annotators.params.edge_waypoint_stroke_width,
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
        
        var cone_center_displacement: float = \
                cone_length * SQRT_TWO / 2.0 * \
                Sc.annotators.params.in_air_destination_indicator_size_ratio
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
        
        for i in Sc.annotators.params.in_air_destination_indicator_cone_count:
            var circle_offset := Vector2(0.0, -cone_center_displacement) \
                    .rotated((2.0 * PI * i) / \
                            Sc.annotators.params \
                            .in_air_destination_indicator_cone_count)
            draw_ice_cream_cone(
                    canvas,
                    cone_end_point,
                    cone_end_point + circle_offset,
                    circle_radius * \
                                Sc.annotators.params \
                                .in_air_destination_indicator_size_ratio,
                    color,
                    is_filled,
                    border_width,
                    sector_arc_length)


func draw_instruction_indicator(
        canvas: CanvasItem,
        input_key: String,
        is_pressed: bool,
        position: Vector2,
        length: float,
        color: Color) -> void:
    var half_length := length / 2.0
    var end_offset_from_mid: Vector2
    match input_key:
        "j":
            end_offset_from_mid = Vector2(0.0, -half_length)
        "ml":
            end_offset_from_mid = Vector2(-half_length, 0.0)
        "mr":
            end_offset_from_mid = Vector2(half_length, 0.0)
        _:
            Sc.logger.error("Invalid input_key: %s" % input_key)
    
    var start := position - end_offset_from_mid
    var end := position + end_offset_from_mid
    var head_length: float = \
            length * Sc.annotators.params.instruction_indicator_head_length_ratio
    var head_width: float= \
            length * Sc.annotators.params.instruction_indicator_head_width_ratio
    var strike_through_length: float= \
            INF if \
            is_pressed else \
            length * \
            Sc.annotators.params.instruction_indicator_strike_trough_length_ratio
    
    draw_strike_through_arrow(
            canvas,
            start,
            end,
            head_length,
            head_width,
            strike_through_length,
            color,
            Sc.annotators.params.instruction_indicator_stroke_width)


func draw_path(
        canvas: CanvasItem,
        path: PlatformGraphPath,
        stroke_width: float = Sc.annotators.params.edge_trajectory_width,
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
    
    if vertices.size() < 2:
        return
    
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
func draw_path_duration_segment(
        canvas: CanvasItem,
        path: PlatformGraphPath,
        segment_time_start: float,
        segment_time_end: float,
        stroke_width: float = Sc.annotators.params.edge_trajectory_width,
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
                                ScaffolderTime.PHYSICS_TIME_STEP)
                index_before_segment = \
                        min(index_before_segment, edge_vertices.size() - 1)
                time_of_index_before = \
                        edge_start_time + \
                        index_before_segment * ScaffolderTime.PHYSICS_TIME_STEP
                time_of_index_after = \
                        time_of_index_before + ScaffolderTime.PHYSICS_TIME_STEP
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
                                ScaffolderTime.PHYSICS_TIME_STEP) + 1
                index_after_segment = \
                        min(index_after_segment, edge_vertices.size() - 1)
                time_of_index_after = \
                        edge_start_time + \
                        index_after_segment * ScaffolderTime.PHYSICS_TIME_STEP
                time_of_index_before = \
                        time_of_index_after - ScaffolderTime.PHYSICS_TIME_STEP
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
            vertices = Sc.utils.sub_pool_vector2_array(
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
            vertices = Sc.utils.sub_pool_vector2_array(
                    edge_vertices,
                    index_before_segment)
            # Substitute the first vertex for a temp end point that aligns with
            # the time boundary.
            vertices[0] = first_vertex_in_segment
        elif is_end_of_segment:
            # Capture part of the edge.
            var sub_edge_vertices := Sc.utils.sub_pool_vector2_array(
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


func _trim_front_end(
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
            Sc.geometry.get_intersection_of_segment_and_circle(
                    vertices[front_index + 1],
                    vertices[front_index],
                    end_position,
                    trim_radius)
    
    vertices = Sc.utils.sub_pool_vector2_array(
            vertices,
            front_index)
    
    vertices[0] = start_replacement
    
    return vertices


func _trim_back_end(
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
            Sc.geometry.get_intersection_of_segment_and_circle(
                    vertices[back_index - 1],
                    vertices[back_index],
                    end_position,
                    trim_radius)
    
    vertices = Sc.utils.sub_pool_vector2_array(
            vertices,
            0,
            back_index + 1)
    
    vertices[vertices.size() - 1] = end_replacement
    
    return vertices


func draw_beat_hashes(
        canvas: CanvasItem,
        beats: Array,
        downbeat_hash_length: float = Sc.annotators.params.path_downbeat_hash_length,
        offbeat_hash_length: float = Sc.annotators.params.path_offbeat_hash_length,
        downbeat_stroke_width: float = Sc.annotators.params.edge_trajectory_width,
        offbeat_stroke_width: float = Sc.annotators.params.edge_trajectory_width,
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


func draw_edge(
        canvas: CanvasItem,
        edge: Edge,
        stroke_width: float = Sc.annotators.params.edge_trajectory_width,
        discrete_trajectory_color := Color.white,
        includes_waypoints := false,
        includes_instruction_indicators := false,
        includes_continuous_positions := true,
        includes_discrete_positions := false) -> void:
    if discrete_trajectory_color == Color.white:
        discrete_trajectory_color = Sc.annotators.params \
                .edge_discrete_trajectory_color_config.sample()
    
    # Set up colors.
    var continuous_trajectory_color: Color = Sc.annotators.params \
            .edge_continuous_trajectory_color_config.sample()
    continuous_trajectory_color.h = discrete_trajectory_color.h
    var waypoint_color: Color = Sc.annotators.params \
            .waypoint_color_config.sample()
    waypoint_color.h = discrete_trajectory_color.h
    var instruction_color: Color = Sc.annotators.params \
            .instruction_color_config.sample()
    instruction_color.h = discrete_trajectory_color.h
    
    if includes_continuous_positions:
        # Draw the trajectory (as calculated via continuous equations of motion
        # during step calculations).
        var vertices := _get_edge_trajectory_vertices(
                edge,
                true,
                true)
        if vertices.size() >= 2:
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
                false)
        if vertices.size() >= 2:
            canvas.draw_polyline(
                    vertices,
                    discrete_trajectory_color,
                    stroke_width)
    
    if includes_waypoints:
        # Draw the intermediate waypoints.
        var waypoint_positions := \
                edge.trajectory.waypoint_positions if \
                edge.trajectory != null else \
                []
        for i in waypoint_positions.size() - 1:
            var waypoint_position: Vector2 = waypoint_positions[i]
            draw_circle_outline(
                    canvas,
                    waypoint_position,
                    Sc.annotators.params.edge_waypoint_radius,
                    waypoint_color,
                    stroke_width,
                    4.0)
        
        draw_destination_marker(
                canvas,
                edge.end_position_along_surface,
                true,
                waypoint_color)
        
        var origin_position := \
                edge.get_start()
        draw_origin_marker(
                canvas,
                origin_position,
                waypoint_color)
    
    if includes_instruction_indicators and \
            edge.trajectory != null:
        # Draw the horizontal instruction positions.
        for instruction in edge.trajectory.horizontal_instructions:
            draw_instruction_indicator(
                    canvas,
                    instruction.input_key,
                    instruction.is_pressed,
                    instruction.position,
                    Sc.annotators.params.edge_instruction_indicator_length,
                    instruction_color)
        
        # Draw the vertical instruction end position.
        if edge.trajectory.jump_instruction_end != null:
            draw_instruction_indicator(
                    canvas,
                    "j",
                    false,
                    edge.trajectory.jump_instruction_end.position,
                    Sc.annotators.params.edge_instruction_indicator_length,
                    instruction_color)


func _get_edge_trajectory_vertices(
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


func _remove_too_close_neighbors(
        vertices: PoolVector2Array) -> PoolVector2Array:
    var result := PoolVector2Array()
    result.resize(vertices.size())
    var previous_vertex := vertices[0]
    result[0] = previous_vertex
    var result_size := 1
    
    for index in range(1, vertices.size()):
        var vertex := vertices[index]
        if vertex.distance_squared_to(previous_vertex) > \
                Sc.annotators.params \
                .adjacent_vertex_too_close_distance_squared_threshold:
            previous_vertex = vertex
            result[result_size] = previous_vertex
            result_size += 1
    
    result.resize(result_size)
    return result


func draw_tilemap_indices(
        canvas: CanvasItem,
        tile_map: TileMap,
        color: Color,
        only_renders_used_indices := false) -> void:
    var half_cell_size: Vector2 = tile_map.cell_size * 0.5
    
    var positions: Array
    if only_renders_used_indices:
        positions = tile_map.get_used_cells()
    else:
        var tilemap_used_rect: Rect2 = tile_map.get_used_rect()
        var tilemap_start_x := tilemap_used_rect.position.x
        var tilemap_start_y := tilemap_used_rect.position.y
        var tilemap_width := tilemap_used_rect.size.x
        var tilemap_height := tilemap_used_rect.size.y
        positions = []
        positions.resize(tilemap_width * tilemap_height)
        for y in tilemap_height:
            for x in tilemap_width:
                positions[y * tilemap_width + x] = \
                        Vector2(x + tilemap_start_x, y + tilemap_start_y)
    
    for position in positions:
        # Draw the grid index of the cell.
        var cell_top_left_corner: Vector2 = tile_map.map_to_world(position)
        var cell_center := cell_top_left_corner + half_cell_size
        var tilemap_index := Sc.geometry.get_tilemap_index_from_grid_coord(
                position,
                tile_map)
        # Only draw positions for every fifth index.
        if tilemap_index % 5 == 0:
            canvas.draw_string(
                    Sc.gui.fonts.main_xxs,
                    cell_center,
                    str(tilemap_index),
                    color)
        canvas.draw_circle(
                cell_center,
                1.0,
                color)


func draw_tile_grid_positions(
        canvas: CanvasItem,
        tile_map: TileMap,
        color: Color,
        only_renders_used_indices := false) -> void:
    var half_cell_size: Vector2 = tile_map.cell_size * 0.5
    
    var positions: Array
    if only_renders_used_indices:
        positions = tile_map.get_used_cells()
    else:
        var tilemap_used_rect: Rect2 = tile_map.get_used_rect()
        var tilemap_start_x := tilemap_used_rect.position.x
        var tilemap_start_y := tilemap_used_rect.position.y
        var tilemap_width := tilemap_used_rect.size.x
        var tilemap_height := tilemap_used_rect.size.y
        positions = []
        positions.resize(tilemap_width * tilemap_height)
        for y in tilemap_height:
            for x in tilemap_width:
                positions[y * tilemap_width + x] = \
                        Vector2(x + tilemap_start_x, y + tilemap_start_y)
    
    for position in positions:
        var cell_top_left_corner: Vector2 = tile_map.map_to_world(position)
        var cell_center := cell_top_left_corner + half_cell_size
        canvas.draw_circle(
                cell_center,
                1.0,
                color)
        # Only draw positions for every fourth row and column.
        if (int(position.x) % 4) == 0 and \
                (int(position.y) % 4) == 0:
            # Draw the grid index of the cell.
            canvas.draw_string(
                    Sc.gui.fonts.main_xxs,
                    cell_center,
                    str(position),
                    color)
