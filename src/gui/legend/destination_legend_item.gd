class_name DestinationLegendItem
extends LegendItem


const TYPE := "DESTINATION"
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
            Sc.annotators.params.edge_end_cone_length * SCALE * Sc.gui.scale
    var radius: float = \
            Sc.annotators.params.edge_end_radius * SCALE * Sc.gui.scale
    var length := cone_length + radius * Sc.gui.scale
    var cone_end_point := Vector2(
            center.x,
            center.y + length / 2.0)
    var color: Color = \
            Sc.annotators.params.default_waypoint_color_config.sample()
    var surface := Surface.new()
    surface.side = SurfaceSide.FLOOR
    var position := PositionAlongSurface.new()
    position.surface = surface
    position.target_projection_onto_surface = cone_end_point
    
    Sc.draw.draw_destination_marker(
            self,
            position,
            false,
            color,
            cone_length,
            radius,
            false,
            Sc.annotators.params.edge_waypoint_stroke_width,
            SECTOR_ARC_LENGTH)
