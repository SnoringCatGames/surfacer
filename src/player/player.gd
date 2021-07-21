class_name Player
extends KinematicBody2D


const GROUP_NAME_HUMAN_PLAYERS := "human_players"
const GROUP_NAME_COMPUTER_PLAYERS := "computer_players"

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
var pointer_listener: PlayerPointerListener

var new_selection: PointerSelectionPosition
var last_selection: PointerSelectionPosition
var pre_selection: PointerSelectionPosition

var is_human_player := false
var is_fake := false
var _is_initialized := false
var _is_destroyed := false
var _is_navigator_initialized := false
var _is_ready := false

var graph: PlatformGraph
var surface_parser: SurfaceParser
var navigator: Navigator
var velocity := Vector2.ZERO
var level
var collider: CollisionShape2D
var animator: PlayerAnimator
var prediction: PlayerPrediction
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

var did_move_last_frame := false

var current_max_horizontal_speed: float
var _can_dash := true
var _dash_cooldown_timeout: int
var _dash_fade_tween: ScaffolderTween


func _init(player_name: String) -> void:
    self.player_name = player_name
    
    self.level = Sc.level
    
    var player_params: PlayerParams = Su.player_params[player_name]
    self.can_grab_walls = player_params.movement_params.can_grab_walls
    self.can_grab_ceilings = player_params.movement_params.can_grab_ceilings
    self.can_grab_floors = player_params.movement_params.can_grab_floors
    self.movement_params = player_params.movement_params
    self.current_max_horizontal_speed = \
            player_params.movement_params.max_horizontal_speed_default
    self.edge_calculators = player_params.edge_calculators
    self.action_handlers = player_params.action_handlers
    
    self.new_selection = PointerSelectionPosition.new(self)
    self.last_selection = PointerSelectionPosition.new(self)
    self.pre_selection = PointerSelectionPosition.new(self)


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
    assert(Sc.geometry.do_shapes_match(
            collider_shape,
            movement_params.collider_shape))
    var transform := shape_owner_get_transform(owner_id)
    assert(abs(transform.get_rotation() - \
            movement_params.collider_rotation) < Sc.geometry.FLOAT_EPSILON)
    
    if movement_params.bypasses_runtime_physics:
        set_collision_mask_bit(
                Su.WALLS_AND_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT, false)
    
    # Ensure we use the actual Shape2D reference that is used by Godot's
    # collision system.
    movement_params.collider_shape = collider_shape
    
#    shape_owner_clear_shapes(owner_id)
#    shape_owner_add_shape(owner_id, movement_params.collider_shape)
    
    self.pointer_listener = PlayerPointerListener.new(self)
    add_child(pointer_listener)
    
    var animators: Array = Sc.utils.get_children_by_type(
            self,
            PlayerAnimator)
    assert(animators.size() <= 1)
    if animators.empty():
        animator = Sc.utils.add_scene(
                self,
                movement_params.animator_params.player_animator_path_or_scene)
    else:
        animator = animators[0]
    animator.set_up(self, true)
    
    if Su.annotators.is_annotator_enabled(
            AnnotatorType.PATH_PRESELECTION) and \
            (is_human_player and Su.is_human_prediction_shown or \
            !is_human_player and Su.is_computer_prediction_shown):
        prediction = PlayerPrediction.new()
        prediction.set_up(self)
    
    # Set up a Tween for the fade-out at the end of a dash.
    _dash_fade_tween = ScaffolderTween.new()
    add_child(_dash_fade_tween)
    
    # Start facing the right.
    surface_state.horizontal_facing_sign = 1
    animator.face_right()
    
    _is_ready = true
    _check_for_initialization_complete()
    
    surface_state.previous_center_position = self.position
    surface_state.center_position = self.position
    
    Sc.device.connect(
            "display_resized",
            self,
            "_on_resized")
    _on_resized()


func _on_annotators_ready() -> void:
    if is_instance_valid(prediction):
        Su.annotators.path_preselection_annotator \
                .add_prediction(prediction)


func _destroy() -> void:
    _is_destroyed = true
    if is_instance_valid(prediction):
        prediction.queue_free()
    if is_instance_valid(animator):
        animator._destroy()
    if !is_queued_for_deletion():
        queue_free()


func _unhandled_input(event: InputEvent) -> void:
    if _is_initialized and \
            !_is_destroyed and \
            Sc.gui.is_user_interaction_enabled and \
            navigator.is_currently_navigating and \
            event is InputEventKey:
        navigator.stop()


func _on_resized() -> void:
    Sc.camera_controller._on_resized()


func init_human_player_state() -> void:
    is_human_player = true
    # Only a single, user-controlled player should have a camera.
    _set_camera()
    _init_navigator()
    _init_user_controller_action_source()
    _is_navigator_initialized = true
    _check_for_initialization_complete()


func init_computer_player_state() -> void:
    is_human_player = false
    _init_navigator()
    _is_navigator_initialized = true
    _check_for_initialization_complete()


func set_platform_graph(graph: PlatformGraph) -> void:
    self.graph = graph
    self.surface_parser = graph.surface_parser
    self.possible_surfaces_set = graph.surfaces_set
    _check_for_initialization_complete()


func _check_for_initialization_complete() -> void:
    self._is_initialized = \
            graph != null and \
            _is_navigator_initialized and \
            _is_ready


func _set_camera() -> void:
    var camera := Camera2D.new()
    camera.smoothing_enabled = true
    camera.smoothing_speed = Sc.gui.camera_smoothing_speed
    add_child(camera)
    # Register the current camera, so it's globally accessible.
    Sc.camera_controller.set_current_camera(camera, self)


func _init_user_controller_action_source() -> void:
    action_sources.push_back(UserActionSource.new(self, true))


func _init_navigator() -> void:
    navigator = Navigator.new(self, graph)
    navigation_state = navigator.navigation_state
    action_sources.push_back(navigator.instructions_action_source)


func _physics_process(delta: float) -> void:
    if is_fake or \
            !_is_initialized or \
            _is_destroyed:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    var delta_scaled: float = Sc.time.scale_delta(delta)
    
    _update_actions(delta_scaled)
    _update_surface_state()
    _handle_pointer_selections()
    
    if surface_state.just_left_air:
        print_msg("GRABBED    :%8s;%8.3fs;P%29s;V%29s; %s", [
                player_name,
                Sc.time.get_play_time(),
                surface_state.center_position,
                velocity,
                surface_state.grabbed_surface.to_string(),
            ])
    elif surface_state.just_entered_air:
        print_msg("LAUNCHED   :%8s;%8.3fs;P%29s;V%29s; %s", [
                player_name,
                Sc.time.get_play_time(),
                surface_state.center_position,
                velocity,
                surface_state.previous_grabbed_surface.to_string(),
            ])
    elif surface_state.just_touched_a_surface:
        var side_str: String
        if surface_state.is_touching_floor:
            side_str = "FLOOR"
        elif surface_state.is_touching_ceiling:
            side_str = "CEILING"
        else:
            side_str = "WALL"
        print_msg("TOUCHED    :%8s;%8.3fs;P%29s;V%29s; %s", [
                player_name,
                Sc.time.get_play_time(),
                surface_state.center_position,
                velocity,
                side_str,
            ])
    
    _update_navigator(delta_scaled)
    
    actions.delta_scaled = delta_scaled
    actions.log_new_presses_and_releases(
            self, Sc.time.get_play_time())
    
    # Flip the horizontal direction of the animation according to which way the
    # player is facing.
    if surface_state.horizontal_facing_sign == 1:
        animator.face_right()
    elif surface_state.horizontal_facing_sign == -1:
        animator.face_left()
    
    _process_actions()
    _process_animation()
    _process_sounds()
    _update_collision_mask()
    
    if !movement_params.bypasses_runtime_physics:
        # Since move_and_slide automatically accounts for delta, we need to
        # compensate for that in order to support our modified framerate.
        var modified_velocity: Vector2 = velocity * Sc.time.get_combined_scale()
        
        # TODO: Use the remaining pre-collision movement that move_and_slide
        #       returns. This might be needed in order to move along slopes?
        move_and_slide(
                modified_velocity,
                Sc.geometry.UP,
                false,
                4,
                Sc.geometry.FLOOR_MAX_ANGLE)
        surface_state.collision_count = get_slide_count()
    
    surface_state.previous_center_position = surface_state.center_position
    surface_state.center_position = self.position
    
    did_move_last_frame = \
            surface_state.previous_center_position != \
            surface_state.center_position
    if did_move_last_frame:
        pointer_listener.on_player_moved()


func _update_navigator(delta_scaled: float) -> void:
    navigator.update()
    
    # TODO: There's probably a more efficient way to do this.
    if navigator.actions_might_be_dirty:
        actions.copy(actions_from_previous_frame)
        _update_actions(delta_scaled)
        _update_surface_state(true)


func _handle_pointer_selections() -> void:
    if new_selection.get_has_selection():
        print_msg("NEW POINTER SELECTION:%8s;%8.3fs;P%29s; %s", [
                player_name,
                Sc.time.get_play_time(),
                str(new_selection.pointer_position),
                new_selection.navigation_destination.to_string() if \
                new_selection.get_is_selection_navigatable() else \
                "[No matching surface]"
            ])
        
        if new_selection.get_is_selection_navigatable():
            last_selection.copy(new_selection)
            navigator.navigate_path(last_selection.path)
            Sc.audio.play_sound("nav_select_success")
        else:
            print_msg("TARGET IS TOO FAR FROM ANY SURFACE")
            Sc.audio.play_sound("nav_select_fail")
        
        new_selection.clear()
        pre_selection.clear()


func _update_actions(delta_scaled: float) -> void:
    # Record actions for the previous frame.
    actions_from_previous_frame.copy(actions)
    
    # Clear actions for the current frame.
    actions.clear()
    
    # Update actions for the current frame.
    for action_source in action_sources:
        action_source.update(
                actions,
                actions_from_previous_frame,
                Sc.time.get_scaled_play_time(),
                delta_scaled,
                navigation_state)
    
    actions.start_dash = \
            Sc.level_button_input.is_action_just_pressed("dash") and \
            movement_params.can_dash and \
            _can_dash


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
        var is_action_relevant_for_surface: bool = \
                action_handler.type == current_action_type or \
                action_handler.type == SurfaceType.OTHER
        var is_action_relevant_for_physics_mode: bool = \
                !movement_params.bypasses_runtime_physics or \
                !action_handler.uses_runtime_physics
        if is_action_relevant_for_surface and \
                is_action_relevant_for_physics_mode:
            _previous_actions_this_frame[action_handler.name] = \
                    action_handler.process(self)


func _process_animation() -> void:
    match current_action_type:
        SurfaceType.FLOOR:
            if actions.pressed_left or actions.pressed_right:
                animator.play(PlayerAnimationType.WALK)
            else:
                animator.play(PlayerAnimationType.REST)
        SurfaceType.WALL:
            if processed_action("WallClimbAction"):
                if actions.pressed_up:
                    animator.play(PlayerAnimationType.CLIMB_UP)
                elif actions.pressed_down:
                    animator.play(PlayerAnimationType.CLIMB_DOWN)
                else:
                    Sc.logger.error()
            else:
                animator.play(PlayerAnimationType.REST_ON_WALL)
        SurfaceType.AIR:
            if velocity.y > 0:
                animator.play(PlayerAnimationType.JUMP_FALL)
            else:
                animator.play(PlayerAnimationType.JUMP_RISE)
        _:
            Sc.logger.error()


func _process_sounds() -> void:
    pass


func processed_action(name: String) -> bool:
    return _previous_actions_this_frame.get(name) == true


func _update_surface_state(preserves_just_changed_state := false) -> void:
    surface_state.update(self, preserves_just_changed_state)


# Update whether or not we should currently consider collisions with
# fall-through floors and walk-through walls.
func _update_collision_mask() -> void:
    set_collision_mask_bit(
            Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT,
            !surface_state.is_falling_through_floors)
    set_collision_mask_bit(
            Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT,
            surface_state.is_grabbing_walk_through_walls)


func start_dash(horizontal_acceleration_sign: int) -> void:
    if !_can_dash or \
            !movement_params.can_dash:
        return
    
    var start_max_speed := \
            movement_params.max_horizontal_speed_default * \
            movement_params.dash_speed_multiplier
    var end_max_speed := movement_params.max_horizontal_speed_default
    var duration: float = \
            movement_params.dash_fade_duration / \
            Sc.time.get_combined_scale()
    var delay: float = \
            (movement_params.dash_duration - 
            movement_params.dash_fade_duration) / \
            Sc.time.get_combined_scale()
    
    current_max_horizontal_speed = start_max_speed
    
    velocity.x = current_max_horizontal_speed * horizontal_acceleration_sign
    velocity.y += movement_params.dash_vertical_boost
    
    _dash_fade_tween.stop_all()
    _dash_fade_tween.interpolate_property(
            self,
            "current_max_horizontal_speed",
            start_max_speed,
            end_max_speed,
            duration,
            "ease_in",
            delay,
            TimeType.PLAY_RENDER_SCALED)
    _dash_fade_tween.start()
    
    Sc.time.clear_timeout(_dash_cooldown_timeout)
    _dash_cooldown_timeout = Sc.time.set_timeout(
            funcref(self, "set"),
            movement_params.dash_cooldown,
            ["_can_dash", true])
    
    if horizontal_acceleration_sign > 0:
        animator.face_right()
    else:
        animator.face_left()
    
    _can_dash = false


# Conditionally prints the given message, depending on the Player's
# configuration.
func print_msg(
        message_template: String,
        message_args = null) -> void:
    if Su.is_surfacer_logging and \
            movement_params.logs_player_actions and \
            (is_human_player or \
                    movement_params.logs_computer_player_events):
        if message_args != null:
            Sc.logger.print(message_template % message_args)
        else:
            Sc.logger.print(message_template)


func set_is_sprite_visible(is_visible: bool) -> void:
    animator.visible = is_visible


func get_is_sprite_visible() -> bool:
    return animator.visible


func set_position(position: Vector2) -> void:
    self.position = position
    surface_state.center_position = position
    surface_state.center_position_along_surface.match_current_grab(
            surface_state.grabbed_surface,
            surface_state.center_position)


func get_intended_position(type: int) -> PositionAlongSurface:
    match type:
        IntendedPositionType.CENTER_POSITION:
            return surface_state.center_position_along_surface if \
                    surface_state.is_grabbing_a_surface else \
                    PositionAlongSurfaceFactory.create_position_without_surface(
                            surface_state.center_position)
        IntendedPositionType.CENTER_POSITION_ALONG_SURFACE:
            return surface_state.center_position_along_surface
        IntendedPositionType.LAST_POSITION_ALONG_SURFACE:
            return surface_state.last_position_along_surface
        IntendedPositionType.CLOSEST_SURFACE_POSITION:
            return SurfaceParser.find_closest_position_on_a_surface(
                    surface_state.center_position, self)
        IntendedPositionType.EDGE_ORIGIN:
            return navigator.edge.start_position_along_surface if \
                    navigator.is_currently_navigating else \
                    null
        IntendedPositionType.EDGE_DESTINATION:
            return navigator.edge.end_position_along_surface if \
                    navigator.is_currently_navigating else \
                    null
        IntendedPositionType.PATH_ORIGIN:
            return navigator.path.origin if \
                    navigator.is_currently_navigating else \
                    null
        IntendedPositionType.PATH_DESTINATION:
            return navigator.path.destination if \
                    navigator.is_currently_navigating else \
                    null
        _:
            Sc.logger.error("Invalid IntendedPositionType: %d" % type)
            return null


func get_current_animation_state(result: PlayerAnimationState) -> void:
    result.player_position = position
    result.animation_type = animator.get_current_animation_type()
    result.animation_position = \
            animator.animation_player.current_animation_position
    result.facing_left = surface_state.horizontal_facing_sign == -1
