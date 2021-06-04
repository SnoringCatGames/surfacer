class_name DestinationSurfaceAnnotationElement
extends SurfaceAnnotationElement

const TYPE := AnnotationElementType.DESTINATION_SURFACE


func _init(
        surface: Surface,
        depth := AnnotationElementDefaults.SURFACE_DEPTH) \
        .(
        surface,
        depth,
        Surfacer.ann_defaults.DESTINATION_SURFACE_COLOR_PARAMS,
        false,
        true,
        TYPE) -> void:
    pass


func _create_legend_items() -> Array:
    var surface_item := DestinationSurfaceLegendItem.new()
    return [surface_item]
