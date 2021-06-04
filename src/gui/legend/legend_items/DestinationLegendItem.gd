class_name DestinationLegendItem
extends LegendItem

const TYPE := LegendItemType.DESTINATION
const TEXT := "Destination"

const SCALE := 0.8
const SECTOR_ARC_LENGTH := 2.2


func _init().(
        TYPE,
        TEXT) -> void:
    pass


func _draw_shape(
        center: Vector2,
        size: Vector2) -> void:
    var cone_length: float = \
            SurfacerDrawUtils.EDGE_END_CONE_LENGTH * SCALE * Gs.gui_scale
    var radius: float = \
            SurfacerDrawUtils.EDGE_END_RADIUS * SCALE * Gs.gui_scale
    var length := cone_length + radius * Gs.gui_scale
    var cone_end_point := Vector2(
            center.x,
            center.y + length / 2.0)
    var color: Color = \
            Surfacer.ann_defaults.DEFAULT_WAYPOINT_COLOR_PARAMS.get_color()
    var surface := Surface.new()
    surface.side = SurfaceSide.FLOOR
    var position := PositionAlongSurface.new()
    position.surface = surface
    position.target_projection_onto_surface = cone_end_point
    
    Gs.draw_utils.draw_destination_marker(
            self,
            position,
            false,
            color,
            cone_length,
            radius,
            false,
            SurfacerDrawUtils.EDGE_WAYPOINT_STROKE_WIDTH,
            SECTOR_ARC_LENGTH)
