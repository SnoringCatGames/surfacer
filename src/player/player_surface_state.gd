class_name PlayerSurfaceState
extends Reference


var is_touching_floor := false
var is_touching_ceiling := false
var is_touching_left_wall := false
var is_touching_right_wall := false
var is_touching_wall := false
var is_touching_a_surface := false

var just_touched_floor := false
var just_stopped_touching_floor := false
var just_touched_ceiling := false
var just_stopped_touching_ceiling := false
var just_touched_wall := false
var just_stopped_touching_wall := false
var just_touched_a_surface := false
var just_stopped_touching_a_surface := false

var is_grabbing_floor := false
var is_grabbing_ceiling := false
var is_grabbing_left_wall := false
var is_grabbing_right_wall := false
var is_grabbing_wall := false
var is_grabbing_a_surface := false

var just_grabbed_floor := false
var just_grabbed_ceiling := false
var just_grabbed_left_wall := false
var just_grabbed_right_wall := false
var just_grabbed_a_surface := false

var is_facing_wall := false
var is_pressing_into_wall := false
var is_pressing_away_from_wall := false

var is_triggering_wall_grab := false
var is_triggering_fall_through := false
var is_falling_through_floors := false
var is_grabbing_walk_through_walls := false

var which_wall := SurfaceSide.NONE
var surface_type := SurfaceType.AIR

var center_position := Vector2.INF
var previous_center_position := Vector2.INF
var collision_count: int
var grab_position := Vector2.INF
var collision_tile_map_coord_result := CollisionTileMapCoordResult.new()
var grab_position_tile_map_coord := Vector2.INF
var grabbed_tile_map: SurfacesTileMap
var grabbed_tile_map_index: int
var grabbed_surface: Surface
var previous_grabbed_surface: Surface
# SurfaceSide
var grabbed_side: int
var grabbed_surface_normal := Vector2.INF
var center_position_along_surface := PositionAlongSurface.new()
var last_position_along_surface := PositionAlongSurface.new()

var velocity := Vector2.INF

var just_changed_surface := false
var just_changed_tile_map := false
var just_changed_tile_map_coord := false
var just_changed_grab_position := false
var just_entered_air := false
var just_left_air := false

var horizontal_facing_sign := -1
var horizontal_acceleration_sign := 0
var toward_wall_sign := 0


func release_wall(player) -> void:
    if !is_grabbing_wall:
        return
    
    is_grabbing_wall = false
    is_grabbing_left_wall = false
    is_grabbing_right_wall = false
    
    is_grabbing_walk_through_walls = player.actions.pressed_up
    
    if is_touching_floor:
        is_grabbing_floor = true
        just_grabbed_floor = true
        just_grabbed_a_surface = true
    else:
        is_grabbing_a_surface = false


# Updates some basic surface-related state for player's actions and environment
# of the current frame.
func update(
        player,
        preserves_just_changed_state := false) -> void:
    # Flip the horizontal direction of the animation according to which way the
    # player is facing.
    if player.actions.pressed_face_right:
        horizontal_facing_sign = 1
    elif player.actions.pressed_face_left:
        horizontal_facing_sign = -1
    elif player.actions.pressed_right:
        horizontal_facing_sign = 1
    elif player.actions.pressed_left:
        horizontal_facing_sign = -1
    
    if player.actions.pressed_right:
        horizontal_acceleration_sign = 1
    elif player.actions.pressed_left:
        horizontal_acceleration_sign = -1
    else:
        horizontal_acceleration_sign = 0
    
    var next_is_touching_floor: bool
    var next_is_touching_ceiling: bool
    var next_is_touching_wall: bool
    if player.movement_params.bypasses_runtime_physics:
        var expected_surface := \
                _get_expected_position_for_bypassing_runtime_physics(player) \
                .surface
        next_is_touching_floor = \
                expected_surface != null and \
                expected_surface.side == SurfaceSide.FLOOR
        next_is_touching_ceiling = \
                expected_surface != null and \
                expected_surface.side == SurfaceSide.CEILING
        next_is_touching_wall = \
                expected_surface != null and \
                (expected_surface.side == SurfaceSide.LEFT_WALL or \
                expected_surface.side == SurfaceSide.RIGHT_WALL)
        which_wall = \
                SurfaceSide.NONE if \
                !next_is_touching_wall else \
                expected_surface.side
    else:
        # Note: These might give false negatives when colliding with a corner.
        #       AFAICT, Godot will simply pick one of the corner's adjacent
        #       segments to base the collision normal off of, so the other
        #       segment will be ignored (and the other segment could correspond
        #       to floor or ceiling).
        next_is_touching_floor = player.is_on_floor()
        next_is_touching_ceiling = player.is_on_ceiling()
        next_is_touching_wall = player.is_on_wall()
        which_wall = Sc.geometry.get_which_wall_collided_for_body(player)
    
    is_touching_left_wall = which_wall == SurfaceSide.LEFT_WALL
    is_touching_right_wall = which_wall == SurfaceSide.RIGHT_WALL
    
    var next_is_touching_a_surface := \
            next_is_touching_floor or \
            next_is_touching_ceiling or \
            next_is_touching_wall
    
    just_touched_floor = \
            (preserves_just_changed_state and just_touched_floor) or \
            (next_is_touching_floor and !is_touching_floor)
    just_stopped_touching_floor = \
            (preserves_just_changed_state and just_stopped_touching_floor) or \
            (!next_is_touching_floor and is_touching_floor)
    
    just_touched_ceiling = \
            (preserves_just_changed_state and just_touched_ceiling) or \
            (next_is_touching_ceiling and !is_touching_ceiling)
    just_stopped_touching_ceiling = \
            (preserves_just_changed_state and \
                    just_stopped_touching_ceiling) or \
            (!next_is_touching_ceiling and is_touching_ceiling)
    
    just_touched_wall = \
            (preserves_just_changed_state and just_touched_wall) or \
            (next_is_touching_wall and !is_touching_wall)
    just_stopped_touching_wall = \
            (preserves_just_changed_state and just_stopped_touching_wall) or \
            (!next_is_touching_wall and is_touching_wall)
    
    just_touched_a_surface = \
            (preserves_just_changed_state and just_touched_a_surface) or \
            (next_is_touching_a_surface and !is_touching_a_surface)
    just_stopped_touching_a_surface = \
            (preserves_just_changed_state and \
                    just_stopped_touching_a_surface) or \
            (!next_is_touching_a_surface and is_touching_a_surface)
    
    is_touching_floor = next_is_touching_floor
    is_touching_ceiling = next_is_touching_ceiling
    is_touching_wall = next_is_touching_wall
    is_touching_a_surface = next_is_touching_a_surface
    
    # Calculate the sign of a colliding wall's direction.
    toward_wall_sign = \
            (0 if !is_touching_wall else \
            (1 if which_wall == SurfaceSide.RIGHT_WALL else \
            -1))
    
    is_facing_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    horizontal_facing_sign > 0) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    horizontal_facing_sign < 0)
    is_pressing_into_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    player.actions.pressed_right) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    player.actions.pressed_left)
    is_pressing_away_from_wall = \
            (which_wall == SurfaceSide.RIGHT_WALL and \
                    player.actions.pressed_left) or \
            (which_wall == SurfaceSide.LEFT_WALL and \
                    player.actions.pressed_right)
    
    var facing_into_wall_and_pressing_up: bool = \
            player.actions.pressed_up and \
            (is_facing_wall or is_pressing_into_wall)
    var facing_into_wall_and_pressing_grab: bool = \
            player.actions.pressed_grab_wall and \
            (is_facing_wall or is_pressing_into_wall)
    var touching_floor_and_pressing_down: bool = \
            is_touching_floor and player.actions.pressed_down
    is_triggering_wall_grab = \
            (is_pressing_into_wall or \
            facing_into_wall_and_pressing_up or \
            facing_into_wall_and_pressing_grab) and \
            !touching_floor_and_pressing_down
    
    is_triggering_fall_through = \
            player.actions.pressed_down and player.actions.just_pressed_jump
    
    # Whether we are grabbing a wall.
    is_grabbing_wall = \
            player.movement_params.can_grab_walls and (
                is_touching_wall and \
                (is_grabbing_wall or is_triggering_wall_grab) and \
                !touching_floor_and_pressing_down
            )
    
    if is_grabbing_wall:
        surface_type = SurfaceType.WALL
    elif is_grabbing_floor:
        surface_type = SurfaceType.FLOOR
    else:
        surface_type = SurfaceType.AIR
    
    # Whether we should fall through fall-through floors.
    if is_grabbing_wall:
        is_falling_through_floors = player.actions.pressed_down
    elif is_touching_floor:
        is_falling_through_floors = is_triggering_fall_through
    else:
        is_falling_through_floors = player.actions.pressed_down
    
    # Whether we should fall through fall-through floors.
    is_grabbing_walk_through_walls = \
            player.movement_params.can_grab_walls and \
                (is_grabbing_wall or player.actions.pressed_up)
    
    self.velocity = player.velocity
    
    _update_which_side_is_grabbed(player, preserves_just_changed_state)
    _update_which_surface_is_grabbed(player, preserves_just_changed_state)


func _update_which_side_is_grabbed(
        player,
        preserves_just_changed_state := false) -> void:
    var next_is_grabbing_floor := false
    var next_is_grabbing_ceiling := false
    var next_is_grabbing_left_wall := false
    var next_is_grabbing_right_wall := false
    
    if is_grabbing_wall:
        next_is_grabbing_left_wall = is_touching_left_wall
        next_is_grabbing_right_wall = is_touching_right_wall
    elif is_grabbing_ceiling:
        next_is_grabbing_ceiling = true
    elif is_touching_floor:
        next_is_grabbing_floor = true
    
    var next_is_grabbing_a_surface := \
            next_is_grabbing_floor or \
            next_is_grabbing_ceiling or \
            next_is_grabbing_left_wall or \
            next_is_grabbing_right_wall
    
    just_grabbed_floor = \
            (preserves_just_changed_state and just_grabbed_floor) or \
            (next_is_grabbing_floor and !is_grabbing_floor)
    just_grabbed_ceiling = \
            (preserves_just_changed_state and just_grabbed_ceiling) or \
            (next_is_grabbing_ceiling and !is_grabbing_ceiling)
    just_grabbed_left_wall = \
            (preserves_just_changed_state and just_grabbed_left_wall) or \
            (next_is_grabbing_left_wall and !is_grabbing_left_wall)
    just_grabbed_right_wall = \
            (preserves_just_changed_state and just_grabbed_right_wall) or \
            (next_is_grabbing_right_wall and !is_grabbing_right_wall)
    just_grabbed_a_surface = \
            just_grabbed_floor or \
            just_grabbed_ceiling or \
            just_grabbed_left_wall or \
            just_grabbed_right_wall
    
    just_entered_air = \
            (preserves_just_changed_state and just_entered_air) or \
            (!next_is_grabbing_a_surface and is_grabbing_a_surface)
    just_left_air = \
            (preserves_just_changed_state and just_left_air) or \
            (next_is_grabbing_a_surface and !is_grabbing_a_surface)
    
    is_grabbing_floor = next_is_grabbing_floor
    is_grabbing_ceiling = next_is_grabbing_ceiling
    is_grabbing_left_wall = next_is_grabbing_left_wall
    is_grabbing_right_wall = next_is_grabbing_right_wall
    is_grabbing_a_surface = next_is_grabbing_a_surface
    
    grabbed_side = \
            SurfaceSide.FLOOR if \
                    is_grabbing_floor else \
            (SurfaceSide.CEILING if \
                    is_grabbing_ceiling else \
            (SurfaceSide.LEFT_WALL if \
                    is_grabbing_left_wall else \
            (SurfaceSide.RIGHT_WALL if \
                    is_grabbing_right_wall else \
            SurfaceSide.NONE)))
    match grabbed_side:
        SurfaceSide.FLOOR:
            grabbed_surface_normal = Sc.geometry.UP
        SurfaceSide.CEILING:
            grabbed_surface_normal = Sc.geometry.DOWN
        SurfaceSide.LEFT_WALL:
            grabbed_surface_normal = Sc.geometry.RIGHT
        SurfaceSide.RIGHT_WALL:
            grabbed_surface_normal = Sc.geometry.LEFT


func _update_which_surface_is_grabbed(
        player,
        preserves_just_changed_state := false) -> void:
    if is_grabbing_a_surface:
        if player.movement_params.bypasses_runtime_physics:
            _update_grab_state_from_expected_navigation(
                    player,
                    preserves_just_changed_state)
        else:
            _update_grab_state_from_collision(
                    player,
                    preserves_just_changed_state)
        
        Sc.geometry.get_collision_tile_map_coord(
                collision_tile_map_coord_result,
                grab_position,
                grabbed_tile_map,
                is_touching_floor,
                is_touching_ceiling,
                is_touching_left_wall,
                is_touching_right_wall)
        var next_grab_position_tile_map_coord := \
                collision_tile_map_coord_result.tile_map_coord
        
        just_changed_tile_map_coord = \
                (preserves_just_changed_state and \
                        just_changed_tile_map_coord) or \
                (just_left_air or \
                        next_grab_position_tile_map_coord != \
                                grab_position_tile_map_coord)
        grab_position_tile_map_coord = next_grab_position_tile_map_coord
        
        if just_changed_tile_map_coord or just_changed_tile_map:
            grabbed_tile_map_index = \
                    Sc.geometry.get_tile_map_index_from_grid_coord(
                            grab_position_tile_map_coord,
                            grabbed_tile_map)
        
        var next_grabbed_surface: Surface = \
                player.surface_parser.get_surface_for_tile(
                        grabbed_tile_map,
                        grabbed_tile_map_index,
                        grabbed_side)
        just_changed_surface = \
                (preserves_just_changed_state and just_changed_surface) or \
                (just_left_air or next_grabbed_surface != grabbed_surface)
        if just_changed_surface:
            previous_grabbed_surface = \
                    previous_grabbed_surface if \
                    preserves_just_changed_state else \
                    grabbed_surface
        grabbed_surface = next_grabbed_surface
        
        center_position_along_surface.match_current_grab(
                grabbed_surface,
                center_position)
        
        PositionAlongSurface.copy(
                last_position_along_surface,
                center_position_along_surface)
        
    else:
        if just_entered_air:
            just_changed_grab_position = true
            just_changed_tile_map = true
            just_changed_tile_map_coord = true
            just_changed_surface = true
            previous_grabbed_surface = \
                    previous_grabbed_surface if \
                    preserves_just_changed_state else \
                    grabbed_surface
        
        grab_position = Vector2.INF
        grabbed_tile_map = null
        grab_position_tile_map_coord = Vector2.INF
        grabbed_surface = null
        center_position_along_surface.reset()


func _update_grab_state_from_expected_navigation(
        player,
        preserves_just_changed_state: bool) -> void:
    var position_along_surface := \
            _get_expected_position_for_bypassing_runtime_physics(player)
    
    var next_grab_position := \
            position_along_surface.target_projection_onto_surface
    just_changed_grab_position = \
            (preserves_just_changed_state and just_changed_grab_position) or \
            (just_left_air or next_grab_position != grab_position)
    grab_position = next_grab_position
    
    var next_grabbed_tile_map := position_along_surface.surface.tile_map
    just_changed_tile_map = \
            (preserves_just_changed_state and just_changed_tile_map) or \
            (just_left_air or next_grabbed_tile_map != grabbed_tile_map)
    grabbed_tile_map = next_grabbed_tile_map


func _get_expected_position_for_bypassing_runtime_physics(player) -> \
        PositionAlongSurface:
    return player.navigator.navigation_state \
                    .expected_position_along_surface if \
            player.navigator.is_currently_navigating else \
            player.navigator.get_previous_destination()


func _update_grab_state_from_collision(
        player,
        preserves_just_changed_state: bool) -> void:
    var collision := _get_attached_surface_collision(
            player,
            self)
    assert((collision != null) == is_grabbing_a_surface)
    
    var next_grab_position := collision.position
    just_changed_grab_position = \
            (preserves_just_changed_state and just_changed_grab_position) or \
            (just_left_air or next_grab_position != grab_position)
    grab_position = next_grab_position
    
    var next_grabbed_tile_map := collision.collider
    just_changed_tile_map = \
            (preserves_just_changed_state and just_changed_tile_map) or \
            (just_left_air or next_grabbed_tile_map != grabbed_tile_map)
    grabbed_tile_map = next_grabbed_tile_map


static func _get_attached_surface_collision(
        body: KinematicBody2D,
        surface_state: PlayerSurfaceState) -> KinematicCollision2D:
    var closest_normal_diff: float = PI
    var closest_collision: KinematicCollision2D
    for i in surface_state.collision_count:
        var current_collision := body.get_slide_collision(i)
        
        var current_normal_diff: float
        if surface_state.is_grabbing_floor:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Sc.geometry.UP))
        elif surface_state.is_grabbing_ceiling:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Sc.geometry.DOWN))
        elif surface_state.is_grabbing_left_wall:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Sc.geometry.RIGHT))
        elif surface_state.is_grabbing_right_wall:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Sc.geometry.LEFT))
        else:
            continue
        
        if current_normal_diff < closest_normal_diff:
            closest_normal_diff = current_normal_diff
            closest_collision = current_collision
    
    return closest_collision
