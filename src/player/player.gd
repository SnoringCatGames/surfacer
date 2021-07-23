tool
class_name Player, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends KinematicBody2D


export var player_name: String
export(int, LAYERS_2D_PHYSICS) var collision_detection_layers := 0

const GROUP_NAME_HUMAN_PLAYERS := "human_players"
const GROUP_NAME_COMPUTER_PLAYERS := "computer_players"

var movement_params: MovementParams
# Array<EdgeCalculator>
var edge_calculators: Array
# Array<Surface>
var possible_surfaces_set: Dictionary

var is_human_player := false
var is_fake := false
var _is_initialized := false
var _is_destroyed := false
var _is_navigator_initialized := false
var _is_ready := false

var _configuration_warning := ""

var velocity := Vector2.ZERO

var just_triggered_jump := false
var is_rising_from_jump := false
var jump_count := 0

var did_move_last_frame := false

var current_max_horizontal_speed: float
var _can_dash := true

var _actions_from_previous_frame := PlayerActionState.new()
var actions := PlayerActionState.new()
var surface_state := PlayerSurfaceState.new()
var navigation_state: PlayerNavigationState

var new_selection: PointerSelectionPosition
var last_selection: PointerSelectionPosition
var pre_selection: PointerSelectionPosition

var graph: PlatformGraph
var surface_parser: SurfaceParser
var navigator: Navigator
var level
var collider: CollisionShape2D
var animator: PlayerAnimator
var prediction: PlayerPrediction
var pointer_listener: PlayerPointerListener

# Array<PlayerActionSource>
var _action_sources := []
# Dictionary<String, bool>
var _previous_actions_this_frame := {}
# Array<PlayerActionHandler>
var _action_handlers: Array

var _dash_cooldown_timeout: int
var _dash_fade_tween: ScaffolderTween

var _extra_collision_detection_area: Area2D
# Dictionary<String, Area2D>
var _layers_for_entered_proximity_detection := {}
# Dictionary<String, Area2D>
var _layers_for_exited_proximity_detection := {}


func _init(player_name: String) -> void:
    self.player_name = player_name
    
    self.level = Sc.level
    
    var player_params: PlayerParams = Su.player_params[player_name]
    self.movement_params = player_params.movement_params
    self.current_max_horizontal_speed = \
            player_params.movement_params.max_horizontal_speed_default
    self.edge_calculators = player_params.edge_calculators
    self._action_handlers = player_params.action_handlers
    
    self.new_selection = PointerSelectionPosition.new(self)
    self.last_selection = PointerSelectionPosition.new(self)
    self.pre_selection = PointerSelectionPosition.new(self)


func _enter_tree() -> void:
    _update_editor_configuration()


func _ready() -> void:
    if is_fake:
        # Fake players are only used for testing potential collisions under the
        # hood.
        return
    
    _configure_children_from_scene()
    
    var collision_detection_layer_names := \
            Sc.utils.get_physics_layer_names_from_bitmask(
                    collision_detection_layers)
    for layer_name in collision_detection_layer_names:
        _add_layer_for_collision_detection(layer_name)
    
    if movement_params.bypasses_runtime_physics:
        set_collision_mask_bit(
                Su.WALLS_AND_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT, false)
    
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


func add_child(child: Node, legible_unique_name := false) -> void:
    .add_child(child, legible_unique_name)
    _update_editor_configuration()


func remove_child(child: Node) -> void:
    .remove_child(child)
    _update_editor_configuration()


func _update_editor_configuration() -> void:
    if !Engine.editor_hint:
        return
    
    # Get MovementParams from scene configuration.
    var movement_params_matches: Array = Sc.utils.get_children_by_type(
            self,
            MovementParams)
    if movement_params_matches.size() > 1:
        _configuration_warning = \
                "Must only define a single MovementParams child node."
        update_configuration_warning()
        return
    elif movement_params_matches.size() < 1:
        _configuration_warning = "Must define a MovementParams child node."
        update_configuration_warning()
        return
    var movement_params: MovementParams = movement_params_matches[0]
    
    # FIXME: ------------------------------------- Verify this works.
    # Record the collision shape on the movement_params scene.
    var collision_shape_matches: Array = Sc.utils.get_children_by_type(
            self,
            CollisionShape2D)
    if collision_shape_matches.size() == 1:
        var collision_shape: CollisionShape2D = collision_shape_matches[0]
        movement_params.collider_shape = collision_shape.shape
        movement_params.collider_rotation = collision_shape.rotation
    
    _configuration_warning = ""
    update_configuration_warning()


func _get_configuration_warning() -> String:
    return _configuration_warning


func _configure_children_from_scene() -> void:
    # Get MovementParams from scene configuration.
    movement_params = Sc.utils.get_child_by_type(self, MovementParams)
    
    # Get ProximityDetectors from scene configuration.
    for detector in Sc.utils.get_children_by_type(self, ProximityDetector):
        if detector.is_detecting_enter:
            _add_layer_for_entered_shape_proximity_detection(
                    detector.get_layer_names(),
                    detector.shape,
                    detector.rotation)
        if detector.is_detecting_exit:
            _add_layer_for_exited_shape_proximity_detection(
                    detector.get_layer_names(),
                    detector.shape,
                    detector.rotation)


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
    _action_sources.push_back(UserActionSource.new(self, true))


func _init_navigator() -> void:
    navigator = Navigator.new(self, graph)
    navigation_state = navigator.navigation_state
    _action_sources.push_back(navigator.instructions_action_source)


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
        actions.copy(_actions_from_previous_frame)
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
    _actions_from_previous_frame.copy(actions)
    
    # Clear actions for the current frame.
    actions.clear()
    
    # Update actions for the current frame.
    for action_source in _action_sources:
        action_source.update(
                actions,
                _actions_from_previous_frame,
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
    
    for action_handler in _action_handlers:
        var is_action_relevant_for_surface: bool = \
                action_handler.type == surface_state.surface_type or \
                action_handler.type == SurfaceType.OTHER
        var is_action_relevant_for_physics_mode: bool = \
                !movement_params.bypasses_runtime_physics or \
                !action_handler.uses_runtime_physics
        if is_action_relevant_for_surface and \
                is_action_relevant_for_physics_mode:
            _previous_actions_this_frame[action_handler.name] = \
                    action_handler.process(self)


func _process_animation() -> void:
    match surface_state.surface_type:
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


func get_current_animation_state(result: PlayerAnimationState) -> void:
    result.player_position = position
    result.animation_type = animator.get_current_animation_type()
    result.animation_position = \
            animator.animation_player.current_animation_position
    result.facing_left = surface_state.horizontal_facing_sign == -1


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


# FIXME: ---------------------------------
# # Thoughts for high-level navigation behavior:
# 
# - New Player sub-classes:
#   - walk/climb back and forth
#     - surface ends or with a given range
#     - with a given pause time (or a min/max to randomly pick from)
#     - optionally jump/climb across nearby surfaces?
#   - jump back and forth
#     - surface ends or with a given range
#     - with a given pause time (or a min/max to randomly pick from)
#     - optionally jump/climb across nearby surfaces?
#   - walk/climb along connected surfaces
#     - with a given max speed
#   - randomly select destinations within range
# 
# 
# - follow target player (or nearest player of group)
#   - configure stopping and starting distance for close-enough
#   - configure stopping and starting distance for too-far
# - collide target player (or nearest player of group)
#   - only collide jumping down onto?
#   - only collide while at a higher center position?
#   - only collide while facing?
#   - configure stopping and starting distance for too-far
# - avoid players of group
#   - configure stopping and starting distance
#   - configure stopping and starting distance for too-far
# 
# - custom
# 
# - Some general params:
#   - throttle delay before re-calculating decisions
#     - also, don't re-calculate until landing?
#   - 


# Uses physics layers and an auxiliary Area2D to detect collisions with areas
# and objects.
func _add_layer_for_collision_detection(layer_name_or_names) -> void:
    # Create the Area2D if it doesn't exist yet.
    if !is_instance_valid(_extra_collision_detection_area):
        _extra_collision_detection_area = _add_detection_area(
                movement_params.collider_shape,
                movement_params.collider_rotation,
                "_on_started_colliding",
                "_on_stopped_colliding")
    _enable_layer(layer_name_or_names, _extra_collision_detection_area)


func _remove_layer_for_collision_detection(layer_name_or_names) -> void:
    if !is_instance_valid(_extra_collision_detection_area):
        return
    
    _disable_layer(layer_name_or_names, _extra_collision_detection_area)
    
    # Destroy the Area2D if it is no longer listening to anything.
    if _extra_collision_detection_area.collision_mask == 0:
        _extra_collision_detection_area.queue_free()
        _extra_collision_detection_area = null


func _add_layer_for_entered_radius_proximity_detection(
        layer_name_or_names,
        radius: float) -> void:
    var shape := CircleShape2D.new()
    shape.radius = radius
    _add_layer_for_entered_shape_proximity_detection(
            layer_name_or_names,
            shape,
            0.0)


func _add_layer_for_exited_radius_proximity_detection(
        layer_name_or_names,
        radius: float) -> void:
    var shape := CircleShape2D.new()
    shape.radius = radius
    _add_layer_for_exited_shape_proximity_detection(
            layer_name_or_names,
            shape,
            0.0)


func _add_layer_for_entered_shape_proximity_detection(
        layer_name_or_names,
        detection_shape: Shape2D,
        detection_shape_rotation: float) -> void:
    var area := _add_detection_area(
            detection_shape,
            detection_shape_rotation,
            "_on_entered_proximity",
            "")
    _enable_layer(layer_name_or_names, area)
    
    var layer_names := \
            [layer_name_or_names] if \
            layer_name_or_names is String else \
            layer_name_or_names
    for layer_name in layer_names:
        _layers_for_entered_proximity_detection[layer_name] = area


func _add_layer_for_exited_shape_proximity_detection(
        layer_name_or_names,
        detection_shape: Shape2D,
        detection_shape_rotation: float) -> void:
    var area := _add_detection_area(
            detection_shape,
            detection_shape_rotation,
            "",
            "_on_exited_proximity")
    _enable_layer(layer_name_or_names, area)
    
    var layer_names := \
            [layer_name_or_names] if \
            layer_name_or_names is String else \
            layer_name_or_names
    for layer_name in layer_names:
        _layers_for_exited_proximity_detection[layer_name] = area


func _remove_layer_for_proximity_detection(layer_name_or_names) -> void:
    var layer_names := \
            [layer_name_or_names] if \
            layer_name_or_names is String else \
            layer_name_or_names
    for layer_name in layer_names:
        if _layers_for_entered_proximity_detection.has(layer_name):
            var area: Area2D = \
                    _layers_for_entered_proximity_detection[layer_name]
            if is_instance_valid(area):
                area.queue_free()
            _layers_for_entered_proximity_detection.erase(layer_name)
        
        if _layers_for_exited_proximity_detection.has(layer_name):
            var area: Area2D = \
                    _layers_for_exited_proximity_detection[layer_name]
            if is_instance_valid(area):
                area.queue_free()
            _layers_for_exited_proximity_detection.erase(layer_name)


func _on_detection_area_enter_exit(
        target,
        callback_name: String,
        detection_area: Area2D) -> void:
    # Ignore any events that are triggered at invalid times.
    if _is_destroyed or \
            is_fake or \
            !Sc.level_session.has_started:
        return
    
    # Get a list of the collision-layer names that are matched between the
    # given detector and detectee.
    var shared_bits: int = \
            target.collision_layer & detection_area.collision_mask
    var layer_names: Array = \
            Sc.utils.get_physics_layer_names_from_bitmask(shared_bits)
    assert(!layer_names.empty())
    
    self.call(callback_name, target, layer_names)


func _on_started_colliding(target: Node2D, layer_names: Array) -> void:
    pass


func _on_stopped_colliding(target: Node2D, layer_names: Array) -> void:
    pass


func _on_entered_proximity(target: Node2D, layer_names: Array) -> void:
    pass


func _on_exited_proximity(target: Node2D, layer_names: Array) -> void:
    pass


func _add_detection_area(
        detection_shape: Shape2D,
        detection_shape_rotation: float,
        enter_callback_name: String,
        exit_callback_name: String) -> Area2D:
    var area := Area2D.new()
    area.monitoring = true
    area.monitorable = false
    area.collision_layer = 0
    area.collision_mask = 0
    
    if enter_callback_name != "":
        area.connect(
                "area_entered",
                self,
                "_on_detection_area_enter_exit",
                [enter_callback_name, area])
        area.connect(
                "body_entered",
                self,
                "_on_detection_area_enter_exit",
                [enter_callback_name, area])
    if exit_callback_name != "":
        area.connect(
                "area_exited",
                self,
                "_on_detection_area_enter_exit",
                [enter_callback_name, area])
        area.connect(
                "body_exited",
                self,
                "_on_detection_area_enter_exit",
                [enter_callback_name, area])
    
    var collision_shape := CollisionShape2D.new()
    collision_shape.shape = detection_shape
    collision_shape.rotation = detection_shape_rotation
    
    area.add_child(collision_shape)
    self.add_child(area)
    
    return area


func _enable_layer(
        layer_name_or_names,
        area: Area2D) -> void:
    assert(layer_name_or_names is String or \
            layer_name_or_names is Array)
    var layer_names := \
            [layer_name_or_names] if \
            layer_name_or_names is String else \
            layer_name_or_names
    
    for layer_name in layer_names:
        # Enable the bit for this layer.
        var layer_bit_mask: int = \
                Sc.utils.get_physics_layer_bitmask_from_name(layer_name)
        area.collision_mask |= layer_bit_mask


func _disable_layer(
        layer_name_or_names,
        area: Area2D) -> void:
    assert(layer_name_or_names is String or \
            layer_name_or_names is Array)
    var layer_names := \
            [layer_name_or_names] if \
            layer_name_or_names is String else \
            layer_name_or_names
    
    for layer_name in layer_names:
        # Disable the bit for this layer.
        var layer_bit_mask: int = \
                Sc.utils.get_physics_layer_bitmask_from_name(layer_name)
        area.collision_mask &= ~layer_bit_mask
