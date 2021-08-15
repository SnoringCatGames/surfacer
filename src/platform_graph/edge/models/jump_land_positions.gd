class_name JumpLandPositions
extends Reference
# Potential jump position, land position, and start velocity for an edge
# calculation.


var jump_position: PositionAlongSurface
var land_position: PositionAlongSurface
var velocity_start: Vector2

# When this is true, the corresponding edge calculation will be given a higher
# jump to start with. This is used in cases when it's more likely than the edge
# calculation would eventually need to backtrack to consider a higher jump
# height anyway, so this should improve run time.
var needs_extra_jump_duration: bool

# When this is true, the corresponding edge calculation will be given a greater
# horizontal end speed. This is assigned when the land position is too close to
# the bottom of a wall, and the character is more likely to fall short of the
# bottom corner of the wall.
var needs_extra_wall_land_horizontal_speed: bool

# When this is true, it usually means that there is a more direct (i.e., less
# horizontal distance covered, or with fewer horizontal direction changes)
# jump/land pair for the same surface pair. Edge calculations are more likely
# to fail when this is true.
# 
# An important reason to still consider these pairs, is if there is actually an
# intermediate surface blocking the way of the more direct alternative, so this
# might be the only option.
var less_likely_to_be_valid: bool


func _init(
        jump_position: PositionAlongSurface = null,
        land_position: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false,
        less_likely_to_be_valid := false) -> void:
    assert(!needs_extra_wall_land_horizontal_speed or \
            land_position.side == SurfaceSide.LEFT_WALL or \
            land_position.side == SurfaceSide.RIGHT_WALL)
    
    self.jump_position = jump_position
    self.land_position = land_position
    self.velocity_start = velocity_start
    self.needs_extra_jump_duration = needs_extra_jump_duration
    self.needs_extra_wall_land_horizontal_speed = \
            needs_extra_wall_land_horizontal_speed
    self.less_likely_to_be_valid = less_likely_to_be_valid


func is_far_enough_from_others(
        movement_params: MovementParameters,
        other_jump_land_positions: Array,
        checking_distance_for_jump_positions: bool,
        checking_distance_for_land_positions: bool) -> bool:
    if other_jump_land_positions.empty():
        return true
    elif movement_params.calculates_all_valid_edges_for_a_surface_pair:
        return true
    elif movement_params \
            .stops_after_finding_first_valid_edge_for_a_surface_pair:
        return false
    
    if checking_distance_for_jump_positions:
        for other in other_jump_land_positions:
            if self.jump_position.target_point.distance_squared_to(
                    other.jump_position.target_point) < \
                    movement_params \
                            .dist_sq_thres_for_considering_additional_jump_land_points:
                # Found jump positions that are too close to each other.
                return false
    
    if checking_distance_for_land_positions:
        for other in other_jump_land_positions:
            if self.land_position.target_point.distance_squared_to(
                    other.land_position.target_point) < \
                    movement_params \
                            .dist_sq_thres_for_considering_additional_jump_land_points:
                # Found land positions that are too close to each other.
                return false
    
    return true


func to_string() -> String:
    return ("JumpLandPositions{ " +
            "jump: %s, " +
            "land: %s, " +
            "v_0: %s, " +
            "extra_duration: %s " +
            "}") % [
        jump_position.to_string(),
        land_position.to_string(),
        velocity_start,
        needs_extra_jump_duration,
    ]


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    jump_position = context.id_to_position_along_surface[int(json_object.j)]
    land_position = context.id_to_position_along_surface[int(json_object.l)]
    velocity_start = Sc.json.decode_vector2(json_object.v)
    needs_extra_jump_duration = json_object.d
    needs_extra_wall_land_horizontal_speed = json_object.s
    less_likely_to_be_valid = json_object.i


func to_json_object() -> Dictionary:
    return {
        j = jump_position.get_instance_id(),
        l = land_position.get_instance_id(),
        v = Sc.json.encode_vector2(velocity_start),
        d = needs_extra_jump_duration,
        s = needs_extra_wall_land_horizontal_speed,
        i = less_likely_to_be_valid,
    }
