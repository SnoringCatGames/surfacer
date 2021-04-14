class_name PlayerAnnotator
extends Node2D

var player: Player
var is_human_player: bool
var previous_position: Vector2

var navigator_annotator: NavigatorAnnotator

var recent_movement_annotator: PlayerRecentMovementAnnotator
var surface_annotator: PlayerSurfaceAnnotator
var position_annotator: PlayerPositionAnnotator
var tile_annotator: PlayerTileAnnotator

func _init(
        player: Player,
        is_human_player: bool) -> void:
    self.player = player
    self.is_human_player = is_human_player
    self.z_index = 2

func _physics_process(delta_sec: float) -> void:
    if !Gs.geometry.are_points_equal_with_epsilon(
            player.position,
            previous_position,
            0.01):
        previous_position = player.position
        
        if recent_movement_annotator != null:
            recent_movement_annotator.check_for_update()
        if surface_annotator != null:
            surface_annotator.check_for_update()
        if position_annotator != null:
            position_annotator.check_for_update()
        if tile_annotator != null:
            tile_annotator.check_for_update()

func set_annotator_enabled(
        annotator_type: int,
        is_enabled: bool) -> void:
    if is_annotator_enabled(annotator_type) == is_enabled:
        # Do nothing. The annotator is already correct.
        return
    
    if is_enabled:
        _create_annotator(annotator_type)
    else:
        _destroy_annotator(annotator_type)

func is_annotator_enabled(annotator_type: int) -> bool:
    match annotator_type:
        AnnotatorType.PLAYER:
            return player.get_is_sprite_visible()
        AnnotatorType.PLAYER_POSITION:
            return position_annotator != null
        AnnotatorType.PLAYER_TRAJECTORY:
            return recent_movement_annotator != null
        AnnotatorType.NAVIGATOR:
            return navigator_annotator != null
        _:
            Gs.logger.error()
            return false

func _create_annotator(annotator_type: int) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.PLAYER:
            player.set_is_sprite_visible(true)
        AnnotatorType.PLAYER_POSITION:
            surface_annotator = PlayerSurfaceAnnotator.new(player)
            add_child(surface_annotator)
            position_annotator = PlayerPositionAnnotator.new(player)
            add_child(position_annotator)
            tile_annotator = PlayerTileAnnotator.new(player)
            add_child(tile_annotator)
        AnnotatorType.PLAYER_TRAJECTORY:
            recent_movement_annotator = \
                    PlayerRecentMovementAnnotator.new(player)
            add_child(recent_movement_annotator)
        AnnotatorType.NAVIGATOR:
            navigator_annotator = NavigatorAnnotator.new(player.navigator)
            add_child(navigator_annotator)
        _:
            Gs.logger.error()

func _destroy_annotator(annotator_type: int) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.PLAYER:
            player.set_is_sprite_visible(false)
        AnnotatorType.PLAYER_POSITION:
            surface_annotator.queue_free()
            surface_annotator = null
            position_annotator.queue_free()
            position_annotator = null
            tile_annotator.queue_free()
            tile_annotator = null
        AnnotatorType.PLAYER_TRAJECTORY:
            recent_movement_annotator.queue_free()
            recent_movement_annotator = null
        AnnotatorType.NAVIGATOR:
            navigator_annotator.queue_free()
            navigator_annotator = null
        _:
            Gs.logger.error()
