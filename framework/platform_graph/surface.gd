extends Reference
class_name Surface

var vertices: PoolVector2Array
# SurfaceSide
var side: int
var bounding_box: Rect2
var normal: Vector2

func _init(vertices: Array, side: int) -> void:
    self.vertices = PoolVector2Array(vertices)
    self.side = side
    bounding_box = Geometry.get_bounding_box_for_points(vertices)
    normal = _calculate_normal(side)

static func to_string(surface: Surface) -> String:
    var side_str = SurfaceSide.to_string(surface.side)
    return "Surface:%s:%s" % [side_str, surface.vertices]

static func _calculate_normal(side: int) -> Vector2:
    return \
            Geometry.UP if side == SurfaceSide.FLOOR else (\
            Geometry.DOWN if side == SurfaceSide.CEILING else (\
            Geometry.RIGHT if side == SurfaceSide.LEFT_WALL else (\
            Geometry.LEFT)))
