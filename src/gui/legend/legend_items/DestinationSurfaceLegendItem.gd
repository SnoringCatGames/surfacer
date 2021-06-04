class_name DestinationSurfaceLegendItem
extends SurfaceLegendItem

const TYPE := LegendItemType.DESTINATION_SURFACE
const TEXT := "Destination\nsurface"
var COLOR_PARAMS: ColorParams = \
        Surfacer.ann_defaults.DESTINATION_SURFACE_COLOR_PARAMS


func _init().(
        TYPE,
        TEXT,
        COLOR_PARAMS) -> void:
    pass
