extends Player
class_name SquirrelPlayer

const TILE_MAP_COLLISION_LAYER := 7
const SQUIRREL_SPAWN_COLLISION_MARGIN := 1.0
const SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN := 256.0
const CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD := 512.0 * 512.0

var level_bounds: Rect2
var shape_query_params: Physics2DShapeQueryParameters

var was_cat_close_last_frame := false
var previous_destination := \
        MovementUtils.create_position_without_surface(Vector2.INF)

func _init().("squirrel") -> void:
    level_bounds = Global.current_level.surface_parser.combined_tile_map_rect \
            .grow(-SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN)
    
    shape_query_params = Physics2DShapeQueryParameters.new()
    shape_query_params.collide_with_areas = false
    shape_query_params.collide_with_bodies = true
    shape_query_params.collision_layer = TILE_MAP_COLLISION_LAYER
    shape_query_params.exclude = []
    shape_query_params.margin = SQUIRREL_SPAWN_COLLISION_MARGIN
    shape_query_params.motion = Vector2.ZERO
    shape_query_params.shape_rid = movement_params.collider_shape.get_rid()
    shape_query_params.transform = Transform2D( \
            movement_params.collider_rotation, \
            Vector2.ZERO)
    shape_query_params.set_shape(movement_params.collider_shape)

func _update_navigator(delta_sec: float) -> void:
    var cat_position: Vector2 = Global.current_player_for_clicks.position
    var is_cat_close := \
            self.position.distance_squared_to(cat_position) <= \
            CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD
    
    if is_cat_close and \
            (!was_cat_close_last_frame or \
            navigator.reached_destination):
        Profiler.start(ProfilerMetric.START_NEW_SQUIRREL_NAVIGATION)
        _start_new_navigation()
        var duration := \
                Profiler.stop(ProfilerMetric.START_NEW_SQUIRREL_NAVIGATION)
        print(("SQUIRREL NEW NAV    ;" + \
                "%8.3fs; " + \
                "calculation duration=%s") % [ \
            Time.elapsed_play_time_sec, \
            duration, \
        ])
    
    was_cat_close_last_frame = is_cat_close
    
    ._update_navigator(delta_sec)

func _start_new_navigation() -> void:
    var possible_destinations: Array = \
            Global.current_level.squirrel_destinations
    var index: int
    var next_destination := previous_destination
    while next_destination.target_point == Vector2.INF or \
            Geometry.are_points_equal_with_epsilon( \
                    next_destination.target_point, \
                    previous_destination.target_point, \
                    128.0):
        index = floor(randf() * possible_destinations.size() - 0.00001)
        next_destination = possible_destinations[index]
    navigator.navigate_to_position(next_destination)
    previous_destination = next_destination

# FIXME: ------------------- This is overkill--remove.
func _calculate_random_position_in_empty_space() -> PositionAlongSurface:
    var space_state: Physics2DDirectSpaceState = \
            Global.current_level.get_world_2d().direct_space_state
    
    # TODO: Implement a more intelligent way to find empty space in the level.
    var point_in_empty_space: Vector2
    var intersects_level := true
    var close_to_cat := true
    var attempts_count := 0
    while intersects_level or close_to_cat:
        point_in_empty_space = _get_random_position_within_bounds(level_bounds)
        
        shape_query_params.transform = Transform2D( \
                movement_params.collider_rotation, \
                point_in_empty_space)
        intersects_level = \
                !space_state.intersect_shape(shape_query_params).empty()
        
        close_to_cat = \
                point_in_empty_space.distance_squared_to( \
                        Global.current_player_for_clicks.position) <= \
                CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD
        
        attempts_count += 1
    
    return SurfaceParser.find_closest_position_on_a_surface( \
            point_in_empty_space, \
            self)

static func _get_random_position_within_bounds(bounds: Rect2) -> Vector2:
    var x := randf() * bounds.size.x + bounds.position.x
    var y := randf() * bounds.size.y + bounds.position.y
    return Vector2(x, y)
