class_name DestinationSurfaceAnnotationElement
extends SurfaceAnnotationElement


const TYPE := AnnotationElementType.DESTINATION_SURFACE


func _init(
        surface: Surface,
        depth := Sc.ann_params.surface_depth) \
        .(
        surface,
        depth,
        Sc.ann_params.destination_surface_color_params,
        false,
        true,
        TYPE) -> void:
    pass


func _create_legend_items() -> Array:
    var surface_item := DestinationSurfaceLegendItem.new()
    return [surface_item]
