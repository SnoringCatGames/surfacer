class_name SurfacerCharacterAnnotator
extends ScaffolderCharacterAnnotator


var navigator_annotator: NavigatorAnnotator
var surface_annotator: CharacterSurfaceAnnotator
var tile_annotator: CharacterTileAnnotator


func _init(character: SurfacerCharacter).(character) -> void:
    pass


func _physics_process(_delta: float) -> void:
    if !is_instance_valid(character):
        return
    if character.did_move_last_frame:
        if is_instance_valid(surface_annotator):
            surface_annotator.check_for_update()
        if is_instance_valid(tile_annotator):
            tile_annotator.check_for_update()


func is_annotator_enabled(annotator_type: String) -> bool:
    match annotator_type:
        ScaffolderAnnotatorTypes.CHARACTER:
            return character.get_is_sprite_visible()
        ScaffolderAnnotatorTypes.CHARACTER_POSITION:
            return is_instance_valid(position_annotator)
        ScaffolderAnnotatorTypes.RECENT_MOVEMENT:
            return is_instance_valid(recent_movement_annotator)
        ScaffolderAnnotatorTypes.NAVIGATOR:
            return is_instance_valid(navigator_annotator)
        _:
            Sc.logger.error("SurfacerCharacterAnnotator.is_annotator_enabled")
            return false


func _create_annotator(annotator_type: String) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        ScaffolderAnnotatorTypes.CHARACTER:
            character.set_is_sprite_visible(true)
        ScaffolderAnnotatorTypes.CHARACTER_POSITION:
            surface_annotator = CharacterSurfaceAnnotator.new(character)
            add_child(surface_annotator)
            position_annotator = \
                    SurfacerCharacterPositionAnnotator.new(character)
            add_child(position_annotator)
            tile_annotator = CharacterTileAnnotator.new(character)
            add_child(tile_annotator)
        ScaffolderAnnotatorTypes.RECENT_MOVEMENT:
            recent_movement_annotator = \
                    SurfacerCharacterRecentMovementAnnotator.new(character)
            add_child(recent_movement_annotator)
        ScaffolderAnnotatorTypes.NAVIGATOR:
            navigator_annotator = NavigatorAnnotator.new(character.navigator)
            add_child(navigator_annotator)
        _:
            Sc.logger.error("SurfacerCharacterAnnotator._create_annotator")


func _destroy_annotator(annotator_type: String) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        ScaffolderAnnotatorTypes.CHARACTER:
            character.set_is_sprite_visible(false)
        ScaffolderAnnotatorTypes.CHARACTER_POSITION:
            surface_annotator.queue_free()
            surface_annotator = null
            position_annotator.queue_free()
            position_annotator = null
            tile_annotator.queue_free()
            tile_annotator = null
        ScaffolderAnnotatorTypes.RECENT_MOVEMENT:
            recent_movement_annotator.queue_free()
            recent_movement_annotator = null
        ScaffolderAnnotatorTypes.NAVIGATOR:
            navigator_annotator.queue_free()
            navigator_annotator = null
        _:
            Sc.logger.error("SurfacerCharacterAnnotator._destroy_annotator")
