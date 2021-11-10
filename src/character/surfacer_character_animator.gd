tool
class_name SurfacerCharacterAnimator, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_character_animator.png"
extends ScaffolderCharacterAnimator


func sync_position_rotation_for_contact_normal(
        character_position: Vector2,
        collider: RotatedShape,
        grabbed_surface: Surface,
        grab_position: Vector2,
        grab_normal: Vector2) -> void:
    var animator_rotation := 0.0
    var animator_position := Vector2.ZERO
    
    if is_instance_valid(grabbed_surface):
        animator_rotation = grabbed_surface.normal.angle_to(grab_normal)
        
        var side_offset := \
                -grabbed_surface.normal * \
                collider.half_width_height
        var grab_offset := grab_position - character_position
        
        var grabbed_vertex_index := -1
        for i in grabbed_surface.vertices.size():
            if Sc.geometry.are_points_equal_with_epsilon(
                    grab_position,
                    grabbed_surface.vertices[i],
                    0.01):
                grabbed_vertex_index = i
                break
        var is_grabbing_vertex := grabbed_vertex_index >= 0
        
        if is_grabbing_vertex:
            var normal_before_vertex := Vector2.INF
            var normal_after_vertex := Vector2.INF
            
            if grabbed_vertex_index == 0 or \
                    grabbed_surface.is_single_vertex:
                # The preceding normal is derived from the preceding grabbed_surface.
                var previous_surface_vertices := \
                        grabbed_surface.counter_clockwise_neighbor.vertices
                if previous_surface_vertices.size() == 1:
                    normal_before_vertex = \
                            grabbed_surface.counter_clockwise_neighbor.normal
                else:
                    normal_before_vertex = Sc.geometry.get_segment_normal(
                            previous_surface_vertices[
                                    previous_surface_vertices.size() - 2],
                            previous_surface_vertices[
                                    previous_surface_vertices.size() - 1])
            else:
                normal_before_vertex = Sc.geometry.get_segment_normal(
                        grabbed_surface.vertices[grabbed_vertex_index - 1],
                        grabbed_surface.vertices[grabbed_vertex_index])
            
            if grabbed_vertex_index == grabbed_surface.vertices.size() - 1 or \
                    grabbed_surface.is_single_vertex:
                # The following normal is derived from the following surface.
                var next_surface_vertices := \
                        grabbed_surface.clockwise_neighbor.vertices
                if next_surface_vertices.size() == 1:
                    normal_after_vertex = \
                            grabbed_surface.clockwise_neighbor.normal
                else:
                    normal_after_vertex = Sc.geometry.get_segment_normal(
                            next_surface_vertices[0],
                            next_surface_vertices[1])
            else:
                normal_after_vertex = Sc.geometry.get_segment_normal(
                        grabbed_surface.vertices[grabbed_vertex_index],
                        grabbed_surface.vertices[grabbed_vertex_index + 1])
            
            var inter_segment_progress: float
            match grabbed_surface.side:
                SurfaceSide.FLOOR:
                    inter_segment_progress = \
                            (-grab_offset.x + collider.half_width_height.x) / \
                            collider.half_width_height.x / 2.0
                SurfaceSide.LEFT_WALL:
                    inter_segment_progress = \
                            (-grab_offset.y + collider.half_width_height.y) / \
                            collider.half_width_height.y / 2.0
                SurfaceSide.RIGHT_WALL:
                    inter_segment_progress = \
                            1 - \
                            (-grab_offset.y + collider.half_width_height.y) / \
                            collider.half_width_height.y / 2.0
                SurfaceSide.CEILING:
                    inter_segment_progress = \
                            1 - \
                            (-grab_offset.x + collider.half_width_height.x) / \
                            collider.half_width_height.x / 2.0
                _:
                    Sc.logger.error()
            inter_segment_progress = clamp(inter_segment_progress, 0.0, 1.0)
            
            var grab_angle: float = lerp_angle(
                    normal_before_vertex.angle(),
                    normal_after_vertex.angle(),
                    inter_segment_progress)
            animator_rotation = fposmod(
                    grab_angle - grabbed_surface.normal.angle(),
                    TAU)
            
            animator_position = grab_offset
            
        else:
            animator_position = grab_offset
        
        # Convert the rotation to be between -PI and PI.
        if animator_rotation > PI:
            animator_rotation -= TAU
        
        var grab_offset_progress: float
        match grabbed_surface.side:
            SurfaceSide.FLOOR, \
            SurfaceSide.CEILING:
                grab_offset_progress = \
                        abs(animator_rotation) / Sc.geometry.FLOOR_MAX_ANGLE
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                grab_offset_progress = \
                        abs(animator_rotation) / \
                        (PI / 2.0 - Sc.geometry.FLOOR_MAX_ANGLE)
            _:
                Sc.logger.error()
        grab_offset_progress = clamp(grab_offset_progress, 0.0, 1.0)
        
        var is_surface_horizontal := \
                grabbed_surface.side == SurfaceSide.FLOOR or \
                grabbed_surface.side == SurfaceSide.CEILING
        
        if is_surface_horizontal:
            animator_position.x = \
                    lerp(0.0, grab_offset.x, grab_offset_progress)
            animator_position.y += \
                    -tan(animator_rotation) * \
                        (grab_offset.x * (1 - grab_offset_progress))
        else:
            animator_position.y = \
                    lerp(0.0, grab_offset.y, grab_offset_progress)
            animator_position.x += \
                    -tan(animator_rotation) * \
                        (grab_offset.y * (1 - grab_offset_progress))
        
    else:
        animator_rotation = 0.0
        animator_position = Vector2.ZERO
    
    self.rotation = animator_rotation
    self.position = animator_position
