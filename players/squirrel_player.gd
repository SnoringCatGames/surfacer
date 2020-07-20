extends Player
class_name SquirrelPlayer

const TILE_MAP_COLLISION_LAYER := 7
const SQUIRREL_SPAWN_COLLISION_MARGIN := 1.0
const SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN := 256.0
const CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD := 512.0 * 512.0

var level_bounds: Rect2

var was_cat_close_last_frame := false
var previous_destination := \
        MovementUtils.create_position_without_surface(Vector2.INF)

func _init().("squirrel") -> void:
    level_bounds = Global.current_level.surface_parser.combined_tile_map_rect \
            .grow(-SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN)

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
        print_msg(("SQUIRREL NEW NAV    ;" + \
                "%8.3fs; " + \
                "calc duration=%sms"), [ \
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
