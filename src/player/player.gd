class_name Player
extends KinematicBody2D

var player_name: String
var can_grab_walls: bool
var can_grab_ceilings: bool
var can_grab_floors: bool
var movement_params: MovementParams
# Array<EdgeCalculator>
var edge_calculators: Array
# Array<Surface>
var possible_surfaces_set: Dictionary
var actions_from_previous_frame := PlayerActionState.new()
var actions := PlayerActionState.new()
var surface_state := PlayerSurfaceState.new()
var navigation_state: PlayerNavigationState
var pointer_handler: PlayerPointerHandler
var new_selection_target := Vector2.INF
var new_selection_position: PositionAlongSurface
var last_selection_target := Vector2.INF
var last_selection_position: PositionAlongSurface
var preselection_target := Vector2.INF
var preselection_position: PositionAlongSurface

var is_human_player := false
var is_fake := false
var is_initialized := false
var is_navigator_initialized := false
var is_ready := false

var graph: PlatformGraph
var surface_parser: SurfaceParser
var navigator: Navigator
var velocity := Vector2.ZERO
var level
var collider: CollisionShape2D
var animator: PlayerAnimator
# Array<PlayerActionSource>
var action_sources := []
# Dictionary<String, bool>
var _previous_actions_this_frame := {}
# Array<PlayerActionHandler>
var action_handlers: Array
# SurfaceType
var current_action_type: int

var just_triggered_jump := false
var is_rising_from_jump := false
var jump_count := 0

var current_max_horizontal_speed: float
var _can_dash := true
var _dash_cooldown_timer: Timer
var _dash_fade_tween: Tween

func _init(player_name: String) -> void:
    self.player_name = player_name
    
    self.level = Gs.level
    
    var player_params: PlayerParams = Surfacer.player_params[player_name]
    self.can_grab_walls = player_params.movement_params.can_grab_walls
    self.can_grab_ceilings = player_params.movement_params.can_grab_ceilings
    self.can_grab_floors = player_params.movement_params.can_grab_floors
    self.movement_params = player_params.movement_params
    self.current_max_horizontal_speed = \
            player_params.movement_params.max_horizontal_speed_default
    self.edge_calculators = player_params.edge_calculators
    self.action_handlers = player_params.action_handlers

func _enter_tree() -> void:
    if is_fake:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    self.pointer_handler = PlayerPointerHandler.new(self)
    add_child(pointer_handler)

func _ready() -> void:
    if is_fake:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    # TODO: Somehow consolidate how collider shapes are defined?
    
    var shape_owners := get_shape_owners()
    assert(shape_owners.size() == 1)
    var owner_id: int = shape_owners[0]
    assert(shape_owner_get_shape_count(owner_id) == 1)
    var collider_shape := shape_owner_get_shape(owner_id, 0)
    assert(Gs.geometry.do_shapes_match( \
            collider_shape, \
            movement_params.collider_shape))
    var transform := shape_owner_get_transform(owner_id)
    assert(abs(transform.get_rotation() - \
            movement_params.collider_rotation) < Gs.geometry.FLOAT_EPSILON)
    
    # Ensure we use the actual Shape2D reference that is used by Godot's
    # collision system.
    movement_params.collider_shape = collider_shape
    
#    shape_owner_clear_shapes(owner_id)
#    shape_owner_add_shape(owner_id, movement_params.collider_shape)
    
    var animators: Array = Gs.utils.get_children_by_type( \
            self, \
            PlayerAnimator)
    assert(animators.size() <= 1)
    animator = \
            animators[0] if \
            !animators.empty() else \
            FakePlayerAnimator.new()

    # Set up a Tween for the fade-out at the end of a dash.
    _dash_fade_tween = Tween.new()
    add_child(_dash_fade_tween)
    
    # Set up a Timer for the dash cooldown.
    _dash_cooldown_timer = Timer.new()
    _dash_cooldown_timer.one_shot = true
    #warning-ignore:return_value_discarded
    _dash_cooldown_timer.connect( \
            "timeout", \
            self, \
            "_dash_cooldown_finished")
    add_child(_dash_cooldown_timer)
    
    # Start facing the right.
    surface_state.horizontal_facing_sign = 1
    animator.face_right()
    
    is_ready = true
    _check_for_initialization_complete()
    
    surface_state.previous_center_position = self.position
    surface_state.center_position = self.position
    
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _on_resized() -> void:
    Gs.camera_controller.update_zoom()

func init_human_player_state() -> void:
    is_human_player = true
    # Only a single, user-controlled player should have a camera.
    _set_camera()
    _init_navigator()
    _init_user_controller_action_source()
    is_navigator_initialized = true
    _check_for_initialization_complete()

func init_computer_player_state() -> void:
    is_human_player = false
    _init_navigator()
    is_navigator_initialized = true
    _check_for_initialization_complete()

func set_platform_graph(graph: PlatformGraph) -> void:
    self.graph = graph
    self.surface_parser = graph.surface_parser
    self.possible_surfaces_set = graph.surfaces_set
    _check_for_initialization_complete()

func _check_for_initialization_complete() -> void:
    self.is_initialized = \
            graph != null and \
            is_navigator_initialized and \
            is_ready

func _set_camera() -> void:
    var camera := Camera2D.new()
    add_child(camera)
    # Register the current camera, so it's globally accessible.
    Gs.camera_controller.set_current_camera(camera)

func _init_user_controller_action_source() -> void:
    action_sources.push_back(UserActionSource.new(self, true))

func _init_navigator() -> void:
    navigator = Navigator.new(self, graph)
    navigation_state = navigator.navigation_state
    action_sources.push_back(navigator.instructions_action_source)

func _physics_process(delta_sec: float) -> void:
    if is_fake:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    if !is_initialized:
        return
    
    assert(Gs.geometry.are_floats_equal_with_epsilon( \
            delta_sec, \
            Time.PHYSICS_TIME_STEP_SEC))
    
    _update_actions(delta_sec)
    _update_surface_state()
    _handle_pointer_selections()
    
    if surface_state.just_left_air:
        print_msg("GRABBED    :%8s;%8.3fs;P%29s;V%29s; %s", [ \
                player_name, \
                Gs.time.elapsed_play_time_actual_sec, \
                surface_state.center_position, \
                velocity, \
                surface_state.grabbed_surface.to_string(), \
            ])
    elif surface_state.just_entered_air:
        print_msg("LAUNCHED   :%8s;%8.3fs;P%29s;V%29s; %s", [ \
                player_name, \
                Gs.time.elapsed_play_time_actual_sec, \
                surface_state.center_position, \
                velocity, \
                surface_state.previous_grabbed_surface.to_string(), \
            ])
    elif surface_state.just_touched_a_surface:
        var side_str: String
        if surface_state.is_touching_floor:
            side_str = "FLOOR"
        elif surface_state.is_touching_ceiling:
            side_str = "CEILING"
        else:
            side_str = "WALL"
        print_msg("TOUCHED    :%8s;%8.3fs;P%29s;V%29s; %s", [ \
                player_name, \
                Gs.time.elapsed_play_time_actual_sec, \
                surface_state.center_position, \
                velocity, \
                side_str, \
            ])
    
    if navigator:
        _update_navigator(delta_sec)
    
    actions.delta_sec = delta_sec
    actions.log_new_presses_and_releases(self, Gs.time.elapsed_play_time_actual_sec)
    
    # Flip the horizontal direction of the animation according to which way the
    # player is facing.
    if surface_state.horizontal_facing_sign == 1:
        animator.face_right()
    elif surface_state.horizontal_facing_sign == -1:
        animator.face_left()
    
    _process_actions()
    _process_animation()
    _process_sfx()
    _update_collision_mask()
    
    # We don't need to multiply velocity by delta because MoveAndSlide already
    # takes delta time into account.
    # TODO: Use the remaining pre-collision movement that move_and_slide
    #       returns. This might be needed in order to move along slopes?
    move_and_slide( \
            velocity, \
            Gs.geometry.UP, \
            false, \
            4, \
            Gs.geometry.FLOOR_MAX_ANGLE)
    
    surface_state.previous_center_position = surface_state.center_position
    surface_state.center_position = self.position
    surface_state.collision_count = get_slide_count()

func _update_navigator(delta_sec: float) -> void:
    navigator.update()
    
    # TODO: There's probably a more efficient way to do this.
    if navigator.actions_might_be_dirty:
        actions.copy(actions_from_previous_frame)
        _update_actions(delta_sec)
        _update_surface_state(true)

func _handle_pointer_selections() -> void:
    if new_selection_target != Vector2.INF:
        print_msg("NEW POINTER SELECTION:%8s;%8.3fs;P%29s; %s", [ \
                player_name, \
                Gs.time.elapsed_play_time_actual_sec, \
                str(new_selection_target), \
                new_selection_position.to_string() if \
                new_selection_position != null else \
                "[No matching surface]"
            ])
        
        if new_selection_position != null:
            last_selection_target = new_selection_target
            last_selection_position = new_selection_position
            navigator.navigate_to_position(last_selection_position)
        else:
            print_msg("TARGET IS TOO FAR FROM ANY SURFACE")
        
        new_selection_target = Vector2.INF
        new_selection_position = null
        preselection_target = Vector2.INF
        preselection_position = null

func _update_actions(delta_sec: float) -> void:
    # Record actions for the previous frame.
    actions_from_previous_frame.copy(actions)
    
    # Clear actions for the current frame.
    actions.clear()
    
    # Update actions for the current frame.
    for action_source in action_sources:
        action_source.update( \
                actions, \
                actions_from_previous_frame, \
                Gs.time.elapsed_play_time_actual_sec, \
                delta_sec, \
                navigation_state)
    
    actions.start_dash = _can_dash and \
            Gs.level_input.is_action_just_pressed("dash")

# Updates physics and player states in response to the current actions.
func _process_actions() -> void:
    _previous_actions_this_frame.clear()
    
    if surface_state.is_grabbing_wall:
        current_action_type = SurfaceType.WALL
    elif surface_state.is_grabbing_floor:
        current_action_type = SurfaceType.FLOOR
    else:
        current_action_type = SurfaceType.AIR
    
    for action_handler in action_handlers:
        if action_handler.type == current_action_type or \
                action_handler.type == SurfaceType.OTHER:
            _previous_actions_this_frame[action_handler.name] = \
                    action_handler.process(self)

func _process_animation() -> void:
    match current_action_type:
        SurfaceType.FLOOR:
            if actions.pressed_left or actions.pressed_right:
                animator.walk()
            else:
                animator.rest()
        SurfaceType.WALL:
            if processed_action("WallClimbAction"):
                if actions.pressed_up:
                    animator.climb_up()
                elif actions.pressed_down:
                    animator.climb_down()
                else:
                    Gs.utils.error()
            else:
                animator.rest_on_wall()
        SurfaceType.AIR:
            if velocity.y > 0:
                animator.jump_fall()
            else:
                animator.jump_rise()
        _:
            Gs.utils.error()

func _process_sfx() -> void:
    pass

func processed_action(name: String) -> bool:
    return _previous_actions_this_frame.get(name) == true

# Updates some basic surface-related state for player's actions and environment
# of the current frame.
func _update_surface_state(preserves_just_changed_state := false) -> void:
    # Flip the horizontal direction of the animation according to which way the
    # player is facing.
    if actions.pressed_face_right:
        surface_state.horizontal_facing_sign = 1
    elif actions.pressed_face_left:
        surface_state.horizontal_facing_sign = -1
    elif actions.pressed_right:
        surface_state.horizontal_facing_sign = 1
    elif actions.pressed_left:
        surface_state.horizontal_facing_sign = -1
    
    if actions.pressed_right:
        surface_state.horizontal_acceleration_sign = 1
    elif actions.pressed_left:
        surface_state.horizontal_acceleration_sign = -1
    else:
        surface_state.horizontal_acceleration_sign = 0
    
    # Note: These might give false negatives when colliding with a corner.
    #       AFAICT, Godot will simply pick one of the corner's adjacent
    #       segments to base the collision normal off of, so the other segment
    #       will be ignored (and the other segment could correspond to floor or
    #       ceiling).
    surface_state.is_touching_floor = is_on_floor()
    surface_state.is_touching_ceiling = is_on_ceiling()
    surface_state.is_touching_wall = is_on_wall()
    
    surface_state.which_wall = Gs.utils.get_which_wall_collided_for_body(self)
    surface_state.is_touching_left_wall = \
            surface_state.which_wall == SurfaceSide.LEFT_WALL
    surface_state.is_touching_right_wall = \
            surface_state.which_wall == SurfaceSide.RIGHT_WALL
    
    var next_is_touching_a_surface := \
            surface_state.is_touching_floor or \
            surface_state.is_touching_ceiling or \
            surface_state.is_touching_wall
    surface_state.just_touched_a_surface = \
            (preserves_just_changed_state and \
                    surface_state.just_touched_a_surface) or \
            (next_is_touching_a_surface and \
                    !surface_state.is_touching_a_surface)
    surface_state.just_stopped_touching_a_surface = \
            (preserves_just_changed_state and \
                    surface_state.just_stopped_touching_a_surface) or \
            (!next_is_touching_a_surface and \
                    surface_state.is_touching_a_surface)
    surface_state.is_touching_a_surface = next_is_touching_a_surface
    
    # Calculate the sign of a colliding wall's direction.
    surface_state.toward_wall_sign = \
            (0 if !surface_state.is_touching_wall else \
            (1 if surface_state.which_wall == SurfaceSide.RIGHT_WALL else \
            -1))
    
    surface_state.is_facing_wall = \
        (surface_state.which_wall == SurfaceSide.RIGHT_WALL and \
                surface_state.horizontal_facing_sign > 0) or \
        (surface_state.which_wall == SurfaceSide.LEFT_WALL and \
                surface_state.horizontal_facing_sign < 0)
    surface_state.is_pressing_into_wall = \
        (surface_state.which_wall == SurfaceSide.RIGHT_WALL and \
                actions.pressed_right) or \
        (surface_state.which_wall == SurfaceSide.LEFT_WALL and \
                actions.pressed_left)
    surface_state.is_pressing_away_from_wall = \
        (surface_state.which_wall == SurfaceSide.RIGHT_WALL and \
                actions.pressed_left) or \
        (surface_state.which_wall == SurfaceSide.LEFT_WALL and \
                actions.pressed_right)
    
    var facing_into_wall_and_pressing_up: bool = \
            actions.pressed_up and \
            (surface_state.is_facing_wall or \
                    surface_state.is_pressing_into_wall)
    var facing_into_wall_and_pressing_grab: bool = \
            actions.pressed_grab_wall and \
            (surface_state.is_facing_wall or \
                    surface_state.is_pressing_into_wall)
    surface_state.is_triggering_wall_grab = \
            surface_state.is_pressing_into_wall or \
            facing_into_wall_and_pressing_up or \
            facing_into_wall_and_pressing_grab
    
    surface_state.is_triggering_fall_through = \
            actions.pressed_down and actions.just_pressed_jump
    
    # Whether we are grabbing a wall.
    surface_state.is_grabbing_wall = \
            surface_state.is_touching_wall and \
            (surface_state.is_grabbing_wall or \
                    surface_state.is_triggering_wall_grab)
    
    # Whether we should fall through fall-through floors.
    if surface_state.is_grabbing_wall:
        surface_state.is_falling_through_floors = actions.pressed_down
    elif surface_state.is_touching_floor:
        surface_state.is_falling_through_floors = \
                surface_state.is_triggering_fall_through
    else:
        surface_state.is_falling_through_floors = actions.pressed_down
    
    # Whether we should fall through fall-through floors.
    surface_state.is_grabbing_walk_through_walls = \
            surface_state.is_grabbing_wall or actions.pressed_up
    
    surface_state.velocity = velocity
    
    _update_which_side_is_grabbed(preserves_just_changed_state)
    _update_which_surface_is_grabbed(preserves_just_changed_state)

func _update_which_side_is_grabbed( \
        preserves_just_changed_state := false) -> void:
    var next_is_grabbing_floor := false
    var next_is_grabbing_ceiling := false
    var next_is_grabbing_left_wall := false
    var next_is_grabbing_right_wall := false
    
    if surface_state.is_grabbing_wall:
        next_is_grabbing_left_wall = surface_state.is_touching_left_wall
        next_is_grabbing_right_wall = surface_state.is_touching_right_wall
    elif surface_state.is_grabbing_ceiling:
        next_is_grabbing_ceiling = true
    elif surface_state.is_touching_floor:
        next_is_grabbing_floor = true
    
    var next_is_grabbing_a_surface := \
            next_is_grabbing_floor or next_is_grabbing_ceiling or \
            next_is_grabbing_left_wall or next_is_grabbing_right_wall
    
    surface_state.just_grabbed_floor = \
            (preserves_just_changed_state and \
                    surface_state.just_grabbed_floor) or \
            (next_is_grabbing_floor and \
                    !surface_state.is_grabbing_floor)
    surface_state.just_grabbed_ceiling = \
            (preserves_just_changed_state and \
                    surface_state.just_grabbed_ceiling) or \
            (next_is_grabbing_ceiling and \
                    !surface_state.is_grabbing_ceiling)
    surface_state.just_grabbed_left_wall = \
            (preserves_just_changed_state and \
                    surface_state.just_grabbed_left_wall) or \
            (next_is_grabbing_left_wall and \
                    !surface_state.is_grabbing_left_wall)
    surface_state.just_grabbed_right_wall = \
            (preserves_just_changed_state and \
                    surface_state.just_grabbed_right_wall) or \
            (next_is_grabbing_right_wall and \
                    !surface_state.is_grabbing_right_wall)
    surface_state.just_grabbed_a_surface = \
            surface_state.just_grabbed_floor or \
            surface_state.just_grabbed_ceiling or \
            surface_state.just_grabbed_left_wall or \
            surface_state.just_grabbed_right_wall
    
    surface_state.just_entered_air = \
            (preserves_just_changed_state and \
                    surface_state.just_entered_air) or \
            (!next_is_grabbing_a_surface and \
                    surface_state.is_grabbing_a_surface)
    surface_state.just_left_air = \
            (preserves_just_changed_state and \
                    surface_state.just_left_air) or \
            (next_is_grabbing_a_surface and \
                    !surface_state.is_grabbing_a_surface)
    
    surface_state.is_grabbing_floor = next_is_grabbing_floor
    surface_state.is_grabbing_ceiling = next_is_grabbing_ceiling
    surface_state.is_grabbing_left_wall = next_is_grabbing_left_wall
    surface_state.is_grabbing_right_wall = next_is_grabbing_right_wall
    surface_state.is_grabbing_a_surface = next_is_grabbing_a_surface
    
    surface_state.grabbed_side = \
            SurfaceSide.FLOOR if \
                    surface_state.is_grabbing_floor else \
            (SurfaceSide.CEILING if \
                    surface_state.is_grabbing_ceiling else \
            (SurfaceSide.LEFT_WALL if \
                    surface_state.is_grabbing_left_wall else \
            (SurfaceSide.RIGHT_WALL if \
                    surface_state.is_grabbing_right_wall else \
            SurfaceSide.NONE)))
    match surface_state.grabbed_side:
        SurfaceSide.FLOOR:
            surface_state.grabbed_surface_normal = Gs.geometry.UP
        SurfaceSide.CEILING:
            surface_state.grabbed_surface_normal = Gs.geometry.DOWN
        SurfaceSide.LEFT_WALL:
            surface_state.grabbed_surface_normal = Gs.geometry.RIGHT
        SurfaceSide.RIGHT_WALL:
            surface_state.grabbed_surface_normal = Gs.geometry.LEFT

func _update_which_surface_is_grabbed( \
        preserves_just_changed_state := false) -> void:
    var collision := _get_attached_surface_collision( \
            self, \
            surface_state)
    assert((collision != null) == surface_state.is_grabbing_a_surface)
    
    if surface_state.is_grabbing_a_surface:
        var next_grab_position := collision.position
        surface_state.just_changed_grab_position = \
                (preserves_just_changed_state and \
                        surface_state.just_changed_grab_position) or \
                (surface_state.just_left_air or \
                        next_grab_position != surface_state.grab_position)
        surface_state.grab_position = next_grab_position
        
        var next_grabbed_tile_map := collision.collider
        surface_state.just_changed_tile_map = \
                (preserves_just_changed_state and \
                        surface_state.just_changed_tile_map) or \
                (surface_state.just_left_air or \
                        next_grabbed_tile_map != \
                                surface_state.grabbed_tile_map)
        surface_state.grabbed_tile_map = next_grabbed_tile_map
        
        Gs.geometry.get_collision_tile_map_coord( \
                surface_state.collision_tile_map_coord_result, \
                surface_state.grab_position, \
                surface_state.grabbed_tile_map, \
                surface_state.is_touching_floor, \
                surface_state.is_touching_ceiling, \
                surface_state.is_touching_left_wall, \
                surface_state.is_touching_right_wall)
        var next_grab_position_tile_map_coord := \
                surface_state.collision_tile_map_coord_result.tile_map_coord
        if !surface_state.collision_tile_map_coord_result \
                .is_godot_floor_ceiling_detection_correct:
            match surface_state.collision_tile_map_coord_result.surface_side:
                SurfaceSide.FLOOR:
                    surface_state.is_touching_floor = true
                    surface_state.is_grabbing_floor = true
                    surface_state.is_touching_ceiling = false
                    surface_state.is_grabbing_ceiling = false
                    surface_state.just_grabbed_ceiling = false
                    surface_state.grabbed_side = SurfaceSide.FLOOR
                    surface_state.grabbed_surface_normal = Gs.geometry.UP
                SurfaceSide.CEILING:
                    surface_state.is_touching_ceiling = true
                    surface_state.is_grabbing_ceiling = true
                    surface_state.is_touching_floor = false
                    surface_state.is_grabbing_floor = false
                    surface_state.just_grabbed_floor = false
                    surface_state.grabbed_side = SurfaceSide.CEILING
                    surface_state.grabbed_surface_normal = Gs.geometry.DOWN
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    surface_state.is_touching_ceiling = \
                            !surface_state.is_touching_ceiling
                    surface_state.is_touching_floor = \
                            !surface_state.is_touching_floor
                    surface_state.is_grabbing_ceiling = false
                    surface_state.is_grabbing_floor = false
                    surface_state.just_grabbed_floor = false
                    surface_state.just_grabbed_ceiling = false
                _:
                    Gs.utils.error()
        surface_state.just_changed_tile_map_coord = \
                (preserves_just_changed_state and \
                        surface_state.just_changed_tile_map_coord) or \
                (surface_state.just_left_air or \
                        next_grab_position_tile_map_coord != \
                                surface_state.grab_position_tile_map_coord)
        surface_state.grab_position_tile_map_coord = \
                next_grab_position_tile_map_coord
        
        if surface_state.just_changed_tile_map_coord or \
                surface_state.just_changed_tile_map:
            surface_state.grabbed_tile_map_index = \
                    Gs.geometry.get_tile_map_index_from_grid_coord( \
                            surface_state.grab_position_tile_map_coord, \
                            surface_state.grabbed_tile_map)
        
        var next_grabbed_surface := surface_parser.get_surface_for_tile( \
                surface_state.grabbed_tile_map, \
                surface_state.grabbed_tile_map_index, \
                surface_state.grabbed_side)
        surface_state.just_changed_surface = \
                (preserves_just_changed_state and \
                        surface_state.just_changed_surface) or \
                (surface_state.just_left_air or \
                        next_grabbed_surface != surface_state.grabbed_surface)
        if surface_state.just_changed_surface:
            surface_state.previous_grabbed_surface = \
                    surface_state.previous_grabbed_surface if \
                    preserves_just_changed_state else \
                    surface_state.grabbed_surface
        surface_state.grabbed_surface = next_grabbed_surface
        
        surface_state.center_position_along_surface.match_current_grab( \
                surface_state.grabbed_surface, \
                surface_state.center_position)
    
    else:
        if surface_state.just_entered_air:
            surface_state.just_changed_grab_position = true
            surface_state.just_changed_tile_map = true
            surface_state.just_changed_tile_map_coord = true
            surface_state.just_changed_surface = true
            surface_state.previous_grabbed_surface = \
                    surface_state.previous_grabbed_surface if \
                    preserves_just_changed_state else \
                    surface_state.grabbed_surface
        
        surface_state.grab_position = Vector2.INF
        surface_state.grabbed_tile_map = null
        surface_state.grab_position_tile_map_coord = Vector2.INF
        surface_state.grabbed_surface = null
        surface_state.center_position_along_surface.reset()

# Update whether or not we should currently consider collisions with
# fall-through floors and walk-through walls.
func _update_collision_mask() -> void:
    set_collision_mask_bit(1, !surface_state.is_falling_through_floors)
    set_collision_mask_bit(2, surface_state.is_grabbing_walk_through_walls)

static func _get_attached_surface_collision( \
        body: KinematicBody2D, \
        surface_state: PlayerSurfaceState) -> KinematicCollision2D:
    var closest_normal_diff: float = PI
    var closest_collision: KinematicCollision2D
    var current_normal_diff: float
    var current_collision: KinematicCollision2D
    for i in range(surface_state.collision_count):
        current_collision = body.get_slide_collision(i)
        
        if surface_state.is_grabbing_floor:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Gs.geometry.UP))
        elif surface_state.is_grabbing_ceiling:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Gs.geometry.DOWN))
        elif surface_state.is_grabbing_left_wall:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Gs.geometry.RIGHT))
        elif surface_state.is_grabbing_right_wall:
            current_normal_diff = \
                    abs(current_collision.normal.angle_to(Gs.geometry.LEFT))
        else:
            continue
        
        if current_normal_diff < closest_normal_diff:
            closest_normal_diff = current_normal_diff
            closest_collision = current_collision
    
    return closest_collision

func start_dash(horizontal_acceleration_sign: int) -> void:
    if !_can_dash:
        return
    
    current_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default * \
            movement_params.dash_speed_multiplier
    velocity.x = current_max_horizontal_speed * horizontal_acceleration_sign
    
    velocity.y += movement_params.dash_vertical_boost
    
    _dash_cooldown_timer.start(movement_params.dash_cooldown)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.reset_all()
    #warning-ignore:return_value_discarded
    _dash_fade_tween.interpolate_property( \
            self, \
            "current_max_horizontal_speed", \
            movement_params.max_horizontal_speed_default * \
                    movement_params.dash_speed_multiplier, \
            movement_params.max_horizontal_speed_default, \
            movement_params.dash_fade_duration, \
            Tween.TRANS_LINEAR, \
            Tween.EASE_IN, \
            movement_params.dash_duration - movement_params.dash_fade_duration)
    #warning-ignore:return_value_discarded
    _dash_fade_tween.start()
    
    if horizontal_acceleration_sign > 0:
        animator.face_right()
    else:
        animator.face_left()
    
    _can_dash = false

func _dash_cooldown_finished() -> void:
    _can_dash = true

# Conditionally prints the given message, depending on the Player's
# configuration.
func print_msg( \
        message_template: String, \
        message_args = null) -> void:
    if Surfacer.is_logging and \
            movement_params.logs_player_actions and \
            (is_human_player or \
                    movement_params.logs_computer_player_events):
        if message_args != null:
            print(message_template % message_args)
        else:
            print(message_template)
