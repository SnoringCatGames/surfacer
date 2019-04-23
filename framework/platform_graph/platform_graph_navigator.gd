extends Reference
class_name PlatformGraphNavigator

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD = 512
const DOWNWARD_DISTANCE_TO_CHECK_FOR_FALLING = 10000

var player # TODO: Add type back
var surface_state: PlayerSurfaceState
var nodes: PlatformGraphNodes
var edges: PlatformGraphEdges

var _stopwatch: Stopwatch

var is_currently_navigating := false
var reached_destination := false
var current_path: PlatformGraphPath
var current_edge: PlatformGraphEdge
var current_edge_index := -1

var just_collided_unexpectedly := false
var just_entered_air_unexpectedly := false
var just_landed_on_expected_surface := false
var just_interrupted_navigation := false
var just_reached_start_of_edge := false

# FIXME: Remove
# Array<Surface>
var nearby_surfaces: Array

func _init(player, graph: PlatformGraph) -> void:
    self.player = player
    surface_state = player.surface_state
    nodes = graph.nodes
    edges = graph.edges[player.player_name]
    _stopwatch = Stopwatch.new()

# Starts a new navigation to the given destination.
func start_new_navigation(target: Vector2) -> void:
    assert(surface_state.is_grabbing_a_surface) # FIXME: Remove
    
    var origin := surface_state.player_center_position_along_surface
    var destination := _find_closest_position_on_a_surface(target)
    var path := _calculate_path(origin, destination)
    
    current_path = path
    current_edge_index = 0
    current_edge = current_path.edges[current_edge_index]
    is_currently_navigating = true
    reached_destination = false

func reset() -> void:
    current_path = null
    current_edge_index = -1
    current_edge = null
    is_currently_navigating = false

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
    if !is_currently_navigating:
        return
    
    var is_grabbed_surface_expected := \
            surface_state.grabbed_surface == current_edge.end.surface
    just_collided_unexpectedly = \
            !is_grabbed_surface_expected and player.get_slide_count() > 0
    just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !just_reached_start_of_edge
    just_landed_on_expected_surface = surface_state.just_left_air and \
            surface_state.grabbed_surface == current_edge.end.surface
    just_interrupted_navigation = just_collided_unexpectedly or just_entered_air_unexpectedly
    # FIXME: Add logic to detect when we've reached the target PositionAlongSurface when moving within node.
    just_reached_start_of_edge = false
    
    if just_interrupted_navigation:
        print("PlatformGraphNavigator: just_interrupted_navigation")
        
        # Re-calculate navigation to the same destination.
        var destination = current_path.end_instructions_destination if \
                current_path.has_end_instructions else \
                current_path.surface_destination.target_point
#        start_new_navigation(destination) # FIXME: Add back in after implementing edge calculations and executions
    
    elif just_reached_start_of_edge:
        print("PlatformGraphNavigator: just_reached_start_of_edge")
        
        reached_destination = current_path.edges.size() == current_edge_index + 1
        if reached_destination:
            reset()
        else:
            current_edge_index += 1
            current_edge = current_path.edges[current_edge_index]
            
            # FIXME: Trigger next instruction set
    
    elif just_landed_on_expected_surface:
        print("PlatformGraphNavigator: just_landed_on_expected_surface")
        
        # FIXME: Detect when position is too far from expected.
        # FIXME: Start moving within the surface to the next edge start position.
        pass
    
    elif surface_state.is_grabbing_a_surface:
        print("PlatformGraphNavigator: Moving along a surface")
        
        # FIXME: Continue moving toward next edge.
        pass
    
    else: # Moving through the air.
        print("PlatformGraphNavigator: Moving through the air")
        
        # FIXME: Detect when position is too far from expected.
        # FIXME: Continue executing movement instruction set.
        pass
    
    # FIXME: Remove
    if surface_state.is_grabbing_a_surface:
        if surface_state.just_changed_surface:
            _stopwatch.start()
            print("get_nearby_surfaces...")
            nearby_surfaces = nodes.get_nearby_surfaces(surface_state.grabbed_surface, \
                    SURFACE_CLOSE_DISTANCE_THRESHOLD)
            print("get_nearby_surfaces duration: %sms" % _stopwatch.stop())
    else:
        nearby_surfaces = []

# Finds the Surface the corresponds to the given PlayerSurfaceState.
func calculate_grabbed_surface(surface_state: PlayerSurfaceState) -> Surface:
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord( \
            surface_state.grab_position_tile_map_coord, surface_state.grabbed_tile_map)
    return nodes.get_surface_for_tile(surface_state.grabbed_tile_map, tile_map_index, \
            surface_state.grabbed_side)

func _calculate_path(origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> PlatformGraphPath:
    var edges := []
    # FIXME: Remove
    var edge := PlatformGraphEdge.new(origin, destination, null)
    edges.push_back(edge)
    # FIXME: Use a A* to find the edges.
    return PlatformGraphPath.new(origin, destination, edges)

# Gets all other surfaces that are near the given surface.
func get_nearby_surfaces(target_surface: Surface, distance_threshold: float) -> Array:
    var result := []
    
    _get_nearby_surfaces(target_surface, nodes.floors, distance_threshold, result)
    _get_nearby_surfaces(target_surface, nodes.ceilings, distance_threshold, result)
    _get_nearby_surfaces(target_surface, nodes.left_walls, distance_threshold, result)
    _get_nearby_surfaces(target_surface, nodes.right_walls, distance_threshold, result)
    
    return result

static func _get_nearby_surfaces(target_surface: Surface, other_surfaces: Array, \
        distance_threshold: float, result: Array) -> void:
    for other_surface in other_surfaces:
        if _get_are_surfaces_close(target_surface, other_surface, distance_threshold) and \
                target_surface != other_surface:
            result.push_back(other_surface)

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

# Finds the closest PositionAlongSurface to the given target point.
func _find_closest_position_on_a_surface(target: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    var surface := _get_closest_surface(target)
    position.match_surface_target_and_collider(surface, target, player.collider)
    return position

# Gets the closest surface to the given point.
func _get_closest_surface(target: Vector2, include_ceilings := false) -> Surface:
    var surface_collections := [nodes.floors, nodes.left_walls, nodes.right_walls]
    if include_ceilings:
        surface_collections.push_back(nodes.ceilings)
    
    var closest_surface: Surface
    var closest_distance_squared: float
    var current_distance_squared: float
    
    closest_surface = surface_collections[0][0]
    closest_distance_squared = \
            Geometry.get_distance_squared_from_point_to_polyline(target, closest_surface.vertices)
    
    for surfaces in surface_collections:
        for current_surface in surfaces:
            current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                    current_surface.bounding_box)
            if current_distance_squared < closest_distance_squared:
                current_distance_squared = Geometry.get_distance_squared_from_point_to_polyline( \
                        target, current_surface.vertices)
                if current_distance_squared < closest_distance_squared:
                    closest_distance_squared = current_distance_squared
                    closest_surface = current_surface
    
    return closest_surface

# Gets the closest surface that can be reached by falling from the given point.
func _get_closest_fallable_surface(start: Vector2, player_movement: PlayerMovement, \
        can_use_horizontal_distance := false) -> Surface:
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
                PoolVector2Array([leftmost_start, rightmost_start, rightmost_end, leftmost_end]))
    else:
        var leftmost_end = Vector2(start.x - end_x_distance, end_y)
        var rightmost_end = Vector2(start.x + end_x_distance, end_y)
        
        return _get_closest_fallable_surface_intersecting_triangle(start, start, leftmost_end, \
                rightmost_end)

func _get_closest_fallable_surface_intersecting_triangle(target: Vector2, triangle_a: Vector2, \
        triangle_b: Vector2, triangle_c: Vector2, include_ceilings := false) -> Surface:
    var surface_collections := [nodes.floors, nodes.left_walls, nodes.right_walls]
    if include_ceilings:
        surface_collections.push_back(nodes.ceilings)
    
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for surfaces in surface_collections:
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

func _get_closest_fallable_surface_intersecting_polygon(target: Vector2, \
        polygon: PoolVector2Array, include_ceilings := false) -> Surface:
    var surface_collections := [nodes.floors, nodes.left_walls, nodes.right_walls]
    if include_ceilings:
        surface_collections.push_back(nodes.ceilings)
    
    var closest_surface: Surface
    var closest_distance_squared: float = INF
    var current_distance_squared: float
    
    for surfaces in surface_collections:
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
