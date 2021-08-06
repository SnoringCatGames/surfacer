class_name SurfacerPlayerAnnotator
extends ScaffolderPlayerAnnotator


var navigator_annotator: NavigatorAnnotator
var surface_annotator: PlayerSurfaceAnnotator
var tile_annotator: PlayerTileAnnotator


func _init(player: SurfacerPlayer).(player) -> void:
    pass


func _physics_process(_delta: float) -> void:
    if player.did_move_last_frame:
        if is_instance_valid(surface_annotator):
            surface_annotator.check_for_update()
        if is_instance_valid(tile_annotator):
            tile_annotator.check_for_update()


func is_annotator_enabled(annotator_type: int) -> bool:
    match annotator_type:
        AnnotatorType.PLAYER:
            return player.get_is_sprite_visible()
        AnnotatorType.PLAYER_POSITION:
            return is_instance_valid(position_annotator)
        AnnotatorType.RECENT_MOVEMENT:
            return is_instance_valid(recent_movement_annotator)
        AnnotatorType.NAVIGATOR:
            return is_instance_valid(navigator_annotator)
        _:
            Sc.logger.error()
            return false


func _create_annotator(annotator_type: int) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.PLAYER:
            player.set_is_sprite_visible(true)
        AnnotatorType.PLAYER_POSITION:
            surface_annotator = PlayerSurfaceAnnotator.new(player)
            add_child(surface_annotator)
            position_annotator = SurfacerPlayerPositionAnnotator.new(player)
            add_child(position_annotator)
            tile_annotator = PlayerTileAnnotator.new(player)
            add_child(tile_annotator)
        AnnotatorType.RECENT_MOVEMENT:
            recent_movement_annotator = \
                    SurfacerPlayerRecentMovementAnnotator.new(player)
            add_child(recent_movement_annotator)
        AnnotatorType.NAVIGATOR:
            navigator_annotator = NavigatorAnnotator.new(player.navigator)
            add_child(navigator_annotator)
        _:
            Sc.logger.error()


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
        AnnotatorType.RECENT_MOVEMENT:
            recent_movement_annotator.queue_free()
            recent_movement_annotator = null
        AnnotatorType.NAVIGATOR:
            navigator_annotator.queue_free()
            navigator_annotator = null
        _:
            Sc.logger.error()
