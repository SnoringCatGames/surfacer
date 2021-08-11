tool
class_name MoveBackAndForthBehaviorController, \
"res://addons/surfacer/assets/images/editor_icons/move_back_and_forth_behavior_controller.png"
extends BehaviorController
## -   This moves a player back-and-forth along a surface.
## -   The spacing and timing of movement is configurable.


const CONTROLLER_NAME := "move_back_and_forth"
const IS_ADDED_MANUALLY := true
const INCLUDES_MID_MOVEMENT_PAUSE := true
const INCLUDES_POST_MOVEMENT_PAUSE := false
const COULD_RETURN_TO_START_POSITION := false

## If true, then the player's movement range will extend to the far ends of the
## surface they are on.
export var moves_to_surface_ends := true setget _set_moves_to_surface_ends

## -   The movement range that the player will move within is centered on their
##     starting position, and extends out to either side a distance of this
##     radius.[br]
## -   This is only used if `moves_to_surface_ends` is `false`.[br]
export var movement_radius := -1.0 setget _set_movement_radius

## The player will not get closer than this to the ends of the surface.
export var min_distance_from_surface_ends := 0.0 \
        setget _set_min_distance_from_surface_ends

## A minimum delay for the player to stand in place before turning around.
export var pause_delay_min := 0.0 setget _set_pause_delay_min
## A maximum delay for the player to stand in place before turning around.
export var pause_delay_max := 0.0 setget _set_pause_delay_max

## -   This can be used to give the player's movement some randomness.[br]
## -   A value of 0.0 causes the player to always move to the far ends of their
##     range.[br]
## -   A value of 1.0 causes the player to move to any random position within
##     their range. This might mean that the player moves in the same direction
##     during sequential movements.[br]
## -   A value of 0.5 causes the player to always at least move to a point on
##     the other half of their range.[br]
export(float, 0.0, 1.0) var max_ratio_for_destination_offset_from_ends := 0.0 \
        setget _set_max_ratio_for_destination_offset_from_ends

var _is_next_move_minward := true
var _destination := PositionAlongSurface.new()


func _init().(
        CONTROLLER_NAME,
        IS_ADDED_MANUALLY,
        INCLUDES_MID_MOVEMENT_PAUSE,
        INCLUDES_POST_MOVEMENT_PAUSE,
        COULD_RETURN_TO_START_POSITION) -> void:
    # Randomize which direction the player moves first.
    _is_next_move_minward = randf() < 0.5


#func _on_active() -> void:
#    ._on_active()


func _on_ready_to_move() -> void:
    ._on_ready_to_move()
    _destination.surface = player.start_surface
    _move()


#func _on_inactive() -> void:
#    ._on_inactive()


#func _on_navigation_ended(did_navigation_finish: bool) -> void:
#    ._on_navigation_ended(did_navigation_finish)


#func _on_physics_process(delta: float) -> void:
#    ._on_physics_process(delta)


func _move() -> bool:
    var is_moving_minward := _is_next_move_minward
    _is_next_move_minward = !_is_next_move_minward
    
    var is_surface_horizontal: bool = \
            player.start_surface.side == SurfaceSide.FLOOR or \
            player.start_surface.side == SurfaceSide.CEILING
    
    var min_x_from_surface_bounds: float = \
            player.start_surface.bounding_box.position.x + \
            min_distance_from_surface_ends
    var max_x_from_surface_bounds: float = \
            player.start_surface.bounding_box.end.x - \
            min_distance_from_surface_ends
    var min_y_from_surface_bounds: float = \
            player.start_surface.bounding_box.position.y + \
            min_distance_from_surface_ends
    var max_y_from_surface_bounds: float = \
            player.start_surface.bounding_box.end.y - \
            min_distance_from_surface_ends
    
    var min_x: float = player.start_position.x
    var max_x: float = player.start_position.x
    var min_y: float = player.start_position.y
    var max_y: float = player.start_position.y
    
    if moves_to_surface_ends:
        if is_surface_horizontal:
            min_x = min_x_from_surface_bounds
            max_x = max_x_from_surface_bounds
        else:
            min_y = min_y_from_surface_bounds
            max_y = max_y_from_surface_bounds
    else:
        if is_surface_horizontal:
            min_x = max( \
                    player.start_position.x - movement_radius, \
                    min_x_from_surface_bounds)
            max_x = min( \
                    player.start_position.x + movement_radius, \
                    max_x_from_surface_bounds)
        else:
            min_y = max( \
                    player.start_position.y - movement_radius, \
                    min_y_from_surface_bounds)
            max_y = min( \
                    player.start_position.y + movement_radius, \
                    max_y_from_surface_bounds)
    
    var range_x := max_x - min_x
    var range_y := max_y - min_y
    
    var sample_min: float
    var sample_max: float
    if is_surface_horizontal:
        if is_moving_minward:
            sample_min = min_x
            sample_max = \
                    min_x + \
                    range_x * max_ratio_for_destination_offset_from_ends
            sample_max = max(sample_max, sample_min)
        else:
            sample_min = \
                    max_x - \
                    range_x * max_ratio_for_destination_offset_from_ends
            sample_max = max_x
            sample_min = min(sample_min, sample_max)
    else:
        if is_moving_minward:
            sample_min = min_y
            sample_max = \
                    min_y + \
                    range_y * max_ratio_for_destination_offset_from_ends
            sample_max = max(sample_max, sample_min)
        else:
            sample_min = \
                    max_y - \
                    range_y * max_ratio_for_destination_offset_from_ends
            sample_max = max_y
            sample_min = min(sample_min, sample_max)
    
    var sample := randf() * (sample_max - sample_min) + sample_min
    var target_point := \
            Vector2(sample, player.start_position.y) if \
            is_surface_horizontal else \
            Vector2(player.start_position.x, sample)
    _destination.match_surface_target_and_collider(
            player.start_surface,
            target_point,
            player.movement_params.collider_half_width_height,
            true,
            true)
    
    return player.navigator.navigate_to_position(_destination)


func _set_moves_to_surface_ends(value: bool) -> void:
    moves_to_surface_ends = value
    if moves_to_surface_ends:
        movement_radius = -1.0
    _update_parameters()


func _set_movement_radius(value: float) -> void:
    movement_radius = value
    if movement_radius >= 0.0:
        moves_to_surface_ends = false
    _update_parameters()


func _set_min_distance_from_surface_ends(value: float) -> void:
    min_distance_from_surface_ends = value
    _update_parameters()


func _set_pause_delay_min(value: float) -> void:
    pause_delay_min = value
    _update_parameters()


func _set_pause_delay_max(value: float) -> void:
    pause_delay_max = value
    _update_parameters()


func _set_max_ratio_for_destination_offset_from_ends(value: float) -> void:
    max_ratio_for_destination_offset_from_ends = value
    _update_parameters()


func _update_parameters() -> void:
    ._update_parameters()
    
    if _configuration_warning != "":
        return
    
    if min_distance_from_surface_ends < 0.0:
        _set_configuration_warning(
                "min_distance_from_surface_ends must be non-negative.")
    elif moves_to_surface_ends and movement_radius >= 0.0:
        _set_configuration_warning(
                "If moves_to_surface_ends is true, " +
                "then movement_radius must be negative.")
    elif !moves_to_surface_ends and movement_radius < 0.0:
        _set_configuration_warning(
                "If moves_to_surface_ends is false, " +
                "then movement_radius must be non-negative.")
    elif pause_delay_min < 0.0:
        _set_configuration_warning(
                "pause_delay_min must be non-negative.")
    elif pause_delay_max < 0.0:
        _set_configuration_warning(
                "pause_delay_max must be non-negative.")
    elif max_ratio_for_destination_offset_from_ends < 0.0:
        _set_configuration_warning(
                "max_ratio_for_destination_offset_from_ends " +
                "must be non-negative.")
    else:
        _set_configuration_warning("")
