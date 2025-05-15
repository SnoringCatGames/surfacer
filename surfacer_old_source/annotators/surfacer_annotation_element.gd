class_name SurfacerAnnotationElement
extends AnnotationElement


func _init(type: int).(type) -> void:
    pass


func _draw_from_surface(
        canvas: CanvasItem,
        surface: Surface,
        color: Color,
        depth := Sc.annotators.params.surface_depth) -> void:
    Sc.draw.draw_surface(
            canvas,
            surface,
            color,
            depth)
