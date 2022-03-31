class_name CharacterSurfaceState
extends Reference
## -   State relating to a character's position relative to nearby surfaces.[br]
## -   This is updated each physics frame.[br]


var is_touching_floor := false
var is_touching_ceiling := false
var is_touching_left_wall := false
var is_touching_right_wall := false
var is_touching_surface: bool setget ,_get_is_touching_surface
var is_touching_wall: bool setget ,_get_is_touching_wall

var is_grabbing_floor := false
var is_grabbing_ceiling := false
var is_grabbing_left_wall := false
var is_grabbing_right_wall := false
var is_grabbing_surface: bool setget ,_get_is_grabbing_surface
var is_grabbing_wall: bool setget ,_get_is_grabbing_wall

var just_touched_floor := false
var just_touched_ceiling := false
var just_touched_left_wall := false
var just_touched_right_wall := false
var just_touched_surface: bool setget ,_get_just_touched_surface
var just_touched_wall: bool setget ,_get_just_touched_wall

var just_stopped_touching_floor := false
var just_stopped_touching_ceiling := false
var just_stopped_touching_left_wall := false
var just_stopped_touching_right_wall := false
var just_stopped_touching_surface: bool \
        setget ,_get_just_stopped_touching_surface
var just_stopped_touching_wall: bool setget ,_get_just_stopped_touching_wall

var just_grabbed_floor := false
var just_grabbed_ceiling := false
var just_grabbed_left_wall := false
var just_grabbed_right_wall := false
var just_grabbed_surface: bool setget ,_get_just_grabbed_surface
var just_grabbed_wall: bool setget ,_get_just_grabbed_wall

var just_stopped_grabbing_floor := false
var just_stopped_grabbing_ceiling := false
var just_stopped_grabbing_left_wall := false
var just_stopped_grabbing_right_wall := false
var just_stopped_grabbing_surface: bool \
        setget ,_get_just_stopped_grabbing_surface
var just_stopped_grabbing_wall: bool setget ,_get_just_stopped_grabbing_wall

var is_facing_wall := false
var is_pressing_into_wall := false
var is_pressing_away_from_wall := false

var is_triggering_explicit_wall_grab := false
var is_triggering_explicit_ceiling_grab := false
var is_triggering_explicit_floor_grab := false

var is_triggering_implicit_wall_grab := false
var is_triggering_implicit_ceiling_grab := false
var is_triggering_implicit_floor_grab := false

var is_triggering_wall_release := false
var is_triggering_ceiling_release := false
var is_triggering_fall_through := false
var is_triggering_jump := false

var is_still_triggering_previous_surface_grab_since_rounding_corner := false

var is_rounding_floor_corner_to_lower_wall := false
var is_rounding_ceiling_corner_to_upper_wall := false
var is_rounding_wall_corner_to_lower_ceiling := false
var is_rounding_wall_corner_to_upper_floor := false
var is_rounding_corner := false
var is_rounding_corner_from_previous_surface := false
var is_rounding_left_corner := false

var just_started_rounding_corner := false
var just_stopped_rounding_corner := false
var just_changed_to_lower_wall_while_rounding_floor_corner := false
var just_changed_to_upper_wall_while_rounding_ceiling_corner := false
var just_changed_to_lower_ceiling_while_rounding_wall_corner := false
var just_changed_to_upper_floor_while_rounding_wall_corner := false
var just_changed_surface_while_rounding_corner := false

var is_descending_through_floors := false
# FIXME: -------------------------------
# - Add support for grabbing jump-through ceilings.
#   - Not via a directional key.
#   - Make this configurable for climb_adjacent_surfaces behavior.
#     - Add a property that indicates probability of climbing through instead
#       of onto.
#     - Use the same probability for fall-through-floor.
# TODO:
# - Create support for a ceiling_jump_up_action.gd?
#   - Might need a new surface state property called
#     is_triggering_jump_up_through, which would be similar to
#     is_triggering_fall_through.
# - Also create support for transitioning from standing-on-fall-through-floor
#   to clinging-to-it-from-underneath and vice versa?
#   - This might require adding support for the concept of a multi-frame
#     action?
#   - And this might require adding new Edge sub-classes for either direction?
var is_ascending_through_ceilings := false
var is_grabbing_walk_through_walls := false

var surface_type := SurfaceType.AIR

var center_position := Vector2.INF
var previous_center_position := Vector2.INF
var rounding_corner_position := Vector2.INF
var did_move_last_frame := false
var did_move_frame_before_last := false
var grab_position := Vector2.INF
var grab_normal := Vector2.INF
var previous_grab_position := Vector2.INF
var previous_grab_normal := Vector2.INF
var grab_position_tilemap_coord := Vector2.INF
var grabbed_tilemap: TileMap
var grabbed_surface: Surface
var previous_grabbed_surface: Surface
var center_position_along_surface := PositionAlongSurface.new()
var last_position_along_surface := PositionAlongSurface.new()

var velocity := Vector2.ZERO

var just_changed_surface := false
var just_changed_tilemap := false
var just_changed_tilemap_coord := false
var just_changed_grab_position := false
var just_entered_air := false
var just_left_air := false

var horizontal_facing_sign := -1
var horizontal_acceleration_sign := 0
var toward_wall_sign := 0

# Dictionary<Surface, SurfaceContact>
var surfaces_to_contacts := {}
var surface_grab: SurfaceContact = null
var floor_contact: SurfaceContact
var ceiling_contact: SurfaceContact
var left_wall_contact: SurfaceContact
var right_wall_contact: SurfaceContact

var contact_count: int setget ,_get_contact_count

var character: ScaffolderCharacter

var _collision_surface_result := CollisionSurfaceResult.new()


func _init(character: ScaffolderCharacter) -> void:
    self.character = character


# Updates surface-related state according to the character's recent movement
# and the environment of the current frame.
func update() -> void:
    velocity = character.velocity
    previous_center_position = center_position
    center_position = character.position
    did_move_frame_before_last = did_move_last_frame
    did_move_last_frame = !Sc.geometry.are_points_equal_with_epsilon(
            previous_center_position, center_position, 0.00001)
    
    _update_contacts()
    _update_touch_state()
    _update_action_state()


func clear_just_changed_state() -> void:
    just_touched_floor = false
    just_touched_ceiling = false
    just_touched_left_wall = false
    just_touched_right_wall = false
    
    just_stopped_touching_floor = false
    just_stopped_touching_ceiling = false
    just_stopped_touching_left_wall = false
    just_stopped_touching_right_wall = false
    
    just_grabbed_floor = false
    just_grabbed_ceiling = false
    just_grabbed_left_wall = false
    just_grabbed_right_wall = false
    
    just_stopped_grabbing_floor = false
    just_stopped_grabbing_ceiling = false
    just_stopped_grabbing_left_wall = false
    just_stopped_grabbing_right_wall = false
    
    just_entered_air = false
    just_left_air = false
    
    just_changed_surface = false
    just_changed_tilemap = false
    just_changed_tilemap_coord = false
    just_changed_grab_position = false


func update_for_initial_surface_attachment(
        start_attachment_surface_side_or_position) -> void:
    assert(start_attachment_surface_side_or_position is Surface or \
            start_attachment_surface_side_or_position is \
                    PositionAlongSurface and \
                start_attachment_surface_side_or_position.surface != \
                    null or \
            start_attachment_surface_side_or_position is int and \
                start_attachment_surface_side_or_position != \
                    SurfaceSide.NONE,
            "SurfacerCharacter._start_attachment_surface_side_or_position " +
            "must be defined before adding the character to the scene tree.")
    
    var side: int = \
            start_attachment_surface_side_or_position if \
            start_attachment_surface_side_or_position is int else \
            start_attachment_surface_side_or_position.side if \
            start_attachment_surface_side_or_position is Surface else \
            start_attachment_surface_side_or_position.surface.side
    
    match side:
        SurfaceSide.FLOOR:
            assert(character.movement_params.can_grab_floors)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            assert(character.movement_params.can_grab_walls)
        SurfaceSide.CEILING:
            assert(character.movement_params.can_grab_ceilings)
        _:
            Sc.logger.error("CharacterSurfaceState.update_for_initial_surface_attachment")
    
    var start_position: Vector2 = character.position
    var normal := SurfaceSide.get_normal(side)
    
    var surface: Surface = \
            start_attachment_surface_side_or_position if \
            start_attachment_surface_side_or_position is Surface else \
            start_attachment_surface_side_or_position.surface if \
            start_attachment_surface_side_or_position is \
                PositionAlongSurface else \
            SurfaceFinder.find_closest_surface_in_direction(
                character.surface_store,
                start_position,
                -normal,
                _collision_surface_result)
    assert(is_instance_valid(surface),
            "start_attachment_surface_side_or_position is invalid")
    
    if start_attachment_surface_side_or_position is PositionAlongSurface:
        PositionAlongSurface.copy(
                center_position_along_surface,
                start_attachment_surface_side_or_position)
    else:
        center_position_along_surface.match_surface_target_and_collider(
                surface,
                start_position,
                character.collider,
                true,
                true,
                true)
        assert(center_position_along_surface.is_valid,
                "start_attachment_surface_side_or_position is invalid")
    
    _update_surface_contact_for_explicit_grab(
            center_position_along_surface,
            SurfaceContact.INITIAL_ATTACHMENT)
    _update_touch_state()
    
    match side:
        SurfaceSide.FLOOR:
            is_grabbing_floor = true
        SurfaceSide.LEFT_WALL:
            is_grabbing_left_wall = true
        SurfaceSide.RIGHT_WALL:
            is_grabbing_right_wall = true
        SurfaceSide.CEILING:
            is_grabbing_ceiling = true
        _:
            Sc.logger.error("CharacterSurfaceState.update_for_initial_surface_attachment")
    
    _update_action_state()
    assert(is_instance_valid(grabbed_surface),
            "start_attachment_surface_side_or_position is invalid")
    
    PositionAlongSurface.copy(
            last_position_along_surface,
            center_position_along_surface)
    previous_grabbed_surface = grabbed_surface
    previous_grab_position = grab_position
    previous_grab_normal = grab_normal
    
    center_position = center_position_along_surface.target_point
    previous_center_position = center_position
    
    character.position = center_position
    character.start_position = center_position
    character.start_surface = surface
    character.start_position_along_surface = \
            PositionAlongSurface.new(center_position_along_surface)
    character._update_reachable_surfaces(surface)


func _update_contacts() -> void:
    floor_contact = null
    left_wall_contact = null
    right_wall_contact = null
    ceiling_contact = null
    
    for surface_contact in surfaces_to_contacts.values():
        surface_contact._is_still_touching = false
    
    if character.movement_params.bypasses_runtime_physics:
        _update_surface_contact_from_expected_navigation()
        
    else:
        _update_physics_contacts()
        
        if is_rounding_corner:
            var is_rounding_successful := \
                    _update_surface_contact_from_rounded_corner()
            if !is_rounding_successful:
                _cancel_rounding_corner()
    
    # Remove any surfaces that are no longer touching.
    var contacts_to_remove := []
    for contact in surfaces_to_contacts.values():
        if !contact._is_still_touching:
            contacts_to_remove.push_back(contact)
    for contact in contacts_to_remove:
        surfaces_to_contacts.erase(contact.surface)
        if surface_grab == contact:
            surface_grab = null
        var details := (
                    "%s; " +
                    "v=%s; " +
                    "is_rounding_corner=%s"
                ) % [
                    contact.position_along_surface.to_string(
                            false, true),
                    Sc.utils.get_vector_string(velocity, 1),
                    is_rounding_corner,
                ]
        character._log(
                "Rem contact",
                details,
                CharacterLogType.SURFACE,
                true)
    
    # FIXME: ---- REMOVE? Does this ever trigger? Even if it did, we
    #             probably want to just ignore the collision this frame.
    if !character.movement_params.bypasses_runtime_physics and \
            !character.collisions.empty() and \
            surfaces_to_contacts.empty():
        var collisions_str := ""
        for collision in character.collisions:
            collisions_str += \
                    "{p=%s, n=%s}, " % \
                    [collision.position, collision.normal]
        Sc.logger.error(
                "There are only invalid collisions: %s" % collisions_str)


func _update_touch_state() -> void:
    var next_is_touching_floor := false
    var next_is_touching_ceiling := false
    var next_is_touching_left_wall := false
    var next_is_touching_right_wall := false
    
    for contact in surfaces_to_contacts.values():
        match contact.surface.side:
            SurfaceSide.FLOOR:
                next_is_touching_floor = true
            SurfaceSide.LEFT_WALL:
                next_is_touching_left_wall = true
            SurfaceSide.RIGHT_WALL:
                next_is_touching_right_wall = true
            SurfaceSide.CEILING:
                next_is_touching_ceiling = true
            _:
                Sc.logger.error("CharacterSurfaceState._update_touch_state")
    
    var next_just_touched_floor := \
            next_is_touching_floor and !is_touching_floor
    var next_just_stopped_touching_floor := \
            !next_is_touching_floor and is_touching_floor
    
    var next_just_touched_ceiling := \
            next_is_touching_ceiling and !is_touching_ceiling
    var next_just_stopped_touching_ceiling := \
            !next_is_touching_ceiling and is_touching_ceiling
    
    var next_just_touched_left_wall := \
            next_is_touching_left_wall and !is_touching_left_wall
    var next_just_stopped_touching_left_wall := \
            !next_is_touching_left_wall and is_touching_left_wall
    
    var next_just_touched_right_wall := \
            next_is_touching_right_wall and !is_touching_right_wall
    var next_just_stopped_touching_right_wall := \
            !next_is_touching_right_wall and is_touching_right_wall
    
    is_touching_floor = next_is_touching_floor
    is_touching_ceiling = next_is_touching_ceiling
    is_touching_left_wall = next_is_touching_left_wall
    is_touching_right_wall = next_is_touching_right_wall
    
    just_touched_floor = \
            next_just_touched_floor or \
            just_touched_floor and !next_just_stopped_touching_floor
    just_stopped_touching_floor = \
            next_just_stopped_touching_floor or \
            just_stopped_touching_floor and !next_just_touched_floor
    
    just_touched_ceiling = \
            next_just_touched_ceiling or \
            just_touched_ceiling and !next_just_stopped_touching_ceiling
    just_stopped_touching_ceiling = \
            next_just_stopped_touching_ceiling or \
            just_stopped_touching_ceiling and !next_just_touched_ceiling
    
    just_touched_left_wall = \
            next_just_touched_left_wall or \
            just_touched_left_wall and !next_just_stopped_touching_left_wall
    just_stopped_touching_left_wall = \
            next_just_stopped_touching_left_wall or \
            just_stopped_touching_left_wall and !next_just_touched_left_wall
    
    just_touched_right_wall = \
            next_just_touched_right_wall or \
            just_touched_right_wall and !next_just_stopped_touching_right_wall
    just_stopped_touching_right_wall = \
            next_just_stopped_touching_right_wall or \
            just_stopped_touching_right_wall and !next_just_touched_right_wall
    
    # Calculate the sign of a colliding wall's direction.
    toward_wall_sign = \
            (-1 if is_touching_left_wall else \
            (1 if is_touching_right_wall else \
            0))


func _update_physics_contacts() -> void:
    var was_a_valid_contact_found := false
    
    for collision in character.collisions:
        var surface_contact := \
                _calculate_surface_contact_from_collision(collision)
        
        if !is_instance_valid(surface_contact):
            continue
        
        was_a_valid_contact_found = true
        
        match surface_contact.surface.side:
            SurfaceSide.FLOOR:
                floor_contact = surface_contact
            SurfaceSide.LEFT_WALL:
                left_wall_contact = surface_contact
            SurfaceSide.RIGHT_WALL:
                right_wall_contact = surface_contact
            SurfaceSide.CEILING:
                ceiling_contact = surface_contact
            _:
                Sc.logger.error("CharacterSurfaceState._update_physics_contacts")


func _calculate_surface_contact_from_collision(
        collision: KinematicCollision2DCopy) -> SurfaceContact:
    var contact_position := collision.position
    var collision_normal := collision.normal
    var contacted_tilemap: TileMap = collision.collider
    
    SurfaceFinder.calculate_collision_surface(
            _collision_surface_result,
            character.surface_store,
            contact_position,
            collision_normal,
            contacted_tilemap,
            true,
            true)
    
    var contacted_surface := _collision_surface_result.surface
    var contact_tilemap_coord := _collision_surface_result.tilemap_coord
    var contact_tilemap_index := _collision_surface_result.tilemap_index
    
    if !is_instance_valid(contacted_surface):
        # -  Godot's collision engine has generated an invalid collision value.
        #    -   This might be a false-positive with an interior surface.
        #    -   This might be a reasonable collision, but with an innaccurate
        #        normal.
        # -  This is uncommon.
        return null
    
    # If both the surface and its collinear neighbor are axially-aligned,
    # and the character center is closer to the collinear neighbor,
    # then use the neighbor instead.
    var nudged_surface := _get_closer_collinear_axially_aligned_surface(
            contacted_surface,
            center_position)
    if nudged_surface != contacted_surface:
        contacted_surface = nudged_surface
    
    # Modify the contact position to be closer to the character center if the
    # contact is on axially-aligned segments of both the surface and the
    # character-collider boundary.
    var centered_contact_position: Vector2 = Sc.geometry \
            .nudge_point_along_axially_aligned_segment_toward_shape_center(
                contact_position,
                contacted_surface,
                center_position)
    if centered_contact_position != contact_position:
        contact_position = centered_contact_position
        contact_tilemap_coord = Sc.geometry.world_to_tilemap(
                contact_position,
                contacted_tilemap)
        contact_tilemap_index = Sc.geometry.get_tilemap_index_from_grid_coord(
                contact_tilemap_coord,
                contacted_tilemap)
    
    var contact_normal: Vector2 = Sc.geometry.get_surface_normal_at_point(
            contacted_surface, contact_position)
    
    var just_started := !surfaces_to_contacts.has(contacted_surface)
    
    if just_started:
        surfaces_to_contacts[contacted_surface] = SurfaceContact.new()
    
    var surface_contact: SurfaceContact = \
            surfaces_to_contacts[contacted_surface]
    surface_contact.type = SurfaceContact.PHYSICS
    surface_contact.surface = contacted_surface
    surface_contact.contact_position = contact_position
    surface_contact.contact_normal = contact_normal
    surface_contact.tilemap_coord = contact_tilemap_coord
    surface_contact.tilemap_index = contact_tilemap_index
    surface_contact.position_along_surface.match_current_grab(
            contacted_surface, center_position)
    surface_contact.just_started = just_started
    surface_contact._is_still_touching = true
    
    if just_started:
        var details := (
                    "%s; " +
                    "v=%s; " +
                    "_calculate_surface_contact_from_collision()"
                ) % [
                    surface_contact.position_along_surface.to_string(
                            false, true),
                    Sc.utils.get_vector_string(velocity, 1),
                ]
        character._log(
                "Add contact",
                details,
                CharacterLogType.SURFACE,
                true)
    
    return surface_contact


func _get_closer_collinear_axially_aligned_surface(
        surface: Surface,
        point: Vector2) -> Surface:
    if surface.is_single_vertex:
        return surface
    
    match surface.side:
        SurfaceSide.FLOOR:
            var neighbor := surface.counter_clockwise_collinear_neighbor
            while neighbor != null and \
                    point.x < surface.first_point.x and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.counter_clockwise_collinear_neighbor
            
            neighbor = surface.clockwise_collinear_neighbor
            while neighbor != null and \
                    point.x > surface.last_point.x and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.clockwise_collinear_neighbor
            
        SurfaceSide.LEFT_WALL:
            var neighbor := surface.counter_clockwise_collinear_neighbor
            while neighbor != null and \
                    point.y < surface.first_point.y and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.counter_clockwise_collinear_neighbor
            
            neighbor = surface.clockwise_collinear_neighbor
            while neighbor != null and \
                    point.y > surface.last_point.y and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.clockwise_collinear_neighbor
            
        SurfaceSide.RIGHT_WALL:
            var neighbor := surface.counter_clockwise_collinear_neighbor
            while neighbor != null and \
                    point.y > surface.first_point.y and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.counter_clockwise_collinear_neighbor
            
            neighbor = surface.clockwise_collinear_neighbor
            while neighbor != null and \
                    point.y < surface.last_point.y and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.clockwise_collinear_neighbor
            
        SurfaceSide.CEILING:
            var neighbor := surface.counter_clockwise_collinear_neighbor
            while neighbor != null and \
                    point.x > surface.first_point.x and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.counter_clockwise_collinear_neighbor
            
            neighbor = surface.clockwise_collinear_neighbor
            while neighbor != null and \
                    point.x < surface.last_point.x and \
                    surface.is_axially_aligned and \
                    neighbor.is_axially_aligned:
                surface = neighbor
                neighbor = surface.clockwise_collinear_neighbor
            
        _:
            Sc.logger.error("CharacterSurfaceState._get_closer_collinear_axially_aligned_surface")
    
    return surface


func _update_surface_contact_from_rounded_corner() -> bool:
    var previous_grab_contact := _get_grab_contact()
    if is_instance_valid(previous_grab_contact):
        # If we are still tracking a valid contact for whichever surface we
        # think should match the current rounding-corner state, then let's just
        # keep that contact and mark it as still valid.
        previous_grab_contact._is_still_touching = true
        return true
    
    var position_along_surface := \
            _get_position_along_surface_from_rounded_corner()
    if !is_instance_valid(position_along_surface):
        return false
    _update_surface_contact_for_explicit_grab(
            position_along_surface,
            SurfaceContact.MATCH_ROUNDING_CORNER)
    return true


func _update_surface_contact_from_expected_navigation() -> void:
    var position_along_surface := \
            _get_expected_position_for_bypassing_runtime_physics()
    _update_surface_contact_for_explicit_grab(
            position_along_surface,
            SurfaceContact.MATCH_TRAJECTORY)


func _get_position_along_surface_from_rounded_corner() -> PositionAlongSurface:
    var surface: Surface
    var corner_position: Vector2
    
    if is_rounding_floor_corner_to_lower_wall:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.FLOOR:
                if center_position.x <= grabbed_surface.center.x:
                    surface = grabbed_surface.counter_clockwise_convex_neighbor
                else:
                    surface = grabbed_surface.clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            if surface.side != SurfaceSide.LEFT_WALL and \
                    surface.side != SurfaceSide.RIGHT_WALL:
                # We collided with another surface while rounding the corner.
                return null
            
            if surface.side == SurfaceSide.LEFT_WALL:
                corner_position = surface.first_point
            else:
                corner_position = surface.last_point
        else:
            surface = grabbed_surface
            if surface.side != SurfaceSide.FLOOR:
                # We collided with another surface while rounding the corner.
                return null
            
            if center_position.x < surface.center.x:
                corner_position = surface.first_point
            else:
                corner_position = surface.last_point
        
    elif is_rounding_ceiling_corner_to_upper_wall:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.CEILING:
                if center_position.x <= grabbed_surface.center.x:
                    surface = grabbed_surface.clockwise_convex_neighbor
                else:
                    surface = grabbed_surface.counter_clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            if surface.side != SurfaceSide.LEFT_WALL and \
                    surface.side != SurfaceSide.RIGHT_WALL:
                # We collided with another surface while rounding the corner.
                return null
            
            if surface.side == SurfaceSide.LEFT_WALL:
                corner_position = surface.last_point
            else:
                corner_position = surface.first_point
        else:
            surface = grabbed_surface
            if surface.side != SurfaceSide.CEILING:
                # We collided with another surface while rounding the corner.
                return null
            
            if center_position.x < surface.center.x:
                corner_position = surface.last_point
            else:
                corner_position = surface.first_point
        
    elif is_rounding_wall_corner_to_lower_ceiling:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                surface = grabbed_surface.clockwise_convex_neighbor
            elif grabbed_surface.side == SurfaceSide.RIGHT_WALL:
                surface = grabbed_surface.counter_clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            if surface.side != SurfaceSide.CEILING:
                # We collided with another surface while rounding the corner.
                return null
            
            if center_position.x < surface.center.x:
                corner_position = surface.last_point
            else:
                corner_position = surface.first_point
        else:
            surface = grabbed_surface
            if surface.side != SurfaceSide.LEFT_WALL and \
                    surface.side != SurfaceSide.RIGHT_WALL:
                # We collided with another surface while rounding the corner.
                return null
            
            if surface.side == SurfaceSide.LEFT_WALL:
                corner_position = surface.last_point
            else:
                corner_position = surface.first_point
        
    elif is_rounding_wall_corner_to_upper_floor:
        if just_changed_surface_while_rounding_corner:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                surface = grabbed_surface.counter_clockwise_convex_neighbor
            elif grabbed_surface.side == SurfaceSide.RIGHT_WALL:
                surface = grabbed_surface.clockwise_convex_neighbor
            else:
                surface = grabbed_surface
            if surface.side != SurfaceSide.FLOOR:
                # We collided with another surface while rounding the corner.
                return null
            
            if center_position.x < surface.center.x:
                corner_position = surface.first_point
            else:
                corner_position = surface.last_point
        else:
            surface = grabbed_surface
            if surface.side != SurfaceSide.LEFT_WALL and \
                    surface.side != SurfaceSide.RIGHT_WALL:
                # We collided with another surface while rounding the corner.
                return null
            
            if surface.side == SurfaceSide.LEFT_WALL:
                corner_position = surface.first_point
            else:
                corner_position = surface.last_point
        
    else:
        Sc.logger.error("CharacterSurfaceState._get_position_along_surface_from_rounded_corner")
        return null
    
    return PositionAlongSurfaceFactory.create_position_offset_from_target_point(
            corner_position,
            surface,
            character.collider,
            true,
            false)


func _cancel_rounding_corner() -> void:
    var details := (
                "Unexpected collision while rounding corner; " +
                "surface=%s; " +
                "f_to_low_w=%s; " +
                "c_to_up_w=%s; " +
                "w_to_low_c=%s; " +
                "w_to_u_f=%s"
            ) % [
                grabbed_surface.to_string(false),
                is_rounding_floor_corner_to_lower_wall,
                is_rounding_ceiling_corner_to_upper_wall,
                is_rounding_wall_corner_to_lower_ceiling,
                is_rounding_wall_corner_to_upper_floor,
            ]
    character._log(
            "Corner coll",
            details,
            CharacterLogType.SURFACE,
            true)
    
    is_rounding_floor_corner_to_lower_wall = false
    just_changed_to_lower_wall_while_rounding_floor_corner = false
    is_rounding_ceiling_corner_to_upper_wall = false
    just_changed_to_upper_wall_while_rounding_ceiling_corner = false
    is_rounding_wall_corner_to_lower_ceiling = false
    just_changed_to_lower_ceiling_while_rounding_wall_corner = false
    is_rounding_wall_corner_to_upper_floor = false
    just_changed_to_upper_floor_while_rounding_wall_corner = false
    just_started_rounding_corner = false
    just_stopped_rounding_corner = false
    is_rounding_corner = false
    just_changed_surface_while_rounding_corner = false
    is_rounding_corner_from_previous_surface = false
    is_rounding_left_corner = false


func _get_expected_position_for_bypassing_runtime_physics() -> \
        PositionAlongSurface:
    return character.navigation_state.expected_position_along_surface if \
            character.navigation_state.is_currently_navigating else \
            character.navigator.get_previous_destination()


func _update_surface_contact_for_explicit_grab(
        position_along_surface: PositionAlongSurface,
        contact_type: int) -> void:
    var surface := position_along_surface.surface
    var side := surface.side
    var contact_position := \
            position_along_surface.target_projection_onto_surface
    var tile_map := surface.tile_map
    
    SurfaceFinder.calculate_collision_surface(
            _collision_surface_result,
            character.surface_store,
            contact_position,
            side,
            tile_map,
            false,
            false)
    
    assert(_collision_surface_result.surface == surface)
    var tilemap_coord := _collision_surface_result.tilemap_coord
    var tilemap_index := _collision_surface_result.tilemap_index
    var contact_normal: Vector2 = Sc.geometry.get_surface_normal_at_point(
            surface, contact_position)
    
    var just_started := !surfaces_to_contacts.has(surface)
    
    # Don't create a new instance each frame if we can re-use the old one.
    var surface_contact: SurfaceContact = \
            surfaces_to_contacts[surface] if \
            surfaces_to_contacts.has(surface) else \
            SurfaceContact.new()
    PositionAlongSurface.copy(
            surface_contact.position_along_surface,
            position_along_surface)
    surface_contact.type = contact_type
    surface_contact.surface = surface
    surface_contact.contact_position = contact_position
    surface_contact.contact_normal = contact_normal
    surface_contact.tilemap_coord = tilemap_coord
    surface_contact.tilemap_index = tilemap_index
    surface_contact.just_started = just_started
    surface_contact._is_still_touching = true
    
    match side:
        SurfaceSide.FLOOR:
            floor_contact = surface_contact
        SurfaceSide.LEFT_WALL:
            left_wall_contact = surface_contact
        SurfaceSide.RIGHT_WALL:
            right_wall_contact = surface_contact
        SurfaceSide.CEILING:
            ceiling_contact = surface_contact
        _:
            Sc.logger.error("CharacterSurfaceState._update_surface_contact_for_explicit_grab")
    
    if just_started:
        var details := (
                    "%s; " +
                    "v=%s; " +
                    "is_rounding_corner=%s; " +
                    "_update_surface_contact_for_explicit_grab()"
                ) % [
                    surface_contact.position_along_surface.to_string(
                            false, true),
                    Sc.utils.get_vector_string(velocity, 1),
                    is_rounding_corner,
                ]
        character._log(
                "Add contact",
                details,
                CharacterLogType.SURFACE,
                true)
        
        surfaces_to_contacts[surface_contact.surface] = surface_contact


func _update_action_state() -> void:
    _update_horizontal_direction()
    _update_grab_trigger_state()
    _update_rounding_corner_state()
    _update_grab_state()
    
    if just_started_rounding_corner or \
            just_changed_surface_while_rounding_corner:
        var is_rounding_successful := \
                _update_surface_contact_from_rounded_corner()
        if !is_rounding_successful:
            _cancel_rounding_corner()
        else:
            _update_touch_state()
    
    assert(!_get_is_grabbing_surface() or _get_is_touching_surface())
    
    _update_grab_contact()


func _update_horizontal_direction() -> void:
    # Flip the horizontal direction of the animation according to which way the
    # character is facing.
    if is_grabbing_left_wall or \
            is_grabbing_right_wall:
        horizontal_facing_sign = toward_wall_sign
    elif character.actions.pressed_face_right:
        horizontal_facing_sign = 1
    elif character.actions.pressed_face_left:
        horizontal_facing_sign = -1
    elif character.actions.pressed_right:
        horizontal_facing_sign = 1
    elif character.actions.pressed_left:
        horizontal_facing_sign = -1
    
    if is_grabbing_left_wall or \
            is_grabbing_right_wall:
        horizontal_acceleration_sign = 0
    elif character.actions.pressed_right:
        horizontal_acceleration_sign = 1
    elif character.actions.pressed_left:
        horizontal_acceleration_sign = -1
    else:
        horizontal_acceleration_sign = 0
    
    is_facing_wall = \
            (is_touching_right_wall and \
                horizontal_facing_sign > 0) or \
            (is_touching_left_wall and \
                horizontal_facing_sign < 0)
    is_pressing_into_wall = \
            (is_touching_right_wall and \
                character.actions.pressed_right) or \
            (is_touching_left_wall and \
                character.actions.pressed_left)
    is_pressing_away_from_wall = \
            (is_touching_right_wall and \
                character.actions.pressed_left) or \
            (is_touching_left_wall and \
                character.actions.pressed_right)


func _update_grab_trigger_state() -> void:
    var is_touching_wall_and_pressing_up: bool = \
            character.actions.pressed_up and \
            _get_is_touching_wall()
    var is_touching_wall_and_pressing_grab: bool = \
            character.actions.pressed_grab and \
            _get_is_touching_wall()
    
    var just_pressed_jump: bool = \
            character.actions.just_pressed_jump
    var is_pressing_floor_grab_input: bool = \
            character.actions.pressed_down and \
            !just_pressed_jump
    var is_pressing_ceiling_grab_input: bool = \
            character.actions.pressed_up and \
            !character.actions.pressed_down and \
            !just_pressed_jump
    var is_pressing_wall_grab_input := \
            is_pressing_into_wall and \
            !is_pressing_away_from_wall and \
            !just_pressed_jump
    var is_pressing_ceiling_release_input: bool = \
            character.actions.pressed_down and \
            !character.actions.pressed_up and \
            !character.actions.pressed_grab or \
            just_pressed_jump
    var is_pressing_wall_release_input := \
            is_pressing_away_from_wall and \
            !is_pressing_into_wall or \
            just_pressed_jump
    var is_pressing_fall_through_input: bool = \
            character.actions.pressed_down and \
            character.actions.just_pressed_jump
    
    is_triggering_explicit_floor_grab = \
            is_touching_floor and \
            is_pressing_floor_grab_input and \
            character.movement_params.can_grab_floors and \
            !just_pressed_jump
    is_triggering_explicit_ceiling_grab = \
            is_touching_ceiling and \
            is_pressing_ceiling_grab_input and \
            character.movement_params.can_grab_ceilings and \
            !just_pressed_jump
    is_triggering_explicit_wall_grab = \
            _get_is_touching_wall() and \
            is_pressing_wall_grab_input and \
            character.movement_params.can_grab_walls and \
            !just_pressed_jump
    
    var current_grabbed_side := \
            grabbed_surface.side if \
            is_instance_valid(grabbed_surface) else \
            SurfaceSide.NONE
    var previous_grabbed_side := \
            previous_grabbed_surface.side if \
            is_instance_valid(previous_grabbed_surface) else \
            SurfaceSide.NONE
    
    var are_current_and_previous_surfaces_convex_neighbors := \
            is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (previous_grabbed_surface.clockwise_convex_neighbor == \
                    grabbed_surface or \
            previous_grabbed_surface.counter_clockwise_convex_neighbor == \
                    grabbed_surface)
    
    var is_facing_previous_wall := \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                horizontal_facing_sign > 0) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                horizontal_facing_sign < 0)
    var is_pressing_into_previous_wall: bool = \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                character.actions.pressed_right) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                character.actions.pressed_left)
    var is_pressing_away_from_previous_wall: bool = \
            (previous_grabbed_side == SurfaceSide.RIGHT_WALL and \
                character.actions.pressed_left) or \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL and \
                character.actions.pressed_right)
    var is_facing_into_previous_wall_and_pressing_up: bool = \
            character.actions.pressed_up and is_facing_previous_wall
    var is_facing_into_previous_wall_and_pressing_grab: bool = \
            character.actions.pressed_grab and is_facing_previous_wall
    var is_pressing_previous_wall_grab_input := \
            (is_pressing_into_previous_wall or \
            is_facing_into_previous_wall_and_pressing_up or \
            is_facing_into_previous_wall_and_pressing_grab) and \
            !is_pressing_away_from_previous_wall and \
            !just_pressed_jump
    
    var is_still_triggering_wall_grab_since_rounding_corner_to_floor := \
            current_grabbed_side == SurfaceSide.FLOOR and \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL or \
            previous_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            (is_pressing_previous_wall_grab_input or \
            just_changed_surface_while_rounding_corner) and \
            !just_pressed_jump
    var is_still_triggering_wall_grab_since_rounding_corner_to_ceiling := \
            current_grabbed_side == SurfaceSide.CEILING and \
            (previous_grabbed_side == SurfaceSide.LEFT_WALL or \
            previous_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            (is_pressing_previous_wall_grab_input or \
            just_changed_surface_while_rounding_corner) and \
            !just_pressed_jump
    var is_still_triggering_floor_grab_since_rounding_corner_to_wall: bool = \
            (current_grabbed_side == SurfaceSide.LEFT_WALL or \
            current_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            previous_grabbed_side == SurfaceSide.FLOOR and \
            are_current_and_previous_surfaces_convex_neighbors and \
            (is_pressing_floor_grab_input or \
            character.actions.pressed_grab or \
            just_changed_surface_while_rounding_corner) and \
            !just_pressed_jump
    var is_still_triggering_ceiling_grab_since_rounding_corner_to_wall: bool = \
            (current_grabbed_side == SurfaceSide.LEFT_WALL or \
            current_grabbed_side == SurfaceSide.RIGHT_WALL) and \
            previous_grabbed_side == SurfaceSide.CEILING and \
            are_current_and_previous_surfaces_convex_neighbors and \
            (is_pressing_ceiling_grab_input or \
            character.actions.pressed_grab or \
            just_changed_surface_while_rounding_corner) and \
            !just_pressed_jump
    is_still_triggering_previous_surface_grab_since_rounding_corner = \
            is_still_triggering_wall_grab_since_rounding_corner_to_floor or \
            is_still_triggering_wall_grab_since_rounding_corner_to_ceiling or \
            is_still_triggering_floor_grab_since_rounding_corner_to_wall or \
            is_still_triggering_ceiling_grab_since_rounding_corner_to_wall
    
    is_triggering_implicit_floor_grab = \
            is_touching_floor and \
            character.movement_params.can_grab_floors and \
            !just_pressed_jump
    is_triggering_implicit_ceiling_grab = \
            (is_touching_ceiling and \
                character.actions.pressed_grab or \
            is_still_triggering_wall_grab_since_rounding_corner_to_ceiling) and \
            character.movement_params.can_grab_ceilings and \
            !just_pressed_jump
    is_triggering_implicit_wall_grab = \
            (is_touching_wall_and_pressing_up or \
            is_touching_wall_and_pressing_grab or \
            is_still_triggering_floor_grab_since_rounding_corner_to_wall or \
            is_still_triggering_ceiling_grab_since_rounding_corner_to_wall) and \
            character.movement_params.can_grab_walls and \
            !just_pressed_jump
    
    is_triggering_ceiling_release = \
            is_grabbing_ceiling and \
            is_pressing_ceiling_release_input and \
            !is_triggering_explicit_ceiling_grab and \
            !is_triggering_implicit_ceiling_grab
    is_triggering_wall_release = \
            _get_is_grabbing_wall() and \
            is_pressing_wall_release_input and \
            !is_triggering_explicit_wall_grab and \
            !is_triggering_implicit_wall_grab
    is_triggering_fall_through = \
            is_touching_floor and \
            is_pressing_fall_through_input
    is_triggering_jump = \
            just_pressed_jump and \
            !is_triggering_fall_through


func _update_rounding_corner_state() -> void:
    var half_width: float = \
            character.collider.half_width_height.x
    var half_height: float = \
            character.collider.half_width_height.y
    
    var are_current_and_previous_surfaces_convex_neighbors := \
            is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (previous_grabbed_surface.clockwise_convex_neighbor == \
                grabbed_surface or \
            previous_grabbed_surface.counter_clockwise_convex_neighbor == \
                grabbed_surface)
    
    var is_rounding_floor_corner_from_previous_lower_wall: bool = \
            is_grabbing_floor and \
            (is_triggering_explicit_floor_grab or \
            character.actions.pressed_grab or \
            is_still_triggering_previous_surface_grab_since_rounding_corner) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            character.movement_params.can_grab_walls and \
            (previous_grabbed_surface.side == SurfaceSide.LEFT_WALL and \
            center_position.x >= grabbed_surface.last_point.x or \
            previous_grabbed_surface.side == SurfaceSide.RIGHT_WALL and \
            center_position.x <= grabbed_surface.first_point.x) and \
            !is_triggering_fall_through and \
            !is_triggering_jump
    var is_rounding_floor_corner_to_next_lower_wall: bool = \
            is_grabbing_floor and \
            (is_triggering_explicit_floor_grab or \
            character.actions.pressed_grab) and \
            !is_rounding_floor_corner_from_previous_lower_wall and \
            character.movement_params.can_grab_walls and \
            (center_position.x <= grabbed_surface.first_point.x or \
            center_position.x >= grabbed_surface.last_point.x) and \
            !is_triggering_fall_through and \
            !is_triggering_jump
    is_rounding_floor_corner_to_lower_wall = \
            is_rounding_floor_corner_from_previous_lower_wall or \
            is_rounding_floor_corner_to_next_lower_wall
    just_changed_to_lower_wall_while_rounding_floor_corner = \
            is_rounding_floor_corner_to_lower_wall and \
            (center_position.x + half_width <= \
                grabbed_surface.first_point.x or \
            center_position.x - half_width >= \
                grabbed_surface.last_point.x)
    
    var is_rounding_ceiling_corner_from_previous_upper_wall: bool = \
            is_grabbing_ceiling and \
            (is_triggering_explicit_ceiling_grab or \
            is_triggering_implicit_ceiling_grab) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            character.movement_params.can_grab_walls and \
            (previous_grabbed_surface.side == SurfaceSide.LEFT_WALL and \
            center_position.x >= grabbed_surface.first_point.x or \
            previous_grabbed_surface.side == SurfaceSide.RIGHT_WALL and \
            center_position.x <= grabbed_surface.last_point.x) and \
            !is_triggering_ceiling_release and \
            !is_triggering_jump
    var is_rounding_ceiling_corner_to_next_upper_wall: bool = \
            is_grabbing_ceiling and \
            (is_triggering_explicit_ceiling_grab or \
            is_triggering_implicit_ceiling_grab) and \
            !is_rounding_ceiling_corner_from_previous_upper_wall and \
            character.movement_params.can_grab_walls and \
            (center_position.x <= grabbed_surface.last_point.x or \
            center_position.x >= grabbed_surface.first_point.x) and \
            !is_triggering_ceiling_release and \
            !is_triggering_jump
    is_rounding_ceiling_corner_to_upper_wall = \
            is_rounding_ceiling_corner_from_previous_upper_wall or \
            is_rounding_ceiling_corner_to_next_upper_wall
    just_changed_to_upper_wall_while_rounding_ceiling_corner = \
            is_rounding_ceiling_corner_to_upper_wall and \
            (center_position.x + half_width <= \
                grabbed_surface.last_point.x or \
            center_position.x - half_width >= \
                grabbed_surface.first_point.x)
    
    var is_rounding_wall_corner_from_previous_lower_ceiling: bool = \
            _get_is_grabbing_wall() and \
            (is_triggering_explicit_wall_grab or \
            is_triggering_implicit_wall_grab) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            character.movement_params.can_grab_ceilings and \
            previous_grabbed_surface.side == SurfaceSide.CEILING and \
            center_position.y >= grabbed_surface.bounding_box.end.y and \
            !is_triggering_wall_release and \
            !is_triggering_jump
    var is_rounding_wall_corner_to_next_lower_ceiling: bool = \
            _get_is_grabbing_wall() and \
            (is_triggering_explicit_wall_grab or \
            is_triggering_implicit_wall_grab) and \
            !is_rounding_wall_corner_from_previous_lower_ceiling and \
            character.movement_params.can_grab_ceilings and \
            center_position.y >= grabbed_surface.bounding_box.end.y and \
            !is_triggering_wall_release and \
            !is_triggering_jump
    is_rounding_wall_corner_to_lower_ceiling = \
            is_rounding_wall_corner_from_previous_lower_ceiling or \
            is_rounding_wall_corner_to_next_lower_ceiling
    just_changed_to_lower_ceiling_while_rounding_wall_corner = \
            is_rounding_wall_corner_to_lower_ceiling and \
            center_position.y - half_height >= \
                grabbed_surface.bounding_box.end.y
    
    var is_rounding_wall_corner_from_previous_upper_floor: bool = \
            _get_is_grabbing_wall() and \
            (is_triggering_explicit_wall_grab or \
            is_triggering_implicit_wall_grab) and \
            are_current_and_previous_surfaces_convex_neighbors and \
            character.movement_params.can_grab_floors and \
            previous_grabbed_surface.side == SurfaceSide.FLOOR and \
            center_position.y <= grabbed_surface.bounding_box.position.y and \
            !is_triggering_wall_release and \
            !is_triggering_jump
    var is_rounding_wall_corner_to_next_upper_floor: bool = \
            _get_is_grabbing_wall() and \
            (is_triggering_explicit_wall_grab or \
            is_triggering_implicit_wall_grab) and \
            !is_rounding_wall_corner_from_previous_upper_floor and \
            character.movement_params.can_grab_floors and \
            center_position.y <= grabbed_surface.bounding_box.position.y and \
            !is_triggering_wall_release and \
            !is_triggering_jump
    is_rounding_wall_corner_to_upper_floor = \
            is_rounding_wall_corner_from_previous_upper_floor or \
            is_rounding_wall_corner_to_next_upper_floor
    just_changed_to_upper_floor_while_rounding_wall_corner = \
            is_rounding_wall_corner_to_upper_floor and \
            center_position.y + half_height <= \
                 grabbed_surface.bounding_box.position.y
    
    var next_is_rounding_corner := \
            is_rounding_floor_corner_to_lower_wall or \
            is_rounding_ceiling_corner_to_upper_wall or \
            is_rounding_wall_corner_to_lower_ceiling or \
            is_rounding_wall_corner_to_upper_floor
    
    just_started_rounding_corner = \
            next_is_rounding_corner and \
            !is_rounding_corner
    just_stopped_rounding_corner = \
            !next_is_rounding_corner and \
            is_rounding_corner
    is_rounding_corner = next_is_rounding_corner
    just_changed_surface_while_rounding_corner = \
            just_changed_to_lower_wall_while_rounding_floor_corner or \
            just_changed_to_upper_wall_while_rounding_ceiling_corner or \
            just_changed_to_lower_ceiling_while_rounding_wall_corner or \
            just_changed_to_upper_floor_while_rounding_wall_corner
    is_rounding_corner_from_previous_surface = \
            is_rounding_floor_corner_from_previous_lower_wall or \
            is_rounding_ceiling_corner_from_previous_upper_wall or \
            is_rounding_wall_corner_from_previous_lower_ceiling or \
            is_rounding_wall_corner_from_previous_upper_floor
    
    if next_is_rounding_corner:
        if is_rounding_floor_corner_to_lower_wall:
            if center_position.x <= grabbed_surface.center.x:
                rounding_corner_position = grabbed_surface.first_point
            else:
                rounding_corner_position = grabbed_surface.last_point
        elif is_rounding_wall_corner_to_upper_floor:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                rounding_corner_position = grabbed_surface.first_point
            else:
                rounding_corner_position = grabbed_surface.last_point
        elif is_rounding_wall_corner_to_lower_ceiling:
            if grabbed_surface.side == SurfaceSide.LEFT_WALL:
                rounding_corner_position = grabbed_surface.last_point
            else:
                rounding_corner_position = grabbed_surface.first_point
        elif is_rounding_ceiling_corner_to_upper_wall:
            if center_position.x <= grabbed_surface.center.x:
                rounding_corner_position = grabbed_surface.last_point
            else:
                rounding_corner_position = grabbed_surface.first_point
        else:
            Sc.logger.error("CharacterSurfaceState._update_rounding_corner_state")
            rounding_corner_position = Vector2.INF
    else:
        rounding_corner_position = Vector2.INF
    
    var is_rounding_right_wall_corner := \
            (is_rounding_wall_corner_to_lower_ceiling or \
            is_rounding_wall_corner_to_upper_floor) and \
            grabbed_surface.side == SurfaceSide.RIGHT_WALL
    var is_rounding_left_corner_of_horizontal_surface := \
            (is_rounding_floor_corner_to_lower_wall or \
            is_rounding_ceiling_corner_to_upper_wall) and \
            center_position.x <= rounding_corner_position.x
    is_rounding_left_corner = \
            is_rounding_right_wall_corner or \
            is_rounding_left_corner_of_horizontal_surface
    
    if just_started_rounding_corner:
        var details: String = \
                "corner_p=%s; " % \
                Sc.utils.get_vector_string(rounding_corner_position, 1)
        if is_rounding_floor_corner_to_lower_wall:
            details += "to_lower_wall; "
        if is_rounding_ceiling_corner_to_upper_wall:
            details += "to_upper_wall; "
        if is_rounding_wall_corner_to_upper_floor:
            details += "to_upper_floor; "
        if is_rounding_wall_corner_to_lower_ceiling:
            details += "to_lower_ceiling; "
        details += "left=%s" % is_rounding_left_corner
        character._log(
                "Start roundi",
                details,
                CharacterLogType.SURFACE,
                true)
    
    if just_changed_surface_while_rounding_corner:
        var details: String = \
                "corner_p=%s; " % \
                Sc.utils.get_vector_string(rounding_corner_position, 1)
        if just_changed_to_lower_wall_while_rounding_floor_corner:
            details += "to_lower_wall; "
        if just_changed_to_upper_wall_while_rounding_ceiling_corner:
            details += "to_upper_wall; "
        if just_changed_to_lower_ceiling_while_rounding_wall_corner:
            details += "to_lower_ceiling; "
        if just_changed_to_upper_floor_while_rounding_wall_corner:
            details += "to_upper_floor; "
        details += "left=%s" % is_rounding_left_corner
        character._log(
                "Sur chng rou",
                details,
                CharacterLogType.SURFACE,
                true)
    
    if just_stopped_rounding_corner:
        character._log(
                "Stop roundin",
                "",
                CharacterLogType.SURFACE,
                true)


func _update_grab_state() -> void:
    var standard_is_grabbing_ceiling: bool = \
            (is_touching_ceiling or \
                 is_rounding_ceiling_corner_to_upper_wall) and \
            (is_grabbing_ceiling or \
                is_triggering_explicit_ceiling_grab or \
                (is_triggering_implicit_ceiling_grab and \
                !is_grabbing_floor and \
                !_get_is_grabbing_wall())) and \
            !is_triggering_ceiling_release and \
            !is_triggering_jump and \
            (is_triggering_explicit_ceiling_grab or \
                 !is_triggering_explicit_wall_grab)
    
    var standard_is_grabbing_wall: bool = \
            (_get_is_touching_wall() or \
                is_rounding_wall_corner_to_lower_ceiling or \
                is_rounding_wall_corner_to_upper_floor) and \
            (_get_is_grabbing_wall() or \
                is_triggering_explicit_wall_grab or \
                (is_triggering_implicit_wall_grab and \
                !is_grabbing_floor and \
                !is_grabbing_ceiling)) and \
            !is_triggering_wall_release and \
            !is_triggering_jump and \
            !is_triggering_explicit_floor_grab and \
            !is_triggering_explicit_ceiling_grab
    
    var standard_is_grabbing_floor: bool = \
            (is_touching_floor or \
                is_rounding_floor_corner_to_lower_wall) and \
            (is_grabbing_floor or \
                is_triggering_explicit_floor_grab or \
                (is_triggering_implicit_floor_grab and \
                !is_grabbing_ceiling and \
                !_get_is_grabbing_wall())) and \
            !is_triggering_fall_through and \
            !is_triggering_jump and \
            (is_triggering_explicit_floor_grab or \
                !is_triggering_explicit_wall_grab)
    
    var next_is_grabbing_ceiling := \
            (standard_is_grabbing_ceiling or \
            just_changed_to_lower_ceiling_while_rounding_wall_corner) and \
            !just_changed_to_upper_wall_while_rounding_ceiling_corner and \
            !is_triggering_ceiling_release
    
    var next_is_grabbing_floor := \
            (standard_is_grabbing_floor or \
            just_changed_to_upper_floor_while_rounding_wall_corner) and \
            !just_changed_to_lower_wall_while_rounding_floor_corner and \
            !is_triggering_fall_through and \
            !next_is_grabbing_ceiling
    
    var next_is_grabbing_wall := \
            (standard_is_grabbing_wall or \
            just_changed_to_lower_wall_while_rounding_floor_corner or \
            just_changed_to_upper_wall_while_rounding_ceiling_corner) and \
            !just_changed_to_upper_floor_while_rounding_wall_corner and \
            !just_changed_to_lower_ceiling_while_rounding_wall_corner and \
            !is_triggering_wall_release and \
            !next_is_grabbing_floor and \
            !next_is_grabbing_ceiling
    
    var next_is_grabbing_left_wall := \
            next_is_grabbing_wall and \
            ((is_rounding_corner and \
                center_position.x >= rounding_corner_position.x) or \
            (!is_rounding_corner and \
                is_touching_left_wall))
    var next_is_grabbing_right_wall := \
            next_is_grabbing_wall and \
            ((is_rounding_corner and \
                center_position.x <= rounding_corner_position.x) or \
            (!is_rounding_corner and \
                is_touching_right_wall))
    
    var next_is_grabbing_surface := \
            next_is_grabbing_floor or \
            next_is_grabbing_ceiling or \
            next_is_grabbing_wall
    
    var next_just_grabbed_floor := \
            next_is_grabbing_floor and !is_grabbing_floor
    var next_just_stopped_grabbing_floor := \
            !next_is_grabbing_floor and is_grabbing_floor
    
    var next_just_grabbed_ceiling := \
            next_is_grabbing_ceiling and !is_grabbing_ceiling
    var next_just_stopped_grabbing_ceiling := \
            !next_is_grabbing_ceiling and is_grabbing_ceiling
    
    var next_just_grabbed_left_wall := \
            next_is_grabbing_left_wall and !is_grabbing_left_wall
    var next_just_stopped_grabbing_left_wall := \
            !next_is_grabbing_left_wall and is_grabbing_left_wall
    
    var next_just_grabbed_right_wall := \
            next_is_grabbing_right_wall and !is_grabbing_right_wall
    var next_just_stopped_grabbing_right_wall := \
            !next_is_grabbing_right_wall and is_grabbing_right_wall
    
    var next_just_entered_air := \
            !next_is_grabbing_surface and _get_is_grabbing_surface()
    var next_just_left_air := \
            next_is_grabbing_surface and !_get_is_grabbing_surface()
    
    is_grabbing_floor = next_is_grabbing_floor
    is_grabbing_ceiling = next_is_grabbing_ceiling
    is_grabbing_left_wall = next_is_grabbing_left_wall
    is_grabbing_right_wall = next_is_grabbing_right_wall
    
    just_grabbed_floor = \
            next_just_grabbed_floor or \
            just_grabbed_floor and \
            !next_just_stopped_grabbing_floor
    just_stopped_grabbing_floor = \
            next_just_stopped_grabbing_floor or \
            just_stopped_grabbing_floor and \
            !next_just_grabbed_floor
    
    just_grabbed_ceiling = \
            next_just_grabbed_ceiling or \
            just_grabbed_ceiling and \
            !next_just_stopped_grabbing_ceiling
    just_stopped_grabbing_ceiling = \
            next_just_stopped_grabbing_ceiling or \
            just_stopped_grabbing_ceiling and \
            !next_just_grabbed_ceiling
    
    just_grabbed_left_wall = \
            next_just_grabbed_left_wall or \
            just_grabbed_left_wall and \
            !next_just_stopped_grabbing_left_wall
    just_stopped_grabbing_left_wall = \
            next_just_stopped_grabbing_left_wall or \
            just_stopped_grabbing_left_wall and \
            !next_just_grabbed_left_wall
    
    just_grabbed_right_wall = \
            next_just_grabbed_right_wall or \
            just_grabbed_right_wall and \
            !next_just_stopped_grabbing_right_wall
    just_stopped_grabbing_right_wall = \
            next_just_stopped_grabbing_right_wall or \
            just_stopped_grabbing_right_wall and \
            !next_just_grabbed_right_wall
    
    just_entered_air = \
            next_just_entered_air or \
            just_entered_air and \
            !next_just_left_air
    just_left_air = \
            next_just_left_air or \
            just_left_air and \
            !next_just_entered_air
    
    if is_grabbing_floor:
        surface_type = SurfaceType.FLOOR
    elif _get_is_grabbing_wall():
        surface_type = SurfaceType.WALL
    elif is_grabbing_ceiling:
        surface_type = SurfaceType.CEILING
    else:
        surface_type = SurfaceType.AIR
    
    # Whether we should fall through fall-through floors.
    match surface_type:
        SurfaceType.FLOOR:
            is_descending_through_floors = is_triggering_fall_through
        SurfaceType.WALL:
            is_descending_through_floors = character.actions.pressed_down
        SurfaceType.CEILING:
            is_descending_through_floors = false
        SurfaceType.AIR, \
        SurfaceType.OTHER:
            is_descending_through_floors = character.actions.pressed_down
        _:
            Sc.logger.error("CharacterSurfaceState._update_grab_state")
    
    # FIXME: ------- Add support for an ascend-through ceiling input.
    # Whether we should ascend-up through jump-through ceilings.
    is_ascending_through_ceilings = \
            !character.movement_params.can_grab_ceilings or \
                (!is_grabbing_ceiling and true)
    
    # Whether we should fall through fall-through floors.
    is_grabbing_walk_through_walls = \
            character.movement_params.can_grab_walls and \
                (_get_is_grabbing_wall() or \
                    character.actions.pressed_up)


func _update_grab_contact() -> void:
    var previous_grabbed_tilemap := grabbed_tilemap
    var previous_grab_position_tilemap_coord := grab_position_tilemap_coord
    
    surface_grab = null
    
    if _get_is_grabbing_surface():
        surface_grab = _get_grab_contact()
        assert(is_instance_valid(surface_grab))
        
        var next_grabbed_surface := surface_grab.surface
        var next_grab_position := surface_grab.contact_position
        var next_grab_normal := surface_grab.contact_normal
        grabbed_tilemap = surface_grab.surface.tile_map
        grab_position_tilemap_coord = surface_grab.tilemap_coord
        PositionAlongSurface.copy(
                center_position_along_surface,
                surface_grab.position_along_surface)
        PositionAlongSurface.copy(
                last_position_along_surface,
                center_position_along_surface)
        
        just_changed_surface = \
                just_changed_surface or \
                just_left_air or \
                next_grabbed_surface != grabbed_surface
        if just_changed_surface and \
                next_grabbed_surface != grabbed_surface and \
                is_instance_valid(grabbed_surface):
            previous_grabbed_surface = grabbed_surface
        grabbed_surface = next_grabbed_surface
        
        just_changed_grab_position = \
                just_changed_grab_position or \
                just_left_air or \
                next_grab_position != grab_position
        if just_changed_grab_position and \
                next_grab_position != grab_position and \
                grab_position != Vector2.INF:
            previous_grab_position = grab_position
            previous_grab_normal = grab_normal
        grab_position = next_grab_position
        grab_normal = next_grab_normal
        
        just_changed_tilemap = \
                just_changed_tilemap or \
                just_left_air or \
                grabbed_tilemap != previous_grabbed_tilemap
        
        just_changed_tilemap_coord = \
                just_changed_tilemap_coord or \
                just_left_air or \
                grab_position_tilemap_coord != \
                    previous_grab_position_tilemap_coord
        
    else:
        if just_entered_air:
            just_changed_grab_position = true
            just_changed_tilemap = true
            just_changed_tilemap_coord = true
            just_changed_surface = true
            previous_grabbed_surface = \
                    grabbed_surface if \
                    is_instance_valid(grabbed_surface) else \
                    previous_grabbed_surface
            previous_grab_position = \
                    grab_position if \
                    grab_position != Vector2.INF else \
                    previous_grab_position
            previous_grab_normal = \
                    grab_normal if \
                    grab_normal != Vector2.INF else \
                    previous_grab_normal
        
        surface_grab = null
        grab_position = Vector2.INF
        grab_normal = Vector2.INF
        grabbed_tilemap = null
        grab_position_tilemap_coord = Vector2.INF
        grabbed_surface = null
        center_position_along_surface.reset()


func _get_is_touching_wall() -> bool:
    return is_touching_left_wall or \
            is_touching_right_wall


func _get_is_touching_surface() -> bool:
    return is_touching_floor or \
            is_touching_ceiling or \
            is_touching_left_wall or \
            is_touching_right_wall


func _get_is_grabbing_wall() -> bool:
    return is_grabbing_left_wall or \
            is_grabbing_right_wall


func _get_is_grabbing_surface() -> bool:
    return is_grabbing_floor or \
            is_grabbing_ceiling or \
            is_grabbing_left_wall or \
            is_grabbing_right_wall


func _get_just_touched_wall() -> bool:
    return just_touched_left_wall or \
            just_touched_right_wall


func _get_just_touched_surface() -> bool:
    return just_touched_floor or \
            just_touched_ceiling or \
            just_touched_left_wall or \
            just_touched_right_wall


func _get_just_stopped_touching_wall() -> bool:
    return just_stopped_touching_left_wall or \
            just_stopped_touching_right_wall


func _get_just_stopped_touching_surface() -> bool:
    return just_stopped_touching_floor or \
            just_stopped_touching_ceiling or \
            just_stopped_touching_left_wall or \
            just_stopped_touching_right_wall


func _get_just_grabbed_wall() -> bool:
    return just_grabbed_left_wall or \
            just_grabbed_right_wall


func _get_just_grabbed_surface() -> bool:
    return just_grabbed_floor or \
            just_grabbed_ceiling or \
            just_grabbed_left_wall or \
            just_grabbed_right_wall


func _get_just_stopped_grabbing_wall() -> bool:
    return just_stopped_grabbing_left_wall or \
            just_stopped_grabbing_right_wall


func _get_just_stopped_grabbing_surface() -> bool:
    return just_stopped_grabbing_floor or \
            just_stopped_grabbing_ceiling or \
            just_stopped_grabbing_left_wall or \
            just_stopped_grabbing_right_wall


func _get_grab_contact() -> SurfaceContact:
    for surface in surfaces_to_contacts:
        if surface.side == SurfaceSide.FLOOR and \
                    is_grabbing_floor or \
                surface.side == SurfaceSide.LEFT_WALL and \
                    is_grabbing_left_wall or \
                surface.side == SurfaceSide.RIGHT_WALL and \
                    is_grabbing_right_wall or \
                surface.side == SurfaceSide.CEILING and \
                    is_grabbing_ceiling:
            return surfaces_to_contacts[surface]
    return null


func _get_contact_count() -> int:
    return surfaces_to_contacts.size()


func get_just_changed_to_neighbor_surface() -> bool:
    return just_changed_surface and \
            is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (grabbed_surface.clockwise_neighbor == \
                previous_grabbed_surface or \
            grabbed_surface.counter_clockwise_neighbor == \
                previous_grabbed_surface)


func get_is_previous_surface_collinear_neighbor() -> bool:
    return is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (grabbed_surface.clockwise_collinear_neighbor == \
                previous_grabbed_surface or \
            grabbed_surface.counter_clockwise_collinear_neighbor == \
                previous_grabbed_surface)


func get_is_previous_surface_convex_neighbor() -> bool:
    return is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (grabbed_surface.clockwise_convex_neighbor == \
                previous_grabbed_surface or \
            grabbed_surface.counter_clockwise_convex_neighbor == \
                previous_grabbed_surface)


func get_is_previous_surface_concave_neighbor() -> bool:
    return is_instance_valid(grabbed_surface) and \
            is_instance_valid(previous_grabbed_surface) and \
            (grabbed_surface.clockwise_concave_neighbor == \
                previous_grabbed_surface or \
            grabbed_surface.counter_clockwise_concave_neighbor == \
                previous_grabbed_surface)


func clear_current_state() -> void:
    # Let these properties be updated in the normal way:
    # -   previous_center_position
    # -   did_move_frame_before_last
    # -   previous_grab_position
    # -   previous_grab_normal
    # -   previous_grabbed_surface
    # -   last_position_along_surface
    
    is_touching_floor = false
    is_touching_ceiling = false
    is_touching_left_wall = false
    is_touching_right_wall = false
    
    is_grabbing_floor = false
    is_grabbing_ceiling = false
    is_grabbing_left_wall = false
    is_grabbing_right_wall = false
    
    just_touched_floor = false
    just_touched_ceiling = false
    just_touched_left_wall = false
    just_touched_right_wall = false
    
    just_stopped_touching_floor = false
    just_stopped_touching_ceiling = false
    just_stopped_touching_left_wall = false
    just_stopped_touching_right_wall = false
    
    just_grabbed_floor = false
    just_grabbed_ceiling = false
    just_grabbed_left_wall = false
    just_grabbed_right_wall = false
    
    just_stopped_grabbing_floor = false
    just_stopped_grabbing_ceiling = false
    just_stopped_grabbing_left_wall = false
    just_stopped_grabbing_right_wall = false
    
    is_facing_wall = false
    is_pressing_into_wall = false
    is_pressing_away_from_wall = false
    
    is_triggering_explicit_wall_grab = false
    is_triggering_explicit_ceiling_grab = false
    is_triggering_explicit_floor_grab = false
    
    is_triggering_implicit_wall_grab = false
    is_triggering_implicit_ceiling_grab = false
    is_triggering_implicit_floor_grab = false
    
    is_triggering_wall_release = false
    is_triggering_ceiling_release = false
    is_triggering_fall_through = false
    is_triggering_jump = false
    
    is_still_triggering_previous_surface_grab_since_rounding_corner = false
    
    is_rounding_floor_corner_to_lower_wall = false
    is_rounding_ceiling_corner_to_upper_wall = false
    is_rounding_wall_corner_to_lower_ceiling = false
    is_rounding_wall_corner_to_upper_floor = false
    is_rounding_corner = false
    is_rounding_corner_from_previous_surface = false
    is_rounding_left_corner = false
    
    just_started_rounding_corner = false
    just_stopped_rounding_corner = false
    just_changed_to_lower_wall_while_rounding_floor_corner = false
    just_changed_to_upper_wall_while_rounding_ceiling_corner = false
    just_changed_to_lower_ceiling_while_rounding_wall_corner = false
    just_changed_to_upper_floor_while_rounding_wall_corner = false
    just_changed_surface_while_rounding_corner = false
    
    is_descending_through_floors = false
    is_ascending_through_ceilings = false
    is_grabbing_walk_through_walls = false
    
    surface_type = SurfaceType.AIR
    
    did_move_last_frame = !Sc.geometry.are_points_equal_with_epsilon(
            previous_center_position,
            center_position,
            0.00001)
    grab_position = Vector2.INF
    grab_normal = Vector2.INF
    grab_position_tilemap_coord = Vector2.INF
    grabbed_tilemap = null
    grabbed_surface = null
    center_position_along_surface.reset()
    
    just_changed_surface = false
    just_changed_tilemap = false
    just_changed_tilemap_coord = false
    just_changed_grab_position = false
    just_entered_air = false
    just_left_air = false
    
    horizontal_facing_sign = -1
    horizontal_acceleration_sign = 0
    toward_wall_sign = 0
    
    surfaces_to_contacts.clear()
    surface_grab = null
    floor_contact = null
    ceiling_contact = null
    left_wall_contact = null
    right_wall_contact = null
    
    contact_count = 0


func sync_state_for_surface_grab(
        surface: Surface,
        center_position: Vector2,
        did_just_grab: bool,
        facing_left: bool) -> void:
    var next_just_touched_floor := false
    var next_just_grabbed_floor := false
    var next_just_touched_left_wall := false
    var next_just_grabbed_left_wall := false
    var next_just_touched_right_wall := false
    var next_just_grabbed_right_wall := false
    var next_just_touched_ceiling := false
    var next_just_grabbed_ceiling := false
    if did_just_grab:
        match surface.side:
            SurfaceSide.FLOOR:
                next_just_touched_floor = !is_touching_floor
                next_just_grabbed_floor = !is_grabbing_floor
            SurfaceSide.LEFT_WALL:
                next_just_touched_left_wall = !is_touching_left_wall
                next_just_grabbed_left_wall = !is_grabbing_left_wall
            SurfaceSide.RIGHT_WALL:
                next_just_touched_right_wall = !is_touching_right_wall
                next_just_grabbed_right_wall = !is_grabbing_right_wall
            SurfaceSide.CEILING:
                next_just_touched_ceiling = !is_touching_ceiling
                next_just_grabbed_ceiling = !is_grabbing_ceiling
            _:
                Sc.logger.error("CharacterSurfaceState.sync_state_for_surface_grab")
    
    var previous_grab_position := grab_position
    var previous_grab_normal := grab_normal
    var previous_grabbed_surface := grabbed_surface
    var previous_is_grabbing_surface := _get_is_grabbing_surface()
    var previous_grabbed_tilemap := grabbed_tilemap
    var previous_grab_position_tilemap_coord := grab_position_tilemap_coord
    
    clear_current_state()
    
    just_touched_floor = next_just_touched_floor
    just_grabbed_floor = next_just_grabbed_floor
    just_touched_left_wall = next_just_touched_left_wall
    just_grabbed_left_wall = next_just_grabbed_left_wall
    just_touched_right_wall = next_just_touched_right_wall
    just_grabbed_right_wall = next_just_grabbed_right_wall
    just_touched_ceiling = next_just_touched_ceiling
    just_grabbed_ceiling = next_just_grabbed_ceiling
    
    self.center_position = center_position
    grabbed_surface = surface
    horizontal_facing_sign = -1 if facing_left else 1
    contact_count = 1
    
    grab_position = Sc.geometry.get_closest_point_on_surface_to_shape(
            surface,
            center_position,
            character.collider)
    grab_normal = Sc.geometry.get_surface_normal_at_point(
            surface,
            grab_position)
    grab_position_tilemap_coord = Sc.geometry.world_to_tilemap(
            grab_position,
            surface.tile_map)
    grabbed_tilemap = surface.tile_map
    var grab_position_tilemap_index: int = \
            Sc.geometry.get_tilemap_index_from_grid_coord(
                grab_position_tilemap_coord,
                grabbed_tilemap)
    center_position_along_surface.match_current_grab(surface, center_position)
    PositionAlongSurface.copy(
            last_position_along_surface,
            center_position_along_surface)
    
    surface_grab = SurfaceContact.new()
    surface_grab.type = SurfaceContact.MATCH_TRAJECTORY
    surface_grab.surface = surface
    surface_grab.contact_position = grab_position
    surface_grab.contact_normal = grab_normal
    surface_grab.tilemap_coord = grab_position_tilemap_coord
    surface_grab.tilemap_index = grab_position_tilemap_index
    surface_grab.position_along_surface.match_current_grab(
            surface,
            center_position)
    surface_grab.just_started = did_just_grab
    surface_grab._is_still_touching = true
    surfaces_to_contacts[surface] = surface_grab
    
    just_entered_air = false
    just_left_air = !previous_is_grabbing_surface
    
    just_changed_surface = \
            just_left_air or \
            grabbed_surface != previous_grabbed_surface
    if grabbed_surface != previous_grabbed_surface:
        self.previous_grabbed_surface = previous_grabbed_surface
    just_changed_grab_position = \
            just_left_air or \
            grab_position != previous_grab_position
    if grab_position != previous_grab_position:
        self.previous_grab_position = previous_grab_position
        self.previous_grab_normal = previous_grab_normal
    just_changed_tilemap = \
            just_left_air or \
            grabbed_tilemap != previous_grabbed_tilemap
    just_changed_tilemap_coord = \
            just_left_air or \
            grab_position_tilemap_coord != \
                previous_grab_position_tilemap_coord
    
    match surface.side:
        SurfaceSide.FLOOR:
            is_touching_floor = true
            is_grabbing_floor = true
            is_triggering_implicit_floor_grab = false
            surface_type = SurfaceType.FLOOR
            floor_contact = surface_grab
        SurfaceSide.LEFT_WALL:
            is_touching_left_wall = true
            is_grabbing_left_wall = true
            is_facing_wall = true
            is_triggering_implicit_wall_grab = false
            surface_type = SurfaceType.WALL
            horizontal_facing_sign = -1
            toward_wall_sign = -1
            left_wall_contact = surface_grab
        SurfaceSide.RIGHT_WALL:
            is_touching_right_wall = true
            is_grabbing_right_wall = true
            is_facing_wall = true
            is_triggering_implicit_wall_grab = false
            surface_type = SurfaceType.WALL
            horizontal_facing_sign = 1
            toward_wall_sign = 1
            right_wall_contact = surface_grab
        SurfaceSide.CEILING:
            is_touching_ceiling = true
            is_grabbing_ceiling = true
            is_triggering_implicit_ceiling_grab = false
            surface_type = SurfaceType.CEILING
            ceiling_contact = surface_grab
        _:
            Sc.logger.error("CharacterSurfaceState.sync_state_for_surface_grab")
    
    if just_changed_surface:
        character._update_reachable_surfaces(grabbed_surface)


func sync_state_for_surface_release(
        surface: Surface,
        center_position: Vector2) -> void:
    var next_just_stopped_touching_floor := false
    var next_just_stopped_grabbing_floor := false
    var next_just_stopped_touching_left_wall := false
    var next_just_stopped_grabbing_left_wall := false
    var next_just_stopped_touching_right_wall := false
    var next_just_stopped_grabbing_right_wall := false
    var next_just_stopped_touching_ceiling := false
    var next_just_stopped_grabbing_ceiling := false
    match surface.side:
        SurfaceSide.FLOOR:
            next_just_stopped_touching_floor = is_touching_floor
            next_just_stopped_grabbing_floor = is_grabbing_floor
        SurfaceSide.LEFT_WALL:
            next_just_stopped_touching_left_wall = is_touching_left_wall
            next_just_stopped_grabbing_left_wall = is_grabbing_left_wall
        SurfaceSide.RIGHT_WALL:
            next_just_stopped_touching_right_wall = is_touching_right_wall
            next_just_stopped_grabbing_right_wall = is_grabbing_right_wall
        SurfaceSide.CEILING:
            next_just_stopped_touching_ceiling = is_touching_ceiling
            next_just_stopped_grabbing_ceiling = is_grabbing_ceiling
        _:
            Sc.logger.error("CharacterSurfaceState.sync_state_for_surface_release")
    
    var previous_grab_position := grab_position
    var previous_grab_normal := grab_normal
    var previous_grabbed_surface := grabbed_surface
    var previous_is_grabbing_surface := _get_is_grabbing_surface()
    
    # TODO: Call this?
#    clear_current_state()
    
    just_entered_air = previous_is_grabbing_surface
    just_left_air = false
    
    if just_entered_air:
        just_changed_grab_position = true
        just_changed_tilemap = true
        just_changed_tilemap_coord = true
        just_changed_surface = true
        previous_grabbed_surface = previous_grabbed_surface
        previous_grab_position = previous_grab_position
        previous_grab_normal = previous_grab_normal
    
    match surface.side:
        SurfaceSide.FLOOR:
            is_touching_floor = false
            is_grabbing_floor = false
            just_stopped_touching_floor = next_just_stopped_touching_floor
            just_stopped_grabbing_floor = next_just_stopped_grabbing_floor
        SurfaceSide.LEFT_WALL:
            is_touching_left_wall = false
            is_grabbing_left_wall = false
            just_stopped_touching_left_wall = \
                    next_just_stopped_touching_left_wall
            just_stopped_grabbing_left_wall = \
                    next_just_stopped_grabbing_left_wall
        SurfaceSide.RIGHT_WALL:
            is_touching_right_wall = false
            is_grabbing_right_wall = false
            just_stopped_touching_right_wall = \
                    next_just_stopped_touching_right_wall
            just_stopped_grabbing_right_wall = \
                    next_just_stopped_grabbing_right_wall
        SurfaceSide.CEILING:
            is_touching_ceiling = false
            is_grabbing_ceiling = false
            just_stopped_touching_ceiling = next_just_stopped_touching_ceiling
            just_stopped_grabbing_ceiling = next_just_stopped_grabbing_ceiling
        _:
            Sc.logger.error("CharacterSurfaceState.sync_state_for_surface_release")
