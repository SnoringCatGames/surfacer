tool
class_name SurfacerCharacter, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_character.png"
extends ScaffolderCharacter
## The main character class for Surfacer.[br]
## -   This defines how your character reacts to input and decides when and were
##     to navigate within the level.[br]
## -   You should extend this with a sub-class for your specific character.[br]
## -   You should then attach your sub-class to a scene for your character.[br]
## -   You should then add a few important child scenes:[br]
##     -   MovementParameters[br]
##     -   ScaffolderCharacterAnimator[br]
##     -   CollisionShape2D[br]
##     -   (Optional) ProximityDetector[br]


## -   If true, then the character's movement will include jumps in place of
##     walking, when possible.
export var is_bouncy := false

## If true, then the character sprite rotation will be updated to match the
## current surface-contact normal.
export var rotates_to_match_surface_normal := true

var movement_params: ReadonlyMovementParametersProxy
# Dictionary<Surface, Surface>
var possible_surfaces_set: Dictionary

var reachable_basis_surface: Surface
# Array<Surface>
var reachable_surfaces := []
# Array<Surface>
var reversibly_reachable_surfaces := []

var start_surface: Surface
var start_position_along_surface: PositionAlongSurface
var _start_attachment_surface_side_or_position = null

var just_triggered_jump := false
var is_rising_from_jump := false
var jump_count := 0

var is_dashing: bool setget ,_get_is_dashing

var current_surface_max_horizontal_speed: float \
        setget ,_get_current_surface_max_horizontal_speed
var current_air_max_horizontal_speed: float \
        setget ,_get_current_air_max_horizontal_speed
var current_walk_acceleration: float \
        setget ,_get_current_walk_acceleration
var current_climb_up_speed: float \
        setget ,_get_current_climb_up_speed
var current_climb_down_speed: float \
        setget ,_get_current_climb_down_speed
var current_ceiling_crawl_speed: float \
        setget ,_get_current_ceiling_crawl_speed

var _current_max_horizontal_speed_multiplier := 1.0
var _can_dash := true

var _actions_from_previous_frame := CharacterActionState.new()
var actions := CharacterActionState.new()
var surface_state := CharacterSurfaceState.new(self)
var navigation_state: CharacterNavigationState

# Array<KinematicCollision2DCopy>
var collisions := []

var graph: PlatformGraph
var surface_store: SurfaceStore
var navigator: SurfaceNavigator
var prediction: CharacterPrediction
var touch_listener: PlayerTouchListener

var behavior: Behavior setget _set_behavior

var default_behavior: Behavior
var previous_behavior: Behavior

# Dictionary<Script, Behavior>
var _behaviors_by_class := {}
# Array<Behavior>
var _behaviors_list := []

# Array<CharacterActionSource>
var _action_sources := []
# Dictionary<String, bool>
var _previous_actions_handlers_this_frame := {}

var _player_action_source: PlayerActionSource

var _dash_cooldown_timeout: int
var _dash_fade_tween: ScaffolderTween

var _was_activated_on_touch_down := false

var is_waiting_to_stop_on_surface := false


func _init() -> void:
    self.add_to_group(Sc.characters.GROUP_NAME_CHARACTERS)


func _ready() -> void:
    surface_state.previous_center_position = self.position
    surface_state.center_position = self.position
    
    # Start facing right.
    surface_state.horizontal_facing_sign = 1
    animator.face_right()
    
    if Engine.editor_hint:
        return
    
    if can_be_player_character and \
            !is_instance_valid(_player_action_source):
        _initialize_player_character_functionality()
    
    if movement_params.can_dash:
        # Set up a Tween for the fade-out at the end of a dash.
        _dash_fade_tween = ScaffolderTween.new(self)
    
    if movement_params.bypasses_runtime_physics:
        set_collision_mask_bit(
                Su.WALLS_AND_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT, false)
    
    if Sc.annotators.is_annotator_enabled(
                ScaffolderAnnotatorTypes.PATH_PRESELECTION) and \
            (can_be_player_character and \
                    Sc.annotators.params.is_player_prediction_shown or \
            !can_be_player_character and \
                    Sc.annotators.params.is_npc_prediction_shown):
        prediction = CharacterPrediction.new()
        prediction.set_up(self)
        _attach_prediction()
    
    _init_platform_graph()
    surface_state.update_for_initial_surface_attachment(
            _start_attachment_surface_side_or_position)
    _init_navigator()
    _parse_behavior_children()
    
    # Set up some annotators to help with debugging.
    set_is_sprite_visible(false)
    Sc.annotators.create_character_annotator(self)


func _destroy() -> void:
    if is_instance_valid(prediction):
        prediction.queue_free()
    ._destroy()


func _on_annotators_ready() -> void:
    ._on_annotators_ready()
    _attach_prediction()


func _attach_prediction() -> void:
    if !Sc.levels.session.has_started:
        return
    
    if is_instance_valid(prediction) and \
            is_instance_valid(Sc.annotators.path_preselection_annotator):
        Sc.annotators.path_preselection_annotator.add_prediction(prediction)


func _update_editor_configuration_debounced() -> void:
    ._update_editor_configuration_debounced()
    
    if _configuration_warning != "":
        return
    
    if Engine.editor_hint:
        # Validate MovementParameters from scene configuration.
        var movement_params_matches: Array = Sc.utils.get_children_by_type(
                self,
                MovementParameters)
        if is_instance_valid(category):
            if movement_params_matches.size() > 0:
                _set_configuration_warning(
                        ("Must not define a MovementParameters child node, " +
                        "since this character is registered in a " +
                        "character-category in the app manifest: %s.") % \
                        category.name)
                return
        else:
            if movement_params_matches.size() > 1:
                _set_configuration_warning(
                        "Must only define a single MovementParameters child node.")
                return
            elif movement_params_matches.size() < 1:
                _set_configuration_warning(
                        "Must define a MovementParameters child node.")
                return
        
        # Validate Behaviors from scene configuration.
        var behaviors: Array = \
                Sc.utils.get_children_by_type(self, Behavior)
        var behavior_names := {}
        for behavior in behaviors:
            if behavior_names.has(behavior.behavior_name):
                _set_configuration_warning(
                        ("Must not define more than one Behavior " +
                        "of type %s.") % behavior.behavior_name)
            behavior_names[behavior.behavior_name] = true
            
            var default_behavior: Behavior
            if behavior.is_active_at_start:
                if is_instance_valid(default_behavior):
                    _set_configuration_warning(
                            "Only one Behavior should be marked " +
                            "as `is_active_at_start`.")
                default_behavior = behavior
        if !is_instance_valid(default_behavior):
            _set_configuration_warning(
                    "One Behavior should be marked as " +
                    "`is_active_at_start`.")
    
    _initialize_child_movement_params()
    
    _set_configuration_warning("")


func _initialize_child_movement_params() -> void:
    if is_instance_valid(movement_params):
        return
    
    # Get MovementParameters from the scene configuration.
    var backing_movement_params: MovementParameters = \
        Su.movement.character_movement_params[character_name]
    backing_movement_params.call_deferred("_parse_shape_from_parent")
    
    movement_params = ReadonlyMovementParametersProxy.new()
    add_child(movement_params)
    movement_params.set_backer(backing_movement_params)
    movement_params.call_deferred("_parse_shape_from_parent")


func set_can_be_player_character(value: bool) -> void:
    .set_can_be_player_character(value)
    if can_be_player_character:
        if _is_ready:
            _initialize_player_character_functionality()


func _initialize_player_character_functionality() -> void:
    _init_player_controller_action_source()
    if Su.movement.uses_point_and_click_navigation:
        assert(get_behavior(PlayerNavigationBehavior) == null)
        var player_navigation_behavior := PlayerNavigationBehavior.new()
        add_behavior(player_navigation_behavior)
        
        self.touch_listener = PlayerTouchListener.new(self)
        add_child(touch_listener)


func set_is_player_control_active(
        value: bool,
        should_also_update_level := true) -> void:
    var is_new_activation: bool = \
            value and Sc.level.active_player_character != self
    .set_is_player_control_active(value, should_also_update_level)
    
    if value and !(behavior is PlayerNavigationBehavior):
        get_behavior(PlayerNavigationBehavior).is_active = true
    
    if !value:
        _was_activated_on_touch_down = false
    
    if is_new_activation:
        touch_listener.on_character_player_control_activated(
                _was_activated_on_touch_down)


func _init_player_controller_action_source() -> void:
    assert(!is_instance_valid(_player_action_source))
    self._player_action_source = PlayerActionSource.new(self, true)
    _action_sources.push_back(_player_action_source)


func _init_platform_graph() -> void:
    var backer_graph: PlatformGraph = \
            Sc.level.graph_parser.platform_graphs[character_name]
    assert(backer_graph != null)
    graph = ReadonlyPlatformGraphProxy.new()
    graph.set_backer(backer_graph)
    graph.movement_params_override = movement_params
    graph.connect(
            "surface_exclusion_changed",
            self,
            "_on_surface_exclusion_changed")
    surface_store = Sc.level.surface_store
    possible_surfaces_set = graph.surfaces_set


func _init_navigator() -> void:
    navigator = SurfaceNavigator.new(self, graph)
    navigator.interruption_resolution_mode = \
            movement_params.default_nav_interrupt_resolution_mode
    navigation_state = navigator.navigation_state
    navigator.connect(
            "navigation_ended",
            self,
            "_on_surfacer_character_navigation_ended")
    _action_sources.push_back(navigator.instructions_action_source)


func _on_physics_process(delta: float) -> void:
    var delta_scaled: float = Sc.time.scale_delta(delta)
    
    collisions.clear()
    _apply_movement()
    _match_expected_navigation_trajectory()
    _maintain_collisions()
    collisions.invert()
    
    _update_actions(delta_scaled)
    surface_state.clear_just_changed_state()
    _update_surface_state()
    
    for behavior in _behaviors_list:
        behavior._on_physics_process(delta_scaled)
    
    _update_navigator(delta_scaled)
    
    if surface_state.just_left_air and \
            is_waiting_to_stop_on_surface:
        _stop_nav_immediately()
    
    actions.log_new_presses_and_releases(self)
    
    # Flip the horizontal direction of the animation according to which way the
    # character is facing.
    if surface_state.horizontal_facing_sign == 1:
        animator.face_right()
    elif surface_state.horizontal_facing_sign == -1:
        animator.face_left()
    
    _process_actions()
    _process_animation()
    _process_sounds()
    _update_collision_mask()
    
    if surface_state.did_move_last_frame and \
            is_instance_valid(touch_listener):
        touch_listener.on_character_moved()


func _apply_movement() -> void:
    if movement_params.bypasses_runtime_physics or \
            velocity == Vector2.ZERO:
        return
    
    # Since move_and_slide automatically accounts for delta, we need to
    # compensate for that in order to support our modified framerate.
    var modified_velocity: Vector2 = velocity * Sc.time.get_combined_scale()
    
    move_and_slide(
            modified_velocity,
            Sc.geometry.UP,
            movement_params.stops_on_slope,
            4,
            Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON)
    
    _record_collisions()


func _match_expected_navigation_trajectory() -> void:
    if navigation_state.just_reached_destination:
        _match_expected_path_end_trajectory()
    elif navigation_state.just_started_edge:
        _match_expected_edge_start_trajectory()
    elif is_instance_valid(navigator.edge):
        _match_expected_edge_trajectory()
    
    assert(!Sc.geometry.is_point_partial_inf(velocity))


func _match_expected_path_end_trajectory() -> void:
    if movement_params.forces_character_position_to_match_path_at_end:
        position = navigator.previous_path.destination.target_point
    if movement_params.forces_character_velocity_to_zero_at_path_end:
        velocity = Vector2.ZERO


func _match_expected_edge_start_trajectory() -> void:
    if movement_params.forces_character_position_to_match_edge_at_start:
        position = navigator.edge.get_start()
    if movement_params.forces_character_velocity_to_match_edge_at_start:
        velocity = navigator.edge.velocity_start
        surface_state.horizontal_acceleration_sign = 0


func _match_expected_edge_trajectory() -> void:
    var playback_elapsed_time: float = \
            navigator.playback.get_elapsed_time_scaled()
    var progress_in_current_trajectory_frame := \
            fmod(playback_elapsed_time, ScaffolderTime.PHYSICS_TIME_STEP) / \
            ScaffolderTime.PHYSICS_TIME_STEP
    
    if movement_params.syncs_character_position_to_edge_trajectory:
        var current_trajectory_position := navigator.edge.get_position_at_time(
                playback_elapsed_time)
        var next_trajectory_position := navigator.edge.get_position_at_time(
                playback_elapsed_time + ScaffolderTime.PHYSICS_TIME_STEP)
        var interpolated_position: Vector2 = lerp(
                current_trajectory_position,
                next_trajectory_position,
                progress_in_current_trajectory_frame)
        var is_movement_beyond_expected_trajectory := \
                current_trajectory_position == Vector2.INF
        if !is_movement_beyond_expected_trajectory:
            position = interpolated_position
    
    if movement_params.syncs_character_velocity_to_edge_trajectory:
        var current_trajectory_velocity := navigator.edge.get_velocity_at_time(
                playback_elapsed_time)
        var next_trajectory_velocity := navigator.edge.get_velocity_at_time(
                playback_elapsed_time + ScaffolderTime.PHYSICS_TIME_STEP)
        var interpolated_velocity: Vector2 = lerp(
                current_trajectory_velocity,
                next_trajectory_velocity,
                progress_in_current_trajectory_frame)
        var is_movement_beyond_expected_trajectory := \
                current_trajectory_velocity == Vector2.INF
        if !is_movement_beyond_expected_trajectory:
            velocity = interpolated_velocity


func _match_expected_navigation_surface_state(
        edge: Edge = null,
        edge_time := INF) -> void:
    if !is_instance_valid(edge):
        edge = navigator.edge
    if is_inf(edge_time):
        edge_time = navigator.playback.get_elapsed_time_scaled()
    edge.sync_expected_surface_state(surface_state, edge_time)


# -   The move_and_slide system depends on some velocity always pushing the
#     character into the floor (or other touched surface).
# -   If we just zero this out, move_and_slide will produce false-negatives for
#     collisions.
func _maintain_collisions() -> void:
    if movement_params.syncs_character_position_to_edge_trajectory and \
            navigation_state.is_currently_navigating and \
            is_instance_valid(navigator.edge.trajectory):
        var playback_elapsed_time: float = \
                navigator.playback.get_elapsed_time_scaled()
        var trajectory_index := \
                int(playback_elapsed_time / ScaffolderTime.PHYSICS_TIME_STEP)
        var is_at_end_of_edge := \
                trajectory_index >= \
                navigator.edge.trajectory \
                        .frame_continuous_positions_from_steps.size()
        if is_at_end_of_edge and \
                is_instance_valid(navigator.edge.get_end_surface()) and \
                !(navigator.edge is IntraSurfaceEdge):
            _trigger_collision_at_end_of_edge(navigator.edge)
            return
    
    _maintain_preexisting_collisions()


func _trigger_collision_at_end_of_edge(edge: Edge) -> void:
    var surface := edge.get_end_surface()
    var normal := surface.normal
    var maintain_collision_velocity: Vector2 = \
            MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION * \
            -normal
    var max_slides := 1
    var position_before_move := position
    var collision_count_before_move := collisions.size()
    
    # Trigger another move_and_slide.
    # -   This will maintain collision state within Godot's collision system.
    # -   This will also ensure the character snaps to the surface.
    move_and_slide(
            maintain_collision_velocity,
            Sc.geometry.UP,
            movement_params.stops_on_slope,
            max_slides,
            Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON)
    
    _record_collisions()
    
    var details := (
        "new_collisions=%d; " +
        "previous_p=%s; " +
        "ending_edge=%s; " +
        "v=%s"
    ) % [
        collisions.size() - collision_count_before_move,
        Sc.utils.get_vector_string(position_before_move, 1),
        EdgeType.get_prefix(navigator.edge.edge_type),
        Sc.utils.get_vector_string(maintain_collision_velocity, 1),
    ]
    _log("E end trig c",
            details,
            CharacterLogType.SURFACE,
            true)


func _maintain_preexisting_collisions() -> void:
    if movement_params.bypasses_runtime_physics or \
            !surface_state.is_grabbing_surface or \
            (surface_state.is_triggering_wall_release and \
            surface_state.is_grabbing_wall) or \
            (surface_state.is_triggering_ceiling_release and \
            surface_state.is_grabbing_ceiling) or \
            (surface_state.is_triggering_fall_through and \
            surface_state.is_grabbing_floor) or \
            actions.just_pressed_jump:
        return
    
    # TODO: We could use surface_state.grab_normal here, if we wanted to walk
    #       more slowly down hills.
    var normal := surface_state.grabbed_surface.normal
    
    var maintain_collision_velocity: Vector2 = \
            MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION * \
            -normal
    
    var max_slides := 1
    
    # Also maintain wall collisions.
    if !surface_state.is_grabbing_wall and \
            surface_state.is_touching_wall and \
            !surface_state.is_triggering_wall_release and \
            !surface_state.is_pressing_away_from_wall:
        maintain_collision_velocity.x = \
                MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION * \
                surface_state.toward_wall_sign
        max_slides = 2
    
    var position_before_move := position
    
    # Trigger another move_and_slide.
    # -   This will maintain collision state within Godot's collision system.
    # -   This will also ensure the character snaps to the surface.
    move_and_slide(
            maintain_collision_velocity,
            Sc.geometry.UP,
            movement_params.stops_on_slope,
            max_slides,
            Sc.geometry.FLOOR_MAX_ANGLE + \
                    Sc.geometry.WALL_ANGLE_EPSILON)
    
    if navigator.edge is FallFromFloorEdge:
        # Fall-from-floor edge trajectories assume that the character doesn't
        # start descending until after entirely clearing the edge of the
        # surface, so we need to undo any potential downward displacement from
        # the curve of the character collider.
        position = position_before_move
    
    _record_collisions()


func _record_collisions() -> void:
    var new_collision_count := get_slide_count()
    var old_collision_count := collisions.size()
    collisions.resize(old_collision_count + new_collision_count)
    
    for i in new_collision_count:
        collisions[old_collision_count + i] = \
                KinematicCollision2DCopy.new(get_slide_collision(i))


func _update_navigator(delta_scaled: float) -> void:
    navigator._update()


func _update_actions(delta_scaled: float) -> void:
    # Record actions for the previous frame.
    _actions_from_previous_frame.copy(actions)
    # Clear actions for the current frame.
    actions.clear()
    
    actions.delta_scaled = delta_scaled
    
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
    
    CharacterActionSource.update_for_implicit_key_events(
            actions,
            _actions_from_previous_frame)


# Updates physics and character states in response to the current actions.
func _process_actions() -> void:
    _previous_actions_handlers_this_frame.clear()
    
    for action_handler in movement_params.action_handlers:
        var is_action_relevant_for_surface: bool = \
                action_handler.type == surface_state.surface_type or \
                action_handler.type == SurfaceType.OTHER
        var is_action_relevant_for_physics_mode: bool = \
                !movement_params.bypasses_runtime_physics or \
                !action_handler.uses_runtime_physics
        if is_action_relevant_for_surface and \
                is_action_relevant_for_physics_mode:
            var executed: bool = action_handler.process(self)
            _previous_actions_handlers_this_frame[action_handler.name] = \
                    executed
            
            # TODO: This is sometimes useful for debugging.
#            if executed and \
#                    action_handler.name != AllDefaultAction.NAME and \
#                    action_handler.name != CapVelocityAction.NAME and \
#                    action_handler.name != FloorDefaultAction.NAME and \
#                    action_handler.name != FloorFrictionAction.NAME and \
#                    action_handler.name != FloorWalkAction.NAME and \
#                    action_handler.name != AirDefaultAction.NAME:
#                var name_str: String = Sc.utils.resize_string(
#                        action_handler.name,
#                        20)
#                _log(name_str,
#                        "",
#                        CharacterLogType.ACTION,
#                        true)
    
    assert(!Sc.geometry.is_point_partial_inf(velocity))


func _process_animation() -> void:
    if rotates_to_match_surface_normal:
        animator.sync_position_rotation_for_contact_normal(
                position,
                collider,
                surface_state.grabbed_surface,
                surface_state.grab_position,
                surface_state.grab_normal)
    
    if surface_state.get_just_changed_to_neighbor_surface() and \
            !surface_state.get_is_previous_surface_collinear_neighbor():
        # TODO: Improve on this.
        # -   Right now, this skip is prevents an issue with the next animation
        #     starting its blend with the previous animation at a what is now a
        #     non-sense rotation.
        # -   However, it would be nice to still have a blend!
        # -   Maybe this is the answer?
        #     -   Update animator to track current blend duration.
        #     -   Then, add a Tween for updating the position and rotation in
        #         this case.
        animator.skip_current_blend()
    
    match surface_state.surface_type:
        SurfaceType.FLOOR:
            if actions.pressed_left or actions.pressed_right:
                animator.play("Walk")
            else:
                animator.play("Rest")
        SurfaceType.WALL:
            if processed_action("WallClimbAction"):
                if actions.pressed_up:
                    animator.play("ClimbUp")
                elif actions.pressed_down:
                    animator.play("ClimbDown")
                else:
                    Sc.logger.error("SurfacerCharacter._process_animation")
            else:
                animator.play("RestOnWall")
        SurfaceType.CEILING:
            if actions.pressed_left or actions.pressed_right:
                animator.play("CrawlOnCeiling")
            else:
                animator.play("RestOnCeiling")
        SurfaceType.AIR:
            if velocity.y > 0:
                animator.play("JumpFall")
            else:
                animator.play("JumpRise")
        _:
            Sc.logger.error("SurfacerCharacter._process_animation")


func _process_sounds() -> void:
    if just_triggered_jump:
        Sc.audio.play_sound("jump")
    
    if surface_state.just_left_air:
        Sc.audio.play_sound("land")
    elif surface_state.just_touched_surface:
        Sc.audio.play_sound("land")


func processed_action(name: String) -> bool:
    return _previous_actions_handlers_this_frame.get(name) == true


func _update_surface_state() -> void:
    surface_state.update()
    
    if surface_state.just_changed_surface and \
            surface_state.is_grabbing_surface:
        _update_reachable_surfaces(surface_state.grabbed_surface)
    
    if surface_state.just_entered_air:
        _log("Released",
                "grab_p=%s, %s" % [
                    Sc.utils.get_vector_string(surface_state.grab_position, 1),
                    surface_state.previous_grabbed_surface.to_string(false),
                ],
                CharacterLogType.SURFACE,
                false)
        
    elif surface_state.just_changed_surface:
        _log("Grabbed",
                "grab_p=%s, %s" % [
                    Sc.utils.get_vector_string(surface_state.grab_position, 1),
                    surface_state.grabbed_surface.to_string(false),
                ],
                CharacterLogType.SURFACE,
                false)
        
    elif surface_state.just_touched_surface:
        var side_prefixes := []
        if surface_state.is_touching_floor:
            side_prefixes.push_back("F")
        elif surface_state.is_touching_ceiling:
            side_prefixes.push_back("C")
        elif surface_state.is_touching_left_wall:
            side_prefixes.push_back("LW")
        elif surface_state.is_touching_right_wall:
            side_prefixes.push_back("RW")
        _log("Touched",
                "side=%s" % Sc.utils.join(side_prefixes),
                CharacterLogType.SURFACE,
                false)


# Update whether or not we should currently consider collisions with
# fall-through floors and walk-through walls.
func _update_collision_mask() -> void:
    set_collision_mask_bit(
            Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT,
            !surface_state.is_descending_through_floors and \
                    velocity.y > 0)
    set_collision_mask_bit(
            Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT,
            !surface_state.is_ascending_through_ceilings and \
                    velocity.y < 0)
    set_collision_mask_bit(
            Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT,
            surface_state.is_grabbing_walk_through_walls)


func _on_surfacer_character_navigation_ended(
        did_navigation_finish: bool,
        triggered_by_player: bool) -> void:
    for behavior in _behaviors_list:
        behavior._on_navigation_ended(did_navigation_finish)


# "Finished" means that the behavior ended itself, so there shouldn't be
# another behavior being triggered somewhere.
func _on_behavior_finished(behavior: Behavior) -> void:
    # FIXME: LEFT OFF HERE: ------------------------
    # - Not sure why behavior.next_behavior could be null, but let's fix it
    #   later.
    if !is_instance_valid(behavior.next_behavior):
        behavior.next_behavior = get_behavior(StaticBehavior)
    
    if behavior != behavior.next_behavior:
        behavior.next_behavior.trigger(false)
    else:
        Sc.logger.error(
            ("Behavior finished, but next behavior is the same: " +
            "behavior=%s, character=%s, position=%s") % [
                behavior.behavior_name,
                character_name,
                Sc.utils.get_vector_string(position),
            ],
            false)


func _on_behavior_error(behavior: Behavior) -> void:
    if behavior != behavior.next_behavior:
        behavior.next_behavior.trigger(false)
    else:
        Sc.logger.error(
            ("Behavior errored, but next behavior is the same: " +
            "behavior=%s, character=%s, position=%s") % [
                behavior.behavior_name,
                character_name,
                Sc.utils.get_vector_string(position),
            ],
            false)


func _on_behavior_move_target_destroyed(behavior: Behavior) -> void:
    _on_behavior_finished(behavior)


func start_dash(horizontal_acceleration_sign: int) -> void:
    if !_can_dash or \
            !movement_params.can_dash:
        return
    
    var duration: float = \
            movement_params.dash_fade_duration / \
            Sc.time.get_combined_scale()
    var delay: float = \
            (movement_params.dash_duration - 
            movement_params.dash_fade_duration) / \
            Sc.time.get_combined_scale()
    
    _current_max_horizontal_speed_multiplier = \
            movement_params.dash_speed_multiplier
    
    velocity.x = current_air_max_horizontal_speed * horizontal_acceleration_sign
    velocity.y += movement_params.dash_vertical_boost
    
    _dash_fade_tween.stop_all()
    _dash_fade_tween.interpolate_property(
            self,
            "_current_max_horizontal_speed_multiplier",
            _current_max_horizontal_speed_multiplier,
            1.0,
            duration,
            "ease_in",
            delay,
            TimeType.PLAY_RENDER_SCALED)
    _dash_fade_tween.start()
    
    Sc.time.clear_timeout(_dash_cooldown_timeout)
    _dash_cooldown_timeout = Sc.time.set_timeout(
            self,
            "set",
            movement_params.dash_cooldown,
            ["_can_dash", true])
    
    if horizontal_acceleration_sign > 0:
        animator.face_right()
    else:
        animator.face_left()
    
    _can_dash = false


func force_boost(boost: Vector2) -> void:
    surface_state.clear_current_state()
    
    velocity = boost
    surface_state.velocity = velocity
    
    position += Vector2(0.0, -1.0)
    surface_state.center_position = position
    surface_state.center_position_along_surface \
            .match_current_grab(null, position)
    
    navigator.stop(true)


## Triggers navigation and replaces preexisting behavior.
func navigate_imperatively(destination: PositionAlongSurface) -> bool:
    var navigation_override_behavior: NavigationOverrideBehavior = \
            get_behavior(NavigationOverrideBehavior)
    if !is_instance_valid(navigation_override_behavior):
        navigation_override_behavior = NavigationOverrideBehavior.new()
        add_behavior(navigation_override_behavior)
    navigation_override_behavior.destination = destination
    navigation_override_behavior.trigger(false)
    return navigation_state.is_currently_navigating


func stop_on_surface() -> void:
    is_waiting_to_stop_on_surface = true
    if surface_state.is_grabbing_surface:
        _stop_nav_immediately()


func _stop_nav_immediately() -> void:
    navigator.stop(false)


func set_start_attachment_surface_side_or_position(
        surface_side_or_position) -> void:
    _start_attachment_surface_side_or_position = surface_side_or_position


func get_intended_position(type: int) -> PositionAlongSurface:
    match type:
        IntendedPositionType.CENTER_POSITION:
            return surface_state.center_position_along_surface if \
                    surface_state.is_grabbing_surface else \
                    PositionAlongSurfaceFactory.create_position_without_surface(
                            surface_state.center_position)
        IntendedPositionType.CENTER_POSITION_ALONG_SURFACE:
            return surface_state.center_position_along_surface
        IntendedPositionType.LAST_POSITION_ALONG_SURFACE:
            return surface_state.last_position_along_surface
        IntendedPositionType.CLOSEST_SURFACE_POSITION:
            var result := \
                    surface_state.center_position_along_surface if \
                    surface_state.is_grabbing_surface else \
                    SurfaceFinder.find_closest_position_on_a_surface(
                            surface_state.center_position,
                            self,
                            SurfaceReachability.ANY)
            return result if \
                    is_instance_valid(result) else \
                    surface_state.last_position_along_surface
        IntendedPositionType.EDGE_ORIGIN:
            return navigator.edge.start_position_along_surface if \
                    navigation_state.is_currently_navigating else \
                    null
        IntendedPositionType.EDGE_DESTINATION:
            return navigator.edge.end_position_along_surface if \
                    navigation_state.is_currently_navigating else \
                    null
        IntendedPositionType.PATH_ORIGIN:
            return navigator.path.origin if \
                    navigation_state.is_currently_navigating else \
                    null
        IntendedPositionType.PATH_DESTINATION:
            return navigator.path.destination if \
                    navigation_state.is_currently_navigating else \
                    null
        _:
            Sc.logger.error("Invalid IntendedPositionType: %d" % type)
            return null


func get_current_animation_state(
        result: SurfacerCharacterAnimationState) -> void:
    result.character_position = position
    result.animation_name = animator.get_current_animation_name()
    result.animation_position = \
            animator.animation_player.current_animation_position
    result.facing_left = surface_state.horizontal_facing_sign == -1


func _parse_behavior_children() -> void:
    var behaviors: Array = \
            Sc.utils.get_children_by_type(self, Behavior)
    
    var projected_behaviors := []
    for behavior in behaviors:
        if behavior.owner != self:
            projected_behaviors.push_back(behavior)
    
    # If there are any projected behavior nodes, then disregard all owned
    # behaviors, and only use the projected ones instead.
    if !projected_behaviors.empty():
        behaviors = projected_behaviors
    
    default_behavior = null
    
    for behavior in behaviors:
        var script: Script = behavior.get_script()
        assert(behavior is PlayerNavigationBehavior or \
                get_behavior(script) == null)
        _behaviors_by_class[script] = behavior
        _behaviors_list.push_back(behavior)
        behavior.is_enabled = true
        if behavior.is_active_at_start:
            default_behavior = behavior
        _add_return_behavior_if_needed(behavior)
    
    # Automatically add a StaticBehavior if no other behavior has been
    # configured as active-at-start.
    if default_behavior == null:
        default_behavior = StaticBehavior.new()
        default_behavior.is_active_at_start = true
        add_behavior(default_behavior)
    
    default_behavior.trigger(false)


func add_behavior(
        behavior: Behavior,
        is_default := false) -> void:
    var script: Script = behavior.get_script()
    assert(get_behavior(script) == null)
    _behaviors_by_class[script] = behavior
    _behaviors_list.push_back(behavior)
    if Engine.editor_hint:
        return
    if is_default:
        behavior.is_active_at_start = true
        if is_instance_valid(default_behavior):
            assert(default_behavior is StaticBehavior)
            for b in _behaviors_list:
                if b.next_behavior == default_behavior:
                    b.next_behavior = behavior
            default_behavior.queue_free()
        remove_behavior(StaticBehavior)
    behavior.is_enabled = true
    add_child(behavior)
    _add_return_behavior_if_needed(behavior)


func _add_return_behavior_if_needed(other_behavior: Behavior) -> void:
    if (other_behavior.returns_to_character_start_position or \
            other_behavior.returns_to_pre_behavior_position) and \
            !has_behavior(ReturnBehavior):
        var return_behavior := ReturnBehavior.new()
        add_behavior(return_behavior)


func remove_behavior(behavior_class: Script) -> void:
    var behavior := get_behavior(behavior_class)
    _behaviors_by_class.erase(behavior_class)
    _behaviors_list.erase(behavior)
    if is_instance_valid(behavior):
        behavior.queue_free()


func get_behavior(behavior_class_or_name) -> Behavior:
    var behavior_class: Script = \
            behavior_class_or_name if \
            behavior_class_or_name is Script else \
            Su.behaviors[behavior_class_or_name]
    if _behaviors_by_class.has(behavior_class):
        return _behaviors_by_class[behavior_class]
    else:
        return null


func has_behavior(behavior_class_or_name) -> bool:
    var behavior_class: Script = \
            behavior_class_or_name if \
            behavior_class_or_name is Script else \
            Su.behaviors[behavior_class_or_name]
    return _behaviors_by_class.has(behavior_class)


func _set_behavior(value: Behavior) -> void:
    var previous_behavior := behavior
    behavior = value
    if behavior != previous_behavior:
        self.previous_behavior = previous_behavior
        movement_params.additional_surface_speed_multiplier = \
            behavior.surface_speed_multiplier


func _on_surface_exclusion_changed() -> void:
    _update_reachable_surfaces(reachable_basis_surface)


func _update_reachable_surfaces(basis_surface: Surface) -> void:
    if !Su.are_reachable_surfaces_per_player_tracked:
        return
    reachable_basis_surface = basis_surface
    reachable_surfaces = graph.get_all_reachable_surfaces(
            reachable_basis_surface,
            movement_params.max_distance_for_reachable_surface_tracking)
    reversibly_reachable_surfaces = \
            graph.get_all_reversibly_reachable_surfaces(
                    reachable_basis_surface,
                    movement_params.max_distance_for_reachable_surface_tracking)


func _get_is_dashing() -> bool:
    return is_instance_valid(_dash_fade_tween) and \
            _dash_fade_tween.is_active()


func _get_current_surface_max_horizontal_speed() -> float:
    return movement_params.max_horizontal_speed_default * \
            movement_params.surface_speed_multiplier * \
            _current_max_horizontal_speed_multiplier * \
            (surface_state.grabbed_surface.properties.speed_multiplier if \
            surface_state.is_grabbing_surface else \
            1.0)


func _get_current_air_max_horizontal_speed() -> float:
    return movement_params.max_horizontal_speed_default * \
            movement_params.air_horizontal_speed_multiplier * \
            _current_max_horizontal_speed_multiplier


func _get_current_walk_acceleration() -> float:
    return movement_params.walk_acceleration * \
            (surface_state.grabbed_surface.properties.speed_multiplier if \
            surface_state.is_grabbing_surface else \
            1.0)


func _get_current_climb_up_speed() -> float:
    return movement_params.climb_up_speed * \
            (surface_state.grabbed_surface.properties.speed_multiplier if \
            surface_state.is_grabbing_surface else \
            1.0)


func _get_current_climb_down_speed() -> float:
    return movement_params.climb_down_speed * \
            (surface_state.grabbed_surface.properties.speed_multiplier if \
            surface_state.is_grabbing_surface else \
            1.0)


func _get_current_ceiling_crawl_speed() -> float:
    return movement_params.ceiling_crawl_speed * \
            (surface_state.grabbed_surface.properties.speed_multiplier if \
            surface_state.is_grabbing_surface else \
            1.0)
