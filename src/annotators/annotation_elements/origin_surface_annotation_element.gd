class_name OriginSurfaceAnnotationElement
extends SurfaceAnnotationElement


const TYPE := AnnotationElementType.ORIGIN_SURFACE


func _init(
        surface: Surface,
        depth := Sc.annotators.params.surface_depth) \
        .(
        surface,
        depth,
        Sc.palette.get_color("origin_surface_color"),
        true,
        false,
        TYPE) -> void:
    pass


func _create_legend_items() -> Array:
    var surface_item := OriginSurfaceLegendItem.new()
    return [surface_item]
