class_name DestinationSurfaceAnnotationElement
extends SurfaceAnnotationElement


const TYPE := AnnotationElementType.DESTINATION_SURFACE


func _init(
        surface: Surface,
        depth := Sc.annotators.params.surface_depth) \
        .(
        surface,
        depth,
        Sc.palette.get_color("destination_surface_color"),
        false,
        true,
        TYPE) -> void:
    pass


func _create_legend_items() -> Array:
    var surface_item := DestinationSurfaceLegendItem.new()
    return [surface_item]
