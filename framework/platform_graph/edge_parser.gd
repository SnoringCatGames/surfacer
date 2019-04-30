extends Reference
class_name EdgeParser

const DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING = 10000

# FIXME: LEFT OFF HERE:
# 
# - PlatformGraphNodes._get_closest_fallable_surface
#   - Use this along with get_nearby_surfaces to calculate possible edges.
#   - Call this dynamically when starting new navigations from an in-air position (make sure it's a cheap operation!).
#   - Add TODOs:
#     - TODO: Add support for choosing the closest "non-occluded" surface to the destination, rather than the closest surface to the origin.
#     - TODO: Actually consider changing velocity due to gravity.
# - Use FallFromAirMovement
# - Use PlayerMovement.get_max_upward_distance and PlayerMovement.get_max_horizontal_distance
# - Add logic to use path.start_instructions when we start a navigation while the player isn't on a surface.
# - Add logic to use path.end_instructions when the destination is far enough from the surface AND an optional
#     should_jump_to_reach_destination parameter is provided.
# 
# - Use get_max_upward_distance and get_max_horizontal_distance to get a bounding box and use that
#   in nodes.get_nearby_surfaces.
# 
# - Add support for creating PlatformGraphEdge.
# - Add support for executing PlatformGraphEdge.
# - Add support for actually parsing out the whole edge set (for our current simple jump, and ignoring walls).
# - Add annotations for the whole edge set.
# 
# - Implement get_all_edges_from_surface for jumping.
# - Add annotations for the actual trajectories that are defined by PlatformGraphEdge.
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
# - Add support for actually navigating end-to-end to a given target point.
# - Add annotations for just the path that the navigator is currently using.
# - Test out the accuracy of edge traversal actually matching up to our pre-calculated trajectories.
# 
# - Add logic to automatically self-correct to the expected position/movement/state sometimes...
#   - When? Each frame? Only when we're further away than our tolerance allows?
# 
# - Add support for actually considering the discrete physics time steps rather than assuming
#   continuous integration?
#   - OR, add support for fudging it?
#     - I could calculate and emulate all of this as previously planned to be realistic and use
#       the same rules as a HumanPlayer; BUT, then actually adjust the movement to matchup with
#       the expected pre-calculated result (so, actually, not really run the instructions set at
#       all?)
#     - It's probably at least worth adding an optional mode that does this and comparing the
#       performance.
# 
# - Refactor PlayerMovement classes, so that whether the start and end posiition is on a platform
#   or in the air is configuration that JumpFromPlatformMovement handles directly, rather than
#   relying on a separate FallFromAir class?
# - Add support for including walls in our navigation.
# - Add support for other PlayerMovement sub-classes:
#   - JumpFromWallMovement
#   - FallFromPlatformMovement
#   - FallFromWallMovement
# - Add support for other jump aspects:
#   - Fast fall
#   - Variable jump height
#   - Double jump
#   - Horizontal acceleration?
# 
# - Update the pre-configured Input Map in Project Settings to use more semantic keys instead of just up/down/etc.
# - Document in a separate markdown file exactly which Input Map keys this framework depends on.
# 
# - MAKE get_nearby_surfaces MORE EFFICIENT? (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run at the start.
# 
# - Add logic to Player when calculating touched edges to check that the collider is a stationary TileMap object
# 
# - Figure out how to configure input names/mappings (or just add docs specifying that the
#   consumer must use these input names?)
# - Test exporting to HTML5.
# - Start adding networking support.

static func calculate_edges(surfaces: Array, player_info: PlayerTypeConfiguration) -> Array:
    var edges := []
    
    # FIXME: LEFT OFF HERE: C: Resume here after fixing others ***************
    # - Refactor PlayerMovement to return the collection of reachable surfaces.
    #   - It needs to handle getting the appropriate possibilities (nearby, fallable, ...) from PlatformGraphNodes
    # 
    # - Implementh a new get_nearby_or_fallable_surfaces
    # 
    # - nodes._get_closest_fallable_surface
    #   - start: Vector2, player_movement: PlayerMovement, surfaces: Array, can_use_horizontal_distance: bool
    # - nodes.get_nearby_surfaces
    #   - target_surface: Surface, distance_threshold: float, other_surfaces: Array
#    for movement_type in player_info.movement_types[i]:
#        if movement_type.can_traverse_edge:
#            for surface in surfaces:
#                # FIXME: Implement this function...
##                var surface_b = PlatformGraphNodes.get_nearby_or_fallable_surfaces()
#                var all_instructions = movement_type.get_all_edges_from_surface(surface)
#                for instructions in all_instructions:
#                    # FIXME: store the edge in the edges set
#                    pass
    
    return edges

# Gets all other surfaces that are near the given surface.
static func _get_nearby_surfaces(target_surface: Surface, distance_threshold: float, \
        other_surfaces: Array) -> Array:
    var result := []
    for other_surface in other_surfaces:
        if _get_are_surfaces_close(target_surface, other_surface, distance_threshold) and \
                target_surface != other_surface:
            result.push_back(other_surface)
    return result

static func _get_are_surfaces_close(surface_a: Surface, surface_b: Surface, \
        distance_threshold: float) -> bool:
    var vertices_a := surface_a.vertices
    var vertices_b := surface_b.vertices
    var vertex_a_a: Vector2
    var vertex_a_b: Vector2
    var vertex_b_a: Vector2
    var vertex_b_b: Vector2
    
    var expanded_bounding_box_a = surface_a.bounding_box.grow(distance_threshold)
    if expanded_bounding_box_a.intersects(surface_b.bounding_box):
        var expanded_bounding_box_b = surface_b.bounding_box.grow(distance_threshold)
        var distance_squared_threshold = distance_threshold * distance_threshold
        
        # Compare each segment in A with each vertex in B.
        for i_a in range(vertices_a.size() - 1):
            vertex_a_a = vertices_a[i_a]
            vertex_a_b = vertices_a[i_a + 1]
            
            for i_b in range(vertices_b.size()):
                vertex_b_a = vertices_b[i_b]
                
                if expanded_bounding_box_a.has_point(vertex_b_a) and \
                        Geometry.get_distance_squared_from_point_to_segment( \
                                vertex_b_a, vertex_a_a, vertex_a_b) <= distance_squared_threshold:
                    return true
        
        # Compare each vertex in A with each segment in B.
        for i_a in range(vertices_a.size()):
            vertex_a_a = vertices_a[i_a]
            
            for i_b in range(vertices_b.size() - 1):
                vertex_b_a = vertices_b[i_b]
                vertex_b_b = vertices_b[i_b + 1]
                
                if expanded_bounding_box_b.has_point(vertex_a_a) and \
                        Geometry.get_distance_squared_from_point_to_segment( \
                                vertex_a_a, vertex_b_a, vertex_b_b) <= distance_squared_threshold:
                    return true
            
            # Handle the degenerate case of single-vertex surfaces.
            if vertices_b.size() == 1:
                if vertex_a_a.distance_squared_to(vertices_b[0]) <= distance_squared_threshold:
                    return true
    
    return false

# Gets the closest surface that can be reached by falling from the given point.
static func _get_closest_fallable_surface(start: Vector2, player_movement: PlayerMovement, \
        surfaces: Array, can_use_horizontal_distance := false) -> Surface:
    var end_x_distance = DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING * \
            player_movement.movement_params.max_horizontal_speed_default / \
            player_movement.movement_params.max_vertical_speed
    var end_y = start.y + DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING
    
    if can_use_horizontal_distance:
        var start_x_distance = player_movement.get_max_horizontal_distance()
        
        var leftmost_start = Vector2(start.x - start_x_distance, start.y)
        var rightmost_start = Vector2(start.x + start_x_distance, start.y)
        var leftmost_end = Vector2(leftmost_start.x - end_x_distance, end_y)
        var rightmost_end = Vector2(rightmost_start.x + end_x_distance, end_y)
        
        return _get_closest_fallable_surface_intersecting_polygon(start, \
                PoolVector2Array([leftmost_start, rightmost_start, rightmost_end, leftmost_end]), \
                surfaces)
    else:
        var leftmost_end = Vector2(start.x - end_x_distance, end_y)
        var rightmost_end = Vector2(start.x + end_x_distance, end_y)
        
        return _get_closest_fallable_surface_intersecting_triangle(start, start, leftmost_end, \
                rightmost_end, surfaces)

static func _get_closest_fallable_surface_intersecting_triangle(target: Vector2, \
        triangle_a: Vector2, triangle_b: Vector2, triangle_c: Vector2, surfaces: Array) -> Surface:
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for current_surface in surfaces:
        current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                current_surface.bounding_box)
        if current_distance_squared < closest_distance_squared:
            if Geometry.do_polyline_and_triangle_intersect(current_surface.vertices, \
                    triangle_a, triangle_b, triangle_c):
                # FIXME: LEFT OFF HERE: Calculate instruction set (or determine whether it's not possible)
                current_distance_squared = \
                        Geometry.get_distance_squared_from_point_to_polyline( \
                                target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                        closest_distance_squared = current_distance_squared
                        closest_surface = current_surface
    
    return closest_surface

static func _get_closest_fallable_surface_intersecting_polygon(target: Vector2, \
        polygon: PoolVector2Array, surfaces: Array) -> Surface:
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for current_surface in surfaces:
        current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                current_surface.bounding_box)
        if current_distance_squared < closest_distance_squared:
            if Geometry.do_polyline_and_polygon_intersect(current_surface.vertices, polygon):
                # FIXME: LEFT OFF HERE: Calculate instruction set (or determine whether it's not possible)
                current_distance_squared = \
                        Geometry.get_distance_squared_from_point_to_polyline( \
                                target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                        closest_distance_squared = current_distance_squared
                        closest_surface = current_surface
    
    return closest_surface
