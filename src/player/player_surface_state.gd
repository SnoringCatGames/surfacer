class_name PlayerSurfaceState
extends Reference
## -   State relating to a player's position relative to nearby surfaces.[br]
## -   This is updated each physics frame.[br]


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
var did_move_last_frame := false
var collision_count: int
var grab_position := Vector2.INF
var grab_position_tile_map_coord := Vector2.INF
var grabbed_tile_map: SurfacesTileMap
var grabbed_surface: Surface
var previous_grabbed_surface: Surface
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

# Dictionary<Surface, SurfaceTouch>
var surfaces_to_touches := {}
# Dictionary<int, SurfaceTouch>
var surface_sides_to_touches := {}
var surface_grab: SurfaceTouch = null

var _collision_tile_map_coord_result := CollisionTileMapCoordResult.new()


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


# Updates surface-related state according to the player's recent movement and
# the environment of the current frame.
func update_for_movement(player) -> void:
    velocity = player.velocity
    
    previous_center_position = center_position
    center_position = player.position
    
    did_move_last_frame = previous_center_position != center_position
    
    if !player.movement_params.bypasses_runtime_physics:
        collision_count = player.get_slide_count()
    
    _update_which_sides_are_touched(player)
    _update_touched_surfaces(player)


# Updates surface-related state according to the player's current actions.
func update_for_actions(
        player,
        preserves_just_changed_state := false) -> void:
    _update_surface_actions(player, preserves_just_changed_state)
    _update_which_side_is_grabbed(player, preserves_just_changed_state)
    _update_surface_grab(player, preserves_just_changed_state)


func _update_which_sides_are_touched(player) -> void:
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
        # Note: These might give false-negatives when colliding with a corner.
        #       AFAICT, Godot will simply pick one of the corner's adjacent
        #       segments to base the collision normal off of, so the other
        #       segment will be ignored (and the other segment could correspond
        #       to floor or ceiling).
        next_is_touching_floor = false
        next_is_touching_wall = false
        next_is_touching_ceiling = false
        which_wall = SurfaceSide.NONE
        for i in collision_count:
            var collision: KinematicCollision2D = player.get_slide_collision(i)
            var side: int = \
                    Sc.geometry.get_which_surface_side_collided(collision)
            match side:
                SurfaceSide.FLOOR:
                    next_is_touching_floor = true
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    next_is_touching_wall = true
                    which_wall = side
                SurfaceSide.CEILING:
                    next_is_touching_ceiling = true
                _:
                    Sc.logger.error()
    
    is_touching_left_wall = which_wall == SurfaceSide.LEFT_WALL
    is_touching_right_wall = which_wall == SurfaceSide.RIGHT_WALL
    
    var next_is_touching_a_surface := \
            next_is_touching_floor or \
            next_is_touching_ceiling or \
            next_is_touching_wall
    
    just_touched_floor = \
            next_is_touching_floor and !is_touching_floor
    just_stopped_touching_floor = \
            !next_is_touching_floor and is_touching_floor
    
    just_touched_ceiling = \
            next_is_touching_ceiling and !is_touching_ceiling
    just_stopped_touching_ceiling = \
            !next_is_touching_ceiling and is_touching_ceiling
    
    just_touched_wall = \
            next_is_touching_wall and !is_touching_wall
    just_stopped_touching_wall = \
            !next_is_touching_wall and is_touching_wall
    
    just_touched_a_surface = \
            next_is_touching_a_surface and !is_touching_a_surface
    just_stopped_touching_a_surface = \
            !next_is_touching_a_surface and is_touching_a_surface
    
    is_touching_floor = next_is_touching_floor
    is_touching_ceiling = next_is_touching_ceiling
    is_touching_wall = next_is_touching_wall
    is_touching_a_surface = next_is_touching_a_surface
    
    # Calculate the sign of a colliding wall's direction.
    toward_wall_sign = \
            (0 if !is_touching_wall else \
            (1 if which_wall == SurfaceSide.RIGHT_WALL else \
            -1))


func _update_touched_surfaces(player) -> void:
    if player.movement_params.bypasses_runtime_physics:
        return
    
    for surface_touch in surfaces_to_touches.values():
        surface_touch._is_still_touching = false
    
    for i in collision_count:
        var collision: KinematicCollision2D = player.get_slide_collision(i)
        var touch_position := collision.position
        var touched_side: int = \
                Sc.geometry.get_which_surface_side_collided(collision)
        var touched_tile_map: SurfacesTileMap = collision.collider
        Sc.geometry.get_collision_tile_map_coord(
                _collision_tile_map_coord_result,
                touch_position,
                touched_tile_map,
                touched_side == SurfaceSide.FLOOR,
                touched_side == SurfaceSide.CEILING,
                touched_side == SurfaceSide.LEFT_WALL,
                touched_side == SurfaceSide.RIGHT_WALL)
        var touch_position_tile_map_coord := \
                _collision_tile_map_coord_result.tile_map_coord
        var touched_tile_map_index: int = \
                Sc.geometry.get_tile_map_index_from_grid_coord(
                        touch_position_tile_map_coord,
                        touched_tile_map)
        var touched_surface: Surface = \
                player.surface_parser.get_surface_for_tile(
                        touched_tile_map,
                        touched_tile_map_index,
                        touched_side)
        var just_started := !surfaces_to_touches.has(touched_surface)
        
        if just_started:
            var touch := SurfaceTouch.new()
            surfaces_to_touches[touched_surface] = touch
            assert(!surface_sides_to_touches.has(touched_side))
            surface_sides_to_touches[touched_side] = touch
        
        var surface_touch: SurfaceTouch = surfaces_to_touches[touched_surface]
        surface_touch.surface = touched_surface
        surface_touch.touch_position = touch_position
        surface_touch.tile_map_coord = touch_position_tile_map_coord
        surface_touch.tile_map_index = touched_tile_map_index
        surface_touch.position_along_surface.match_current_grab(
                touched_surface, center_position)
        surface_touch.just_started = just_started
        surface_touch._is_still_touching = true
    
    # Remove any surfaces that are no longer touching.
    for surface_touch in surfaces_to_touches.values():
        if !surface_touch._is_still_touching:
            surfaces_to_touches.erase(surface_touch.surface)
            surface_sides_to_touches.erase(surface_touch.surface.side)


func _update_surface_actions(
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


func _update_surface_grab(
        player,
        preserves_just_changed_state: bool) -> void:
    var previous_surface_grab := surface_grab
    var previous_grab_position := grab_position
    var previous_grabbed_tile_map := grabbed_tile_map
    var previous_grab_position_tile_map_coord := grab_position_tile_map_coord
    
    if is_grabbing_a_surface and \
            player.movement_params.bypasses_runtime_physics:
        # Populate surfaces_to_touches with a touch that matches expected
        # navigation state.
        _update_surface_touch_from_expected_navigation(
                player,
                preserves_just_changed_state)
    
    surface_grab = null
    
    if is_grabbing_a_surface:
        for surface in surfaces_to_touches:
            if surface.side == SurfaceSide.FLOOR and \
                            is_grabbing_floor or \
                    surface.side == SurfaceSide.LEFT_WALL and \
                            is_grabbing_left_wall or \
                    surface.side == SurfaceSide.RIGHT_WALL and \
                            is_grabbing_right_wall or \
                    surface.side == SurfaceSide.CEILING and \
                            is_grabbing_ceiling:
                surface_grab = surfaces_to_touches[surface]
                break
        assert(surface_grab != null)
        
        grab_position = surface_grab.touch_position
        grabbed_tile_map = surface_grab.surface.tile_map
        grab_position_tile_map_coord = surface_grab.tile_map_coord
        grabbed_surface = surface_grab.surface
        PositionAlongSurface.copy(
                center_position_along_surface,
                surface_grab.position_along_surface)
        PositionAlongSurface.copy(
                last_position_along_surface,
                center_position_along_surface)
        
        just_changed_grab_position = \
                (preserves_just_changed_state and \
                        just_changed_grab_position) or \
                (just_left_air or grab_position != previous_grab_position)
        
        just_changed_tile_map = \
                (preserves_just_changed_state and just_changed_tile_map) or \
                (just_left_air or \
                        grabbed_tile_map != previous_grabbed_tile_map)
        
        just_changed_tile_map_coord = \
                (preserves_just_changed_state and \
                        just_changed_tile_map_coord) or \
                (just_left_air or \
                        grab_position_tile_map_coord != \
                        previous_grab_position_tile_map_coord)
        
        just_changed_surface = \
                (preserves_just_changed_state and just_changed_surface) or \
                (just_left_air or \
                        surface_grab.surface != previous_surface_grab.surface)
        if just_changed_surface:
            previous_grabbed_surface = \
                    previous_grabbed_surface if \
                    preserves_just_changed_state else \
                    grabbed_surface
        
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


func _update_surface_touch_from_expected_navigation(
        player,
        preserves_just_changed_state: bool) -> void:
    var position_along_surface := \
            _get_expected_position_for_bypassing_runtime_physics(player)
    var touch_position := position_along_surface.target_projection_onto_surface
    var surface := position_along_surface.surface
    var tile_map := surface.tile_map
    Sc.geometry.get_collision_tile_map_coord(
            _collision_tile_map_coord_result,
            touch_position,
            tile_map,
            is_touching_floor,
            is_touching_ceiling,
            is_touching_left_wall,
            is_touching_right_wall)
    var tile_map_coord := _collision_tile_map_coord_result.tile_map_coord
    var tile_map_index: int = Sc.geometry.get_tile_map_index_from_grid_coord(
            grab_position_tile_map_coord,
            grabbed_tile_map)
    var just_started := \
            !is_instance_valid(surface_grab) or \
            surface_grab.surface != surface
    
    # Don't create a new instance each frame if we can re-use the old one.
    var surface_touch := \
            surface_grab if \
            is_instance_valid(surface_grab) else \
            SurfaceTouch.new()
    surface_touch.surface = surface
    surface_touch.touch_position = touch_position
    surface_touch.tile_map_coord = tile_map_coord
    surface_touch.tile_map_index = tile_map_index
    surface_touch.position_along_surface = position_along_surface
    surface_touch.just_started = just_started
    surface_touch._is_still_touching = true
    
    if just_started:
        surfaces_to_touches.clear()
        surfaces_to_touches[surface_touch.surface] = surface_touch
        surface_sides_to_touches.clear()
        surface_sides_to_touches[surface_touch.surface.side] = surface_touch


func _get_expected_position_for_bypassing_runtime_physics(player) -> \
        PositionAlongSurface:
    return player.navigator.navigation_state \
                    .expected_position_along_surface if \
            player.navigator.is_currently_navigating else \
            player.navigator.get_previous_destination()
