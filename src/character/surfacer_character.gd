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

var movement_params: MovementParameters
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

var current_max_horizontal_speed: float
var _can_dash := true

var _actions_from_previous_frame := CharacterActionState.new()
var actions := CharacterActionState.new()
var surface_state := CharacterSurfaceState.new(self)
var navigation_state: CharacterNavigationState

var graph: PlatformGraph
var surface_parser: SurfaceParser
var navigator: SurfaceNavigator
var prediction: CharacterPrediction
var pointer_listener: PlayerPointerListener

var behavior: Behavior
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

var _dash_cooldown_timeout: int
var _dash_fade_tween: ScaffolderTween


func _init() -> void:
    self.add_to_group(Sc.characters.GROUP_NAME_SURFACER_CHARACTERS)


func _ready() -> void:
    surface_state.previous_center_position = self.position
    surface_state.center_position = self.position
    
    # Start facing right.
    surface_state.horizontal_facing_sign = 1
    animator.face_right()
    
    if Engine.editor_hint:
        return
    
    if movement_params.can_dash:
        # Set up a Tween for the fade-out at the end of a dash.
        _dash_fade_tween = ScaffolderTween.new()
        add_child(_dash_fade_tween)
    
    if movement_params.bypasses_runtime_physics:
        set_collision_mask_bit(
                Su.WALLS_AND_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.FALL_THROUGH_FLOORS_COLLISION_MASK_BIT, false)
        set_collision_mask_bit(
                Su.WALK_THROUGH_WALLS_COLLISION_MASK_BIT, false)
    
    if Sc.annotators.is_annotator_enabled(
            AnnotatorType.PATH_PRESELECTION) and \
            (is_player_character and \
                    Su.ann_manifest.is_player_prediction_shown or \
            !is_player_character and \
                    Su.ann_manifest.is_npc_prediction_shown):
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
    Sc.annotators.create_character_annotator(
            self,
            is_player_character)


func _destroy() -> void:
    if is_instance_valid(prediction):
        prediction.queue_free()
    ._destroy()


func _on_annotators_ready() -> void:
    ._on_annotators_ready()
    _attach_prediction()


func _attach_prediction() -> void:
    if !Sc.level_session.has_started:
        return
    
    if is_instance_valid(prediction) and \
            is_instance_valid(Sc.annotators.path_preselection_annotator):
        Sc.annotators.path_preselection_annotator \
                .add_prediction(prediction)


func _update_editor_configuration_debounced() -> void:
    ._update_editor_configuration_debounced()
    
    if _configuration_warning != "":
        return
    
    if Engine.editor_hint:
        # Validate MovementParameters from scene configuration.
        var movement_params_matches: Array = Sc.utils.get_children_by_type(
                self,
                MovementParameters)
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
    # Get MovementParameters from scene configuration.
    movement_params = Su.movement.character_movement_params[character_name]
    self.current_max_horizontal_speed = \
            movement_params.max_horizontal_speed_default
    movement_params.call_deferred("_parse_shape_from_parent")


func set_is_player_character(value: bool) -> void:
    .set_is_player_character(value)
    if is_player_character:
        _init_player_controller_action_source()
        if Su.movement.uses_point_and_click_navigation:
            var player_navigation_behavior := \
                    PlayerNavigationBehavior.new()
            player_navigation_behavior.cancels_navigation_on_key_press = \
                    Su.movement.cancels_point_and_click_nav_on_key_press
            add_behavior(player_navigation_behavior)
            
            self.pointer_listener = PlayerPointerListener.new(self)
            add_child(pointer_listener)


func _init_player_controller_action_source() -> void:
    _action_sources.push_back(PlayerActionSource.new(self, true))


func _init_platform_graph() -> void:
    var graph: PlatformGraph = \
            Sc.level.graph_parser.platform_graphs[character_name]
    assert(graph != null)
    graph.connect(
            "surface_exclusion_changed",
            self,
            "_on_surface_exclusion_changed")
    self.graph = graph
    self.surface_parser = Sc.level.surface_parser
    self.possible_surfaces_set = graph.surfaces_set


func _init_navigator() -> void:
    navigator = SurfaceNavigator.new(self, graph)
    navigation_state = navigator.navigation_state
    navigator.connect(
            "navigation_ended",
            self,
            "_on_surfacer_character_navigation_ended")
    _action_sources.push_back(navigator.instructions_action_source)


func _on_physics_process(delta: float) -> void:
    var delta_scaled: float = Sc.time.scale_delta(delta)
    
    if !movement_params.bypasses_runtime_physics:
        # Since move_and_slide automatically accounts for delta, we need to
        # compensate for that in order to support our modified framerate.
        var modified_velocity: Vector2 = \
                velocity * Sc.time.get_combined_scale()
        
        # FIXME: LEFT OFF HERE: ------------------ Use move_and_slide_with_snap.
        
        # TODO: Use the remaining pre-collision movement that move_and_slide
        #       returns. This might be needed in order to move along slopes?
        move_and_slide(
                modified_velocity,
                Sc.geometry.UP,
                true,
                4,
                Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON)
    
    _update_actions(delta_scaled)
    surface_state.clear_just_changed_state()
    _update_surface_state()
    
    for behavior in _behaviors_list:
        behavior._on_physics_process(delta)
    
    _update_navigator(delta_scaled)
    
    actions.delta_scaled = delta_scaled
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
            is_player_character:
        pointer_listener.on_character_moved()


func _update_navigator(delta_scaled: float) -> void:
    navigator._update()


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
            _previous_actions_handlers_this_frame[action_handler.name] = executed
            
            # TODO: This is sometimes useful for debugging.
#            if executed and \
#                    action_handler.name != AllDefaultAction.NAME and \
#                    action_handler.name != CapVelocityAction.NAME and \
#                    action_handler.name != \
#                            MatchExpectedEdgeTrajectoryAction.NAME and \
#                    action_handler.name != FloorDefaultAction.NAME and \
#                    action_handler.name != FloorFrictionAction.NAME and \
#                    action_handler.name != AirDefaultAction.NAME:
#                var name_str: String = Sc.utils.resize_string(
#                        action_handler.name,
#                        20)
#                _log(name_str,
#                        "",
#                        CharacterLogType.ACTION,
#                        true)


func _process_animation() -> void:
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
                    Sc.logger.error()
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
            Sc.logger.error()


func _process_sounds() -> void:
    pass


func processed_action(name: String) -> bool:
    return _previous_actions_handlers_this_frame.get(name) == true


func _update_surface_state() -> void:
    surface_state.update()
    
    if surface_state.just_changed_surface and \
            surface_state.is_grabbing_surface:
        _update_reachable_surfaces(surface_state.grabbed_surface)
    
    if surface_state.just_left_air:
        _log("Grabbed",
                "grab_p=%s, %s" % [
                    Sc.utils.get_vector_string(surface_state.grab_position, 1),
                    surface_state.grabbed_surface.to_string(false),
                ],
                CharacterLogType.SURFACE,
                false)
        
    elif surface_state.just_entered_air:
        _log("Launched",
                "grab_p=%s, %s" % [
                    Sc.utils.get_vector_string(surface_state.grab_position, 1),
                    surface_state.previous_grabbed_surface.to_string(false),
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
        did_navigation_finish: bool) -> void:
    for behavior in _behaviors_list:
        behavior._on_navigation_ended(did_navigation_finish)


# "Finished" means that the behavior ended itself, so there shouldn't be
# another behavior being triggered somewhere.
func _on_behavior_finished(behavior: Behavior) -> void:
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


func navigate_as_choreographed(destination: PositionAlongSurface) -> bool:
    var choreography_behavior: ChoreographyBehavior = \
            get_behavior(ChoreographyBehavior)
    if !is_instance_valid(choreography_behavior):
        choreography_behavior = ChoreographyBehavior.new()
        add_behavior(choreography_behavior)
    choreography_behavior.destination = destination
    choreography_behavior.trigger(false)
    return navigation_state.is_currently_navigating


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
            return surface_state.center_position_along_surface if \
                    surface_state.is_grabbing_surface else \
                    SurfaceParser.find_closest_position_on_a_surface(
                            surface_state.center_position,
                            self,
                            SurfaceReachability.ANY)
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


func get_current_animation_state(result: CharacterAnimationState) -> void:
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
        assert(get_behavior(script) == null)
        _behaviors_by_class[script] = behavior
        _behaviors_list.push_back(behavior)
        behavior.is_enabled = true
        if behavior.is_active_at_start:
            default_behavior = behavior
        _add_return_behavior_if_needed(behavior)
    
    # Automatically add a DefaultBehavior if no other behavior has been
    # configured as active-at-start.
    if default_behavior == null:
        default_behavior = DefaultBehavior.new()
        default_behavior.is_active_at_start = true
        add_behavior(default_behavior)
    
    default_behavior.trigger(false)


func add_behavior(behavior: Behavior) -> void:
    var script: Script = behavior.get_script()
    assert(get_behavior(script) == null)
    _behaviors_by_class[script] = behavior
    _behaviors_list.push_back(behavior)
    if Engine.editor_hint:
        return
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
