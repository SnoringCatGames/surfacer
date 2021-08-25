tool
class_name CollideBehavior, \
"res://addons/surfacer/assets/images/editor_icons/collide_behavior.png"
extends Behavior


const NAME := "collide"
const IS_ADDED_MANUALLY := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := true
const COULD_RETURN_TO_START_POSITION := true

# FIXME: ---------------------------
## -   FIXME: --
export var anticipates_target_edge := false

# FIXME: ---------------------------
## -   FIXME: --
export var anticipates_target_path := false

# FIXME: ---------------------------
# - But also check whether the target destination has changed.
## -   FIXME: --
export var recomputes_nav_on_target_edge_change := true

var collision_target: ScaffolderCharacter


func _init().(
        NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    pass


#func _on_active() -> void:
#    ._on_active()


#func _on_ready_to_move() -> void:
#    ._on_ready_to_move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func on_collided() -> void:
    character._log("Collided:            %8.3fs; %s; with=%s; pos=%s" % [
                Sc.time.get_play_time(),
                character.character_name,
                collision_target.character_name,
                character.position,
            ],
            CharacterLogType.BEHAVIOR)
    
    _pause_post_movement()
    
    if character.navigation_state.is_currently_navigating and \
            is_active:
        character.navigator.stop()


func _move() -> bool:
    # FIXME: LEFT OFF HERE: ------------------- 
    # - Update move to return an enum value.
    # - Reached max
    # - Was valid
    # - Error
    # - Cancel back to default
    # - THEN, add checks to all other references in Behaviors to other
    #   characters.
    if !is_instance_valid(collision_target):
        return false
    
    var max_distance_squared_from_start_position := \
            max_distance_from_start_position * max_distance_from_start_position
    
    var surface_reachability := \
            SurfaceReachability.REVERSIBLY_REACHABLE if \
            only_navigates_reversible_paths else \
            SurfaceReachability.REACHABLE
    
    var destination: PositionAlongSurface
    if can_leave_start_surface:
        if collision_target.surface_state.is_grabbing_surface:
            destination = collision_target.surface_state \
                    .center_position_along_surface
        else:
            destination = SurfaceParser.find_closest_position_on_a_surface(
                    collision_target.position,
                    character,
                    surface_reachability)
    else:
        destination = PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        collision_target.position,
                        start_surface,
                        character.movement_params.collider_half_width_height,
                        true)
    
    # Prevent straying too far the start position.
    if start_position_for_max_distance_checks.distance_squared_to(
            destination.target_point) <= \
            max_distance_squared_from_start_position:
        var is_navigation_valid := _attempt_navigation_to_destination(
                destination,
                _is_first_move_since_active)
        if is_navigation_valid:
            return true
    
    var original_destination := destination
    var original_distance := \
            start_position.distance_to(original_destination.target_point)
    var direction := \
            (start_position - original_destination.target_point) / \
            original_distance
    
    # If the original destination is too far from the start position, then try
    # moving the character slightly less far from their current position.
    for ratio in [0.5, 0.25]:
        var target: Vector2 = \
                start_position + \
                direction * ratio * original_distance
        destination = SurfaceParser.find_closest_position_on_a_surface(
                target,
                character,
                surface_reachability)
        
        # Prevent straying too far the start position.
        if start_position_for_max_distance_checks.distance_squared_to(
                destination.target_point) <= \
                max_distance_squared_from_start_position:
            var is_navigation_valid := _attempt_navigation_to_destination(
                    destination,
                    _is_first_move_since_active)
            if is_navigation_valid:
                return true
    
    _reached_max_distance = true
    return false
