class_name SurfacerAnnotationElement
extends AnnotationElement


func _init(type: int).(type) -> void:
    pass


func _draw_from_surface(
        canvas: CanvasItem,
        surface: Surface,
        color_params: ColorParams,
        depth := Sc.ann_params.surface_depth) -> void:
    var color := color_params.get_color()
    Sc.draw.draw_surface(
            canvas,
            surface,
            color,
            depth)
