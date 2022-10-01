tool
class_name SurfacerAnnotators
extends ScaffolderAnnotators


const _SURFACER_CHARACTER_SUB_ANNOTATORS := [
    ScaffolderAnnotatorTypes.CHARACTER,
    ScaffolderAnnotatorTypes.CHARACTER_POSITION,
    ScaffolderAnnotatorTypes.RECENT_MOVEMENT,
    ScaffolderAnnotatorTypes.NAVIGATOR,
]

const _SURFACER_LEVEL_SPECIFIC_ANNOTATORS := [
    ScaffolderAnnotatorTypes.RULER,
    ScaffolderAnnotatorTypes.LEVEL,
    ScaffolderAnnotatorTypes.SURFACES,
    ScaffolderAnnotatorTypes.GRID_INDICES,
    ScaffolderAnnotatorTypes.PATH_PRESELECTION,
]

# Dictionary<ScaffolderAnnotatorTypes, bool>
const _SURFACER_DEFAULT_ENABLEMENT := {
    ScaffolderAnnotatorTypes.RULER: false,
    ScaffolderAnnotatorTypes.SURFACES: false,
    ScaffolderAnnotatorTypes.GRID_INDICES: false,
    ScaffolderAnnotatorTypes.LEVEL: true,
    ScaffolderAnnotatorTypes.CHARACTER: true,
    ScaffolderAnnotatorTypes.CHARACTER_POSITION: false,
    ScaffolderAnnotatorTypes.RECENT_MOVEMENT: false,
    ScaffolderAnnotatorTypes.NAVIGATOR: true,
    ScaffolderAnnotatorTypes.PATH_PRESELECTION: true,
}

var surfaces_annotator: SurfacesAnnotator
var path_preselection_annotator: PathPreselectionAnnotator
var grid_indices_annotator: GridIndicesAnnotator


func _init(
        character_sub_annotators := _SURFACER_CHARACTER_SUB_ANNOTATORS,
        level_specific_annotators := _SURFACER_LEVEL_SPECIFIC_ANNOTATORS,
        default_enablement := _SURFACER_DEFAULT_ENABLEMENT,
        character_annotation_class: Script = SurfacerCharacterAnnotator \
        ).(
        character_sub_annotators,
        level_specific_annotators,
        default_enablement,
        character_annotation_class) -> void:
    pass


func _create_annotator(annotator_type: String) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        ScaffolderAnnotatorTypes.RULER:
            if Sc.level != null:
                ruler_annotator = RulerAnnotator.new()
                ruler_layer.add_child(ruler_annotator)
        ScaffolderAnnotatorTypes.SURFACES:
            if Sc.level != null and \
                    Sc.level.surface_store != null:
                surfaces_annotator = SurfacesAnnotator.new( \
                        Sc.level.surface_store)
                annotation_layer.add_child(surfaces_annotator)
        ScaffolderAnnotatorTypes.GRID_INDICES:
            if Sc.level != null and \
                    Sc.level.surface_store != null:
                grid_indices_annotator = GridIndicesAnnotator.new(
                        Sc.level.surface_store)
                annotation_layer.add_child(grid_indices_annotator)
        ScaffolderAnnotatorTypes.PATH_PRESELECTION:
            if Sc.characters.can_include_player_characters and \
                    Su.manifest.movement_manifest.uses_point_and_click_navigation:
                path_preselection_annotator = PathPreselectionAnnotator.new()
                annotation_layer.add_child(path_preselection_annotator)
        ScaffolderAnnotatorTypes.LEVEL:
            if Sc.level != null:
                Sc.level.set_tilemap_visibility(true)
                Sc.level.set_background_visibility(true)
        _:
            Sc.logger.error("SurfacerAnnotators._create_annotator")


func _destroy_annotator(annotator_type: String) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        ScaffolderAnnotatorTypes.RULER:
            if ruler_annotator != null:
                ruler_annotator.queue_free()
                ruler_annotator = null
        ScaffolderAnnotatorTypes.SURFACES:
            if surfaces_annotator != null:
                surfaces_annotator.queue_free()
                surfaces_annotator = null
        ScaffolderAnnotatorTypes.GRID_INDICES:
            if grid_indices_annotator != null:
                grid_indices_annotator.queue_free()
                grid_indices_annotator = null
        ScaffolderAnnotatorTypes.PATH_PRESELECTION:
            if path_preselection_annotator != null:
                path_preselection_annotator.queue_free()
                path_preselection_annotator = null
        ScaffolderAnnotatorTypes.LEVEL:
            if Sc.level != null:
                Sc.level.set_tilemap_visibility(false)
                Sc.level.set_background_visibility(false)
        _:
            Sc.logger.error("SurfacerAnnotators._destroy_annotator")
