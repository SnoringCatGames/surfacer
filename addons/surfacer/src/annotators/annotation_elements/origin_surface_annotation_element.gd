class_name OriginSurfaceAnnotationElement
extends SurfaceAnnotationElement


const TYPE := AnnotationElementType.ORIGIN_SURFACE


func _init(
        surface: Surface,
        depth := Sc.ann_params.surface_depth) \
        .(
        surface,
        depth,
        Sc.ann_params.origin_surface_color_params,
        true,
        false,
        TYPE) -> void:
    pass


func _create_legend_items() -> Array:
    var surface_item := OriginSurfaceLegendItem.new()
    return [surface_item]
