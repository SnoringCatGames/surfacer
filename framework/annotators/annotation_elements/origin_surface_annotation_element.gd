extends SurfaceAnnotationElement
class_name OriginSurfaceAnnotationElement

const TYPE := AnnotationElementType.ORIGIN_SURFACE

func _init( \
        surface: Surface, \
        depth := AnnotationElementDefaults.SURFACE_DEPTH) \
        .( \
        surface, \
        depth, \
        AnnotationElementDefaults.ORIGIN_SURFACE_COLOR_PARAMS, \
        true, \
        false, \
        TYPE) -> void:
    pass

func _create_legend_items() -> Array:
    var surface_item := OriginSurfaceLegendItem.new()
    return [surface_item]
