tool
class_name SurfacerBootstrap
extends ScaffolderBootstrap


func _init().("SurfacerBootstrap") -> void:
    pass


func _on_app_initialized() -> void:
    ._on_app_initialized()
    Sc.annotators._on_app_initialized()
    # Hide this annotator by default.
    Sc.annotators.set_annotator_enabled(
            AnnotatorType.RECENT_MOVEMENT,
            false)


func _on_splash_finished() -> void:
    if !Su.is_precomputing_platform_graphs:
        ._on_splash_finished()
    else:
        Sc.nav.open("precompute_platform_graphs")
