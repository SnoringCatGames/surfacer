class_name SurfacerAnnotationElement
extends AnnotationElement


func _init(type: int).(type) -> void:
    pass


func _draw_from_surface(
        canvas: CanvasItem,
        surface: Surface,
        color_config: ColorConfig,
        depth := Sc.annotators.params.surface_depth) -> void:
    var color := color_config.sample()
    Sc.draw.draw_surface(
            canvas,
            surface,
            color,
            depth)
