tool
class_name SurfacerAnnotators
extends ScaffolderAnnotators


var _SURFACER_PLAYER_SUB_ANNOTATORS := [
    AnnotatorType.PLAYER,
    AnnotatorType.PLAYER_POSITION,
    AnnotatorType.RECENT_MOVEMENT,
    AnnotatorType.NAVIGATOR,
]

var _SURFACER_LEVEL_SPECIFIC_ANNOTATORS := [
    AnnotatorType.RULER,
    AnnotatorType.LEVEL,
    AnnotatorType.SURFACES,
    AnnotatorType.GRID_INDICES,
    AnnotatorType.PATH_PRESELECTION,
]

# Dictionary<AnnotatorType, bool>
const _SURFACER_DEFAULT_ENABLEMENT := {
    AnnotatorType.RULER: false,
    AnnotatorType.SURFACES: false,
    AnnotatorType.GRID_INDICES: false,
    AnnotatorType.LEVEL: true,
    AnnotatorType.PLAYER: true,
    AnnotatorType.PLAYER_POSITION: false,
    AnnotatorType.RECENT_MOVEMENT: true,
    AnnotatorType.NAVIGATOR: true,
    AnnotatorType.PATH_PRESELECTION: true,
}

var surfaces_annotator: SurfacesAnnotator
var path_preselection_annotator: PathPreselectionAnnotator
var grid_indices_annotator: GridIndicesAnnotator


func _init().(
        _SURFACER_PLAYER_SUB_ANNOTATORS,
        _SURFACER_LEVEL_SPECIFIC_ANNOTATORS,
        _SURFACER_DEFAULT_ENABLEMENT,
        SurfacerPlayerAnnotator) -> void:
    pass


func _create_annotator(annotator_type: int) -> void:
    assert(!is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.RULER:
            if Sc.level != null:
                ruler_annotator = RulerAnnotator.new()
                ruler_layer.add_child(ruler_annotator)
        AnnotatorType.SURFACES:
            if Sc.level != null and \
                    Su.graph_parser.surface_parser != null:
                surfaces_annotator = SurfacesAnnotator.new( \
                        Su.graph_parser.surface_parser)
                annotation_layer.add_child(surfaces_annotator)
        AnnotatorType.GRID_INDICES:
            if Sc.level != null and \
                    Su.graph_parser.surface_parser != null:
                grid_indices_annotator = GridIndicesAnnotator.new(
                        Su.graph_parser.surface_parser)
                annotation_layer.add_child(grid_indices_annotator)
        AnnotatorType.PATH_PRESELECTION:
            if is_instance_valid(Sc.players.get_human_player()):
                path_preselection_annotator = PathPreselectionAnnotator.new(
                        Sc.players.get_human_player())
                annotation_layer.add_child(path_preselection_annotator)
        AnnotatorType.LEVEL:
            if Sc.level != null:
                Sc.level.set_tile_map_visibility(true)
        _:
            Sc.logger.error()


func _destroy_annotator(annotator_type: int) -> void:
    assert(is_annotator_enabled(annotator_type))
    match annotator_type:
        AnnotatorType.RULER:
            if ruler_annotator != null:
                ruler_annotator.queue_free()
                ruler_annotator = null
        AnnotatorType.SURFACES:
            if surfaces_annotator != null:
                surfaces_annotator.queue_free()
                surfaces_annotator = null
        AnnotatorType.GRID_INDICES:
            if grid_indices_annotator != null:
                grid_indices_annotator.queue_free()
                grid_indices_annotator = null
        AnnotatorType.PATH_PRESELECTION:
            if path_preselection_annotator != null:
                path_preselection_annotator.queue_free()
                path_preselection_annotator = null
        AnnotatorType.LEVEL:
            if Sc.level != null:
                Sc.level.set_tile_map_visibility(false)
        _:
            Sc.logger.error()
