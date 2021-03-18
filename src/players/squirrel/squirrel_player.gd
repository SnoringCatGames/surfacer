extends Player
class_name SquirrelPlayer

const TILE_MAP_COLLISION_LAYER := 7
const SQUIRREL_SPAWN_COLLISION_MARGIN := 1.0
const SQUIRREL_SPAWN_LEVEL_OUTER_MARGIN := 256.0
const CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD := 512.0 * 512.0
const SQUIRREL_TRIGGER_NEW_NAVIGATION_INTERVAL_SEC := 3.0

var was_cat_close_last_frame := false
var previous_destination := \
        MovementUtils.create_position_without_surface(Vector2.INF)

func _init().("squirrel") -> void:
    pass

func _process_sfx() -> void:
    if just_triggered_jump:
        Audio.play_sound("squirrel_jump")
    
    if surface_state.just_left_air:
        Audio.play_sound("squirrel_land")

func _ready() -> void:
    if is_fake:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    Time.set_timeout( \
            funcref(self, "_trigger_new_navigation_recurring"), \
            SQUIRREL_TRIGGER_NEW_NAVIGATION_INTERVAL_SEC)

func _trigger_new_navigation_recurring() -> void:
    if is_human_player:
        return
    
    if !navigator.is_currently_navigating:
        _start_new_navigation()
    Time.set_timeout( \
            funcref(self, "_trigger_new_navigation_recurring"), \
            SQUIRREL_TRIGGER_NEW_NAVIGATION_INTERVAL_SEC)

func _update_navigator(delta_sec: float) -> void:
    if is_human_player:
        return
    
    var cat_position: Vector2 = SurfacerConfig.current_player_for_clicks.position
    var is_cat_close := \
            self.position.distance_squared_to(cat_position) <= \
            CAT_IS_CLOSE_DISTANCE_SQUARED_THRESHOLD
    
    if is_cat_close and \
            (!was_cat_close_last_frame or \
            navigator.reached_destination):
        _start_new_navigation()
    
    was_cat_close_last_frame = is_cat_close
    
    ._update_navigator(delta_sec)

func _start_new_navigation() -> void:
    Profiler.start(ProfilerMetric.START_NEW_SQUIRREL_NAVIGATION)
    
    var possible_destinations: Array = \
            ScaffoldConfig.level.squirrel_destinations
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
    
    var duration: float = \
            Profiler.stop(ProfilerMetric.START_NEW_SQUIRREL_NAVIGATION)
    print_msg(("SQUIRREL NEW NAV    ;" + \
            "%8.3fs; " + \
            "calc duration=%sms"), [ \
        Time.elapsed_play_time_actual_sec, \
        duration, \
    ])
